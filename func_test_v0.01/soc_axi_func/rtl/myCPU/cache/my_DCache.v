`include "defines.vh"
`include "cache_config.vh"
module data_cache_fifo(
    input         clk            ,
    input         rst            ,
    input         cache_ena      ,
    // master
    // ar
    output [31:0] m_araddr       ,
    output        m_arvalid      ,
    input         m_arready      ,
    // r
    input  [31:0] m_rdata        ,
    input         m_rlast        ,
    input         m_rvalid       ,
    output        m_rready       ,
    // aw
    output [3:0]  m_awid         ,
    output [7 :0] m_awlen        ,
    output [2 :0] m_awsize       ,
    output [1 :0] m_awburst      ,
    output [1 :0] m_awlock       ,
    output [3 :0] m_awcache      ,
    output [2 :0] m_awprot       ,
    output [31:0] m_awaddr       ,
    output        m_awvalid      ,
    input         m_awready      ,
    // w
    output [3:0]  m_wid          ,         
    output [31:0] m_wdata        ,
    output        m_wlast        ,
    output [3:0]  m_wstrb        ,
    output        m_wvalid       ,
    input         m_wready       ,
    // b
    input         m_bvalid       ,
    output        m_bready       ,
	// slave
    // ar, aw
    input  [31:0] s_addr         ,  // ar & aw 共用一个addr data_addr
    // ar
    input         s_arvalid      ,  // data_ren
    // r
    output [31:0] s_rdata        ,  // data_rd
    output        s_rvalid       ,  // data_valid_r
    // aw
    input  [3:0]  s_awvalid      ,  //data_wen, 不同于传统的awvalid，这里的awvalid其实是data_wen
    // w
    input  [31:0] s_wdata        ,  // data_wd
    output        s_wready       ,  // data_cache_write_ok
    input         flush
);


/*
2 ways, 4kB per way. 128 sets.

Every line(block) contains 32 Bytes(8 words), 4 Bytes per word.

width:
TAG = 20, INDEX = 7, OFFSET = 5, V = 1, LRU = 1, D = 1.

[31: 12] [11: 5] [4: 0]

8 bank per way, 32 bits/bank.

write_through method.

*/

//-----------------------state definition------------------------//
parameter IDLE = 4'd0;  // wait addr and request
parameter COMP_TAG = 4'd1;   // compare tag between addr and tagv & update lru
parameter READ_MEM = 4'h2;  // request data from memory, if m_arready = 1, then go to SELECT
parameter SELECT = 4'h3;    // choose the target to be replaced; send request to read tag, v & d, bank data from ram(if m_rvalid = 1 then handle the coming data)
parameter REPLACE = 4'h4;   // update v and d & if dirty send request to write back(if m_rvalid = 1 then handle the coming data), wait for data from memory,  wait the write back finished.
parameter REFILL = 4'h5;    // then update data ram and tag ram, v & d & lru.
//-----------------------signal definition-----------------------//
// state
reg [3:0] current_state = IDLE;

// tag ram
// depth = 128, width = 20, 2 instances
// 19:0 is tag
wire tag_wen [1:0];
wire [6:0] tag_addr [1:0];  // index(0~127)
wire [19:0] tag_wdata [1:0];    // tag ram write data
wire [19:0] tag_rdata [1:0];    // tag ram read data
genvar i;

// v and lru
reg [127:0] v [1:0];// v(0~127, 2 way)
reg [127:0] d [1:0];// d(0~127, 2 way)
reg [127:0] lru;    // lru(0~127)

// data ram
// 128 sets, 2 way/set, 8 bank/way => 16 bank/set.
// depth = 128, width = 32, 16 instances.
wire [3:0] data_wen [1:0][7:0]; // control 4 bytes wen
wire [6:0] data_addr [1:0][7:0];  // index(0~127)
wire [31:0] data_wdata [1:0][7:0];    // data ram write data
wire [31:0] data_rdata [1:0][7:0];    // data ram read data
genvar j, k;

// useful signal
wire [1:0] hit;
wire replaced_way;
wire dirty;

reg cached;
reg [2:0] read_count = 3'd0;    // transfer 8 words(banks) per time
reg [31:0] data_at_refill = 32'h0000_0000;  // the target data requested from cpu(used at refill stage)
reg [1:0] read_state; // 0 for idle, 1 for sending, 2 for done.

