`include "defines.vh"
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
parameter REPLACE = 4'h4;   // update v and d & if dirty send request to write back(if m_rvalid = 1 then handle the coming data)
parameter REFILL = 4'h5;    // wait for data from memory, then update data ram and tag ram, v & d & lru; wait the write back finished.
//-----------------------signal definition-----------------------//
// state
reg [3:0] current_state = IDLE;

// tag ram
// depth = 128, width = 20, 2 instances
// 19:0 is tag
wire tag_wen [1:0];
wire [6:0] tag_addr [1:0];  // index(0~127)
wire [19:0] tag_wdata [1:0];    // tag write data
wire [19:0] tag_rdata [1:0];    // tag read data
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
wire [31:0] data_wdata [1:0][7:0];    // data write data
wire [31:0] data_rdata [1:0][7:0];    // data read data
genvar j, k;

// useful signal
wire [1:0] hit;
wire replaced_way;
wire [31:0] addr_req;
wire [19:0] tag_req;
wire [6:0] index_req;
wire [2:0] offset_req;

reg [31:0] addr_req_r;
reg m_arvalid_r;

reg m_wlast_r;
reg m_wvalid_r;
reg [31:0] m_wdata_r;

reg s_wready_r;
reg [31:0] s_rdata_r;
reg s_rvalid_r;

reg cached;
reg [2:0] read_count = 3'd0;    // transfer 8 words(banks) per time
reg [31:0] data_at_write_back = 32'h0000_0000;
reg [31:0] wdata_req_r;

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
task set_addr_req_r();
    begin
        addr_req_r <= s_addr;
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

        s_wready_r <= 1'b0;
        s_rdata_r <= 32'h0000_0000;
        s_rvalid_r <= 1'b0;

        cached <= 1'b0;
        read_count <= 3'd0;
        data_at_write_back <= 32'h0000_0000;


    end else begin
        case (current_state)
            IDLE: begin
                if(!flush) begin
                    if (s_arvalid == 1'b1) begin
                        if (cache_ena) begin
                            current_state <= COMP_TAG;
                        end else begin
                            current_state <= READ_MEM;
                            read_count <= 3'd0;
                            m_arvalid_r <= 1'b1;
                        end
                        set_addr_req_r();
                        cached <= cache_ena;
                    end else if (|s_awvalid == 1'b1) begin
                        if (cache_ena) begin
                            current_state <= COMP_TAG;
                        end else begin
                            current_state <= READ_MEM;
                        end
                        set_addr_req_r();
                        wdata_req_r <= s_wdata;
                        cached <= cache_ena;
                    end
                end
            end

            COMP_TAG: begin
                if (|hit) begin
                    current_state <= IDLE;
                    lru[addr_req_r[11:5]] <= (hit[0] == 1'b1) ? 1'b0 : 1'b1;
                end
                else begin
                    lru[addr_req_r[11:5]] <= ~lru[addr_req_r[11:5]];
                    current_state <= READ_MEM;
                    read_count <= 3'd0;
                    m_arvalid_r <= 1'b1;
                end
            end

            // read mem & write to data ram
            READ_MEM: begin
                if (m_arready == 1'b1) begin
                    m_arvalid_r <= 1'b0;
                end
                if (cached) begin
                    if (m_rvalid) begin
                        read_count <= read_count + 1'b1;
                        // if axi outputs data needed, then put it into data_at_write_back, and send to s_rdata at WRITE_BACK
                        if (read_count == addr_req_r[4:2]) begin
                            data_at_write_back <= m_rdata;
                        end
                        // write data to data ram (see assign)
                    end
                    if (m_rlast == 1'b1) begin 
                        current_state <= WRITE_BACK;
                        read_count <= 3'b0;
                    end
                end else begin
                    if (m_rvalid && m_rlast) begin
                        current_state <= WRITE_BACK;
                        data_at_write_back <= m_rdata;
                    end
                end

            end

            // update tagv & send missing data back to cpu
            WRITE_BACK: begin
                current_state <= IDLE;
                // update tagv
                if (cached) begin
                    v[hit] <= v[hit] | (1 << addr_req_r[11:5]);
                end
            end
            default: ;
        endcase
    end
end

//-----------------------wire assign------------------------//
// don't know when the axi_ram will reply with arready=1, so have a reg to wait for that
assign m_arvalid = m_arvalid_r;
assign m_rready = 1'b1;

// calculate tag, index, offset
assign addr_req = (current_state == IDLE) ? s_araddr : addr_req_r;
assign tag_req = addr_req[31:12];
assign index_req = addr_req[11:5];
assign offset_req = addr_req[4:2];

// indicate which way to be replaced
assign replaced_way = lru[index_req];

// used for READ_MEM
// read from memory, offset width = 5 bits.
assign m_araddr = (cached) ? {tag_req, index_req, {5{1'b0}}} : addr_req;

generate
for(i = 0;i < 2;i = i + 1) begin: gen_u1
    // used for IDLE
    assign tag_addr[i] = index_req;
    // used for COMP_TAG
    assign hit[i] = ((tag_rdata[i] == tag_req) && (v[i][index_req] == 1'b1)) ? 1'b1 : 1'b0;

    // write for memory
    for(j = 0;j < 8;j = j + 1) begin
        assign data_wen[i][j] = ((cached) && (m_rvalid) && (replaced_way == i) && (read_count == j)) ? 4'b1111 : 4'b0000;
        assign data_wdata[i][j] = m_rdata;
        assign data_addr[i][j] = index_req;
    end
    // used for WRITE_BACK
    assign tag_wen[i] = ((cached) && (current_state == WRITE_BACK) && (replaced_way == i));
    assign tag_wdata[i] = tag_req;
end
endgenerate

// send data to CPU (at COMP_TAG or WRITE_BACK)
// assume the cpu get data from cache in 1 cycle, so don't have a reg to wait
// if hit, the cpu get data at COMP_TAG state
// else, the cpu get data at WRITE_BACK state
assign s_rvalid =
    ((current_state == COMP_TAG) && (|hit)) ?
        1'b1
    :
        ((current_state == WRITE_BACK) ?
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
        ((current_state == WRITE_BACK) ? 
            data_at_write_back
        :
            {32{1'b0}});

function [2:0]get_awsize(input cache_ena, input [3:0]s_awvalid);
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

assign m_awsize = get_awsize(cache_ena,s_awvalid);
assign m_awburst = cache_ena ? 2'b01:2'b00;
assign m_awlock = 2'b00;
assign m_awcache = 4'b0000;
assign m_awprot = 3'b000;

assign m_wid = 4'b0000;
assign m_wlast = m_wlast_r;
assign m_wvalid = m_wvalid_r;
assign m_wdata = m_wdata_r;
assign m_wstrb = cache_ena ? 4'b1111 : s_awvalid;

assign m_bready = 1'b1;

assign s_wready = s_wready_r;
assign s_rdata = s_rdata_r;
assign s_rvalid = s_rvalid_r;

endmodule;