reg [2:0] write_count = 3'd0;
reg [31:0] data_for_write_through [7:0]; // if dirty, data from ram should be write through to memory. This reg is used for store it temporarily.
reg [1:0] write_state;  // 0 for idle, 1 for sending, 2 for done.

// request signal
wire [31:0] addr_req;
    wire [19:0] tag_req;
    wire [6:0] index_req;
    wire [2:0] offset_req;
wire [31:0] wdata_req;
wire arvalid_req;
wire [3:0] awvalid_req;

reg [31:0] addr_req_r;
reg [31:0] wdata_req_r;
reg arvalid_req_r;
reg [3:0] awvalid_req_r;

// master
// ar
reg m_arvalid_r;
// aw
reg m_awvalid_r;
// w
reg [31:0] m_wdata_r;
reg m_wlast_r;
reg m_wvalid_r;
// slave
// s
reg [31:0] s_rdata_r;
reg s_rvalid_r;


//-----------------------memory definition------------------------//
// tag ram
generate
    for (i = 0;i < 2;i = i + 1) begin: tagv_ram_gen
        tag_ram tag_ram_inst(
            .clka(clk),
            .ena(cache_ena),
            .wea(tag_wen[i]),
            .addra(tag_addr[i]),
            .dina(tag_wdata[i]),
            .douta(tag_rdata[i])
        );
    end
endgenerate

// data ram
generate
    for (j = 0;j < 2;j = j + 1) begin: way_ram_gen
        for (k = 0;k < 8;k = k + 1) begin: bank_ram_gen
            data_ram data_ram_inst(
            .clka(clk),
            .ena(cache_ena),
            .wea(data_wen[j][k]),
            .addra(data_addr[j][k]),
            .dina(data_wdata[j][k]),
            .douta(data_rdata[j][k])
        );
        end
    end
endgenerate

//-----------------------state transition------------------------//
task set_req_r();
    begin
        addr_req_r <= s_addr;
        arvalid_req_r <= arvalid_req;
        awvalid_req_r <= awvalid_req;
        wdata_req_r <= s_wdata;
    end
endtask

integer index;
always @(posedge clk) begin
    if(rst == `RST_ENABLE) begin
        current_state <= IDLE;
        for (index = 0;index < 2;index = index + 1) begin
            v[index] <= {128{1'b0}};
            d[index] <= {128{1'b0}};
        end

        lru <= {128{1'b0}};

        addr_req_r <= 32'h0000_0000;
        m_arvalid_r <= 1'b0;

        m_wlast_r <= 1'b0;
        m_wvalid_r <= 1'b0;
        m_wdata_r <= 32'h0000_0000;

        s_rdata_r <= 32'h0000_0000;
        s_rvalid_r <= 1'b0;

        cached <= 1'b0;
        read_count <= 3'd0;
        data_at_refill <= 32'h0000_0000;
        read_state <= 2'b0;

        write_count <= 1'b0;
        for (index = 0;index < 8;index = index + 1) begin
            data_for_write_through[index] <= 32'h0000_0000;
        end
        write_state <= 2'b0;

    end else begin
        case (current_state)
            // wait addr and request
            IDLE: begin
                if(!flush) begin
                    if ((s_arvalid == 1'b1) || (|s_awvalid == 1'b1)) begin
                        if (cache_ena) begin
                            current_state <= COMP_TAG;
                        end else begin
                            current_state <= READ_MEM;
                            read_count <= 3'd0;
                            m_arvalid_r <= 1'b1;
                        end
                        set_req_r();
                        cached <= cache_ena;
                    end
                end
            end

            // compare tag between addr and tagv & update lru
            COMP_TAG: begin
                if (|hit) begin
                    // if hit: for read, it updates lru and goes back to IDLE; for write, it updates lru, data ram and goes to IDLE.
                    lru[addr_req_r[11:5]] <= (hit[0] == 1'b1) ? 1'b0 : 1'b1;    
                    if (arvalid_req == 1'b1) begin
                        current_state <= IDLE;                     
                    end else if (|awvalid_req == 1'b1) begin
                        current_state <= REFILL;
                    end
                end else begin
                    // if not hit: for read, it sends addr and goes to READ_MEM; for write, it sends addr and goes to READ_MEM; also, it handles the write through process.
                    lru[addr_req_r[11:5]] <= ~lru[addr_req_r[11:5]];
                    // for read work
                    current_state <= READ_MEM;
                    read_count <= 3'd0;
                    m_arvalid_r <= 1'b1;
                    // for write work
                    if (dirty == 1'b1) begin
                        // if dirty, send write back request
                        write_count <= 3'd0;
                        m_awvalid_r <= 1'b1;
                        // store ram data to be written back
                        for (index = 0;index < 8; index = index + 1) begin
                            data_for_write_through[index] <= data_rdata[replaced_way][index];
                        end
                    end
                end
            end

            // wait data from memory, and wait for write data. for cached data, it replaces cache line, also writes dirty data to memory; for uncached, it goes directly to read/write memory.
            // todo: add write channel support
            READ_MEM: begin

                if (cached) begin
                    // handshake
                    // read
                    if (m_arready == 1'b1) begin
                        m_arvalid_r <= 1'b0;
                        read_state <= 2'b01;
                    end
                    // write
                    if ((m_awready == 1'b1) && (dirty == 1'b1)) begin
                        m_awvalid_r <= 1'b0;
                        write_state <= 2'b01;
                    end
                    // data transfer
                    // read
                    if (m_rvalid) begin
                        read_count <= read_count + 1;
                        // if axi outputs data needed, then put it into data_at_refill, and send to s_rdata at REFILL
                        if (read_count == addr_req_r[4:2]) begin
                            data_at_refill <= m_rdata;
                        end
                        // write data to data ram (see assign)
                    end
                    if (m_rlast == 1'b1) begin 
                        // current_state <= REFILL;
                        read_state <= 2'b10;
                        read_count <= 3'b0;
                    end
                    // write
                    if ((dirty == 1'b1) && (write_state == 2'b01)) begin
                        if (write_count == 3'd7) begin
                            m_wvalid_r <= 1'b0;
                            m_wlast_r <= 1'b0;
                            write_state <= 2'b10;
                            write_count <= 3'd0;
                        end else if (write_count == 3'd6) begin
                            m_wvalid_r <= 1'b1;
                            m_wlast_r <= 1'b1; 
                            if (m_wready == 1'b1) begin
                                write_count <= write_count + 1;
                            end
                        end else begin
                            m_wvalid_r <= 1'b1;
                            m_wlast_r <= 1'b0;
                            if (m_wready == 1'b1) begin
                                write_count <= write_count + 1;
                            end
                        end
                    end
                    // transition
                    if ((read_state == 2'b10) && (write_state == 2'b10)) begin
                        current_state <= REFILL;
                        read_state <= 2'b00;
                        write_state <= 2'b00;
                    end
                end else begin
                    // handshake
                    // read
                    if (m_arready == 1'b1) begin
                        m_arvalid_r <= 1'b0;
                        read_state <= 2'b01;
                    end
                    // write
                    if (m_awready == 1'b1) begin
                        m_awvalid_r <= 1'b0;
                        m_wvalid_r <= 1'b1;
                        m_wlast_r <= 1'b1;
                        write_state <= 2'b01;
                    end
                    // data transfer
                    // read
                    if (m_rvalid && m_rlast) begin
                        data_at_refill <= m_rdata;
                        read_state <= 2'b10;
                    end
                    // write
                    if (m_wready == 1'b1) begin
                        write_state <= 2'b10;
                    end
                    // transition
                    if ((read_state == 2'b10) && (write_state == 2'b10)) begin
                        current_state <= REFILL;
                        read_state <= 2'b00;
                        write_state <= 2'b00;
                    end
                end
            end
            // 1. update tag, v and d 
            // 2. for read, send missing data back to cpu; for write, update the data in ram. 1 cycle.
            REFILL: begin
                current_state <= IDLE;
                // update tag v d
                // for write, also update data ram
                if (cached) begin
                    // update tag(see assign)
                    // update v for both read and write
                    v[replaced_way][index_req] <= v[replaced_way][index_req] | 1;
                    // update d for only write
                    if (|awvalid_req == 1'b1) begin
                        // update data ram(see assign)
                        // update d
                        d[replaced_way][index_req] <= 1;
                    end else if (arvalid_req) begin
                        // update d
                        // it means first time of reading from memory to cache. the d should be 0.
                        d[replaced_way][index_req] <= 0;
                    end
                end
            end
            default: ;
        endcase
    end
end

//-----------------------wire assign------------------------//
// don't know when the axi_ram will reply with arready=1, so have a reg to wait for that
assign m_arvalid = m_arvalid_r;
assign m_rready = (current_state == READ_MEM) ? 1'b1 : 1'b0;

// calculate addr, tag, index, offset, data
assign addr_req = (current_state == IDLE) ? s_araddr : addr_req_r;
    assign tag_req = addr_req[31:12];
    assign index_req = addr_req[11:5];
    assign offset_req = addr_req[4:2];
assign wdata_req = (current_state == IDLE) ? s_wdata : wdata_req_r;
assign arvalid_req = (current_state == IDLE) ? s_arvalid : arvalid_req_r;
assign awvalid_req = (current_state == IDLE) ? s_awvalid : awvalid_req_r;

// indicate which way to be replaced
assign replaced_way = lru[index_req];
assign dirty = d[replaced_way][index_req];
// used for READ_MEM
// read from memory, offset width = 5 bits.
assign m_araddr = (cached) ? {tag_req, index_req, {5{1'b0}}} : addr_req;

generate
for(i = 0;i < 2;i = i + 1) begin: gen_u1
    // used for IDLE
    assign tag_addr[i] = index_req;
    // used for COMP_TAG
    assign hit[i] = ((tag_rdata[i] == tag_req) && (v[i][index_req] == 1'b1)) ? 1'b1 : 1'b0;
    // write to memory
    for(j = 0;j < 8;j = j + 1) begin
        assign data_wen[i][j] = 
        ((current_state == READ_MEM) && (cached) && (m_rvalid) && (replaced_way == i) && (read_count == j)) ? 
            4'b1111 
        : 
            (((current_state == REFILL) && (cached) && (hit[i] == 1'b1)) ? 
                awvalid_req
            :
                4'b0000);
        assign data_wdata[i][j] = 
            (current_state == READ_MEM) ? 
                m_rdata
            :
                ((current_state == REFILL) ?
                    data_for_write_through[j]
                :
                    32'h0000_0000);
        assign data_addr[i][j] = index_req;
    end
    // used for REFILL
    assign tag_wen[i] = ((cached) && (current_state == REFILL) && (replaced_way == i));
    assign tag_wdata[i] = tag_req;
end
endgenerate



function [2:0] get_awsize(input cache_ena, input [3:0] s_awvalid);
begin
    if(cache_ena) begin
        get_awsize = 3'b010;
    end else begin
        case(s_awvalid)
        4'b1111: get_awsize = 3'b010;
        4'b1100,4'b0011: get_awsize = 3'b001;
        4'b0001,4'b0010,4'b0100,4'b1000: get_awsize = 3'b000;
        default: get_awsize = 3'b000; 
        endcase
    end
end
endfunction

// master
// aw
assign m_awid = 4'b0000;
assign m_awlen = cached ? `DATA_BURST_NUM : 8'h00;
assign m_awsize = get_awsize(cached, awvalid_req);
assign m_awburst = cached ? 2'b01:2'b00;
assign m_awlock = 2'b00;
assign m_awcache = 4'b0000;
assign m_awprot = 3'b000;
assign m_awaddr = (cached) ? {tag_req, index_req, {5{1'b0}}} : s_addr;
assign m_awvalid = m_awvalid_r;
// w
assign m_wid = 4'b0000;
assign m_wdata = m_wdata_r;
assign m_wlast = m_wlast_r;
assign m_wvalid = m_wvalid_r;
assign m_wstrb = cached ? 4'b1111 : awvalid_req;
// b
assign m_bready = 1'b1;
// slave
// r
// send data to CPU (at COMP_TAG or REFILL)
// assume the cpu get data from cache in 1 cycle, so don't have a reg to wait
// if hit, the cpu get data at COMP_TAG state
// else, the cpu get data at REFILL state
assign s_rvalid =
    ((current_state == COMP_TAG) && (|hit)) ?
        1'b1
    :
        (((current_state == REFILL) && (|awvalid_req == 1'b0) && (arvalid_req == 1'b1)) ?
            1'b1
        :
            1'b0);
assign s_rdata = 
    (current_state == COMP_TAG && (|hit)) ?
        ((hit[0] == 1'b1) ? 
            data_rdata[0][offset_req]
        :
            data_rdata[1][offset_req])
    :
        ((current_state == REFILL) ? 
            data_at_refill
        :
            {32{1'b0}});
// w
assign s_wready = 
    ((current_state == REFILL) && ((|awvalid_req == 1'b1)) && (arvalid_req == 1'b0)) ? 
        1'b1
    :
        1'b0;
endmodule;