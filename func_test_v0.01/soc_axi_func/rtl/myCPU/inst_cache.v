`include "defines.vh"

module inst_cache(
    input         rst            ,
    input         clk            ,
    input         cache_ena      ,
    
    // master
    output [31:0] m_araddr       ,
    output        m_arvalid      ,
    input         m_arready      ,
    input  [31:0] m_rdata        ,  // cache作为主设备从内存（从设备）中读取得到的数�?
    input         m_rlast        ,
    input         m_rvalid       ,
    output        m_rready       ,

    // slave
    input  [31:0] s_araddr       ,
    input         s_arvalid      ,
    output [31:0] s_rdata        ,  // cache作为从设备向调用它的cpu（主设备）发送读取的数据
    output        s_rvalid       ,       
    input         flush

);

/*
2 ways, 4kB per way. 128 sets.

Every line(block) contains 32 Bytes(8 words), 4 Bytes per word.

width:
TAG = 20, INDEX = 7, OFFSET = 5, V = 1, LRU = 1.

[31: 12] [11: 5] [4: 0]

8 bank per way, 32 bits/bank.

*/

//-----------------------state definition------------------------//
parameter IDLE_AND_COMP_TAG = 4'd0;  // wait addr and request
parameter READ_MEM = 4'h1;  // read new block from mem to addr, and write new block inst cache
parameter WRITE_BACK = 4'h2;    // update tagv and lru & send missing data back to cpu

//-----------------------signal definition-----------------------//
// state
reg [3:0] current_state = IDLE_AND_COMP_TAG;

// tag ram
// depth = 128, width = 20, 2 instances
// 19:0 is tag
wire tag_wen [1:0];
wire [6:0] tag_addr [1:0];  // index(0~127)
wire [19:0] tag_wdata [1:0];    // tag write data
wire [19:0] tag_rdata [1:0];    // tag read data
wire tag_ena;
genvar i;

// v and lru
reg [127:0] v [1:0];// v(0~127, 2 way)
reg [127:0] lru;    // lru(0~127)

// data ram
// 128 sets, 2 way/set, 8 bank/way => 16 bank/set.
// depth = 128, width = 32, 16 instances.
wire [3:0] data_wen [1:0][7:0]; // control 4 bytes wen
wire [6:0] data_addr [1:0][7:0];  // index(0~127)
wire [31:0] data_wdata [1:0][7:0];    // data write data
wire [31:0] data_rdata [1:0][7:0];    // data read data
wire data_ena;
genvar j, k;

// useful signal
wire [1:0] hit;
wire replaced_way;
wire [31:0] addr_req_latest;
wire [19:0] tag_req_latest;
wire [6:0] index_req_latest;
wire [2:0] offset_req_latest;
wire cached;

reg m_arvalid_r;
reg cached_r;
reg [2:0] read_count = 3'd0;    // transfer 8 words(banks) per time
reg [31:0] data_at_write_back = 32'h0000_0000;

// pipeline
wire [31:0] addr_req_idle;
wire ren_idle;
wire cached_idle;

wire [31:0] addr_req_compTag;
wire ren_compTag;
wire cached_compTag;

wire [1:0] hit_compTag;
wire [31:0] s_rdata_compTag;
wire s_rvalid_compTag;
wire stall_compTag;

wire stall_mem;

//-----------------------memory definition------------------------//
// tag ram
generate
    for (i = 0;i < 2;i = i + 1) begin: tagv_ram_gen
        tag_ram tag_ram_inst(
            .clka(clk),
            .ena(1'b1),
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
            .ena(1'b1),
            .wea(data_wen[j][k]),
            .addra(data_addr[j][k]),
            .dina(data_wdata[j][k]),
            .douta(data_rdata[j][k])
        );
        end
    end
endgenerate

//-----------------------module instantiation------------------------//

Idle cache_idle(
    .s_araddr_i(s_araddr),
    .ren_i(s_arvalid),
    .cached_i(cached),

    .addr_req_o(addr_req_idle),
    .ren_o(ren_idle),
    .cached_o(cached_idle)
);

Idle_CompTag cache_idle_compTag(
    .clock_i(clk),
    .reset_i(rst),
    .flush_i(flush),
    .stall_i({stall_compTag, stall_mem}), // stall at normal stage or after write back
    .addr_req_idle_i(addr_req_idle),
    .ren_idle_i(ren_idle),
    .cached_idle_i(cached_idle),

    .ren_compTag_o(ren_compTag),
    .addr_req_compTag_o(addr_req_compTag),
    .cached_compTag_o(cached_compTag)
);

CompTag cache_compTag(
    .data_data_i(data_rdata[~hit[0]][addr_req_compTag[4:2]]),
    .hit_i(hit),
    .ren_i(ren_compTag),
    .cached_i(cached_compTag),
    .handle_miss_done_i((current_state === WRITE_BACK) ? 1'b1 : 1'b0), // if WRITE_BACK, then handle miss done

    .s_rdata_o(s_rdata_compTag),
    .s_rvalid_o(s_rvalid_compTag),
    .stall_compTag_o(stall_compTag)
);

//-----------------------state transition------------------------//

task set_before_read_mem();
    begin
        read_count <= 3'd0;
        m_arvalid_r <= 1'b1;
    end
endtask

integer index;
always @(posedge clk) begin
    if(rst == `RST_ENABLE) begin

        current_state <= IDLE_AND_COMP_TAG;
        for (index = 0;index < 2;index = index + 1) begin
            v[index] <= {128{1'b0}};
        end

        lru <= {128{1'b0}};

        m_arvalid_r <= 1'b0;
        cached_r <= 1'b0;

        read_count <= 3'd0;
        data_at_write_back <= 32'h0000_0000;

    end else begin
        case (current_state)
            IDLE_AND_COMP_TAG: begin
                if(!flush) begin
                    if (ren_compTag === 1'b1) begin
                        if (cache_ena) begin
                            if (|hit) begin
                                // update lru
                                // lru通常保持为最近使用的�?路，但是当缺失发生时，反转为�?近未使用的一�?
                                current_state <= IDLE_AND_COMP_TAG;
                                lru[index_req_latest] <= (hit[0] == 1'b1) ? 1'b0 : 1'b1;
                            end else begin
                                lru[index_req_latest] <= ~lru[index_req_latest];
                                set_before_read_mem();
                                current_state <= READ_MEM;
                            end
                        end else begin
                            set_before_read_mem();
                            current_state <= READ_MEM;
                        end
                        cached_r <= cache_ena;
                    end
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
                        if (read_count == addr_req_compTag[4:2]) begin
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
                current_state <= IDLE_AND_COMP_TAG;
                // update tagv
                if (cached) begin
                    v[replaced_way][index_req_latest] <= v[replaced_way][index_req_latest] | 1;
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

// calculate latest tag, index, offset
// used for tag_addr, data_addr request in rams
assign addr_req_latest = 
    (current_state == IDLE_AND_COMP_TAG) ? 
        addr_req_idle 
    : 
        addr_req_compTag;
assign tag_req_latest = addr_req_latest[31:12];
assign index_req_latest = addr_req_latest[11:5];
assign offset_req_latest = addr_req_latest[4:2];

// cached
assign cached = (current_state == IDLE_AND_COMP_TAG) ? cache_ena : cached_r;

// indicate which way to be replaced
assign replaced_way = lru[addr_req_compTag[11:5]];

// used for IDLE_AND_COMP_TAG
// assign valid_compTag = v;

// used for READ_MEM
// read from memory, offset width = 5 bits.
assign m_araddr = (cached) ? {addr_req_compTag[31:5], {5{1'b0}}} : addr_req_compTag;

generate
    for(i = 0;i < 2;i = i + 1) begin: gen_u1
        // used for IDLE_AND_COMP_TAG, WRITE_BACK
        assign tag_addr[i] = index_req_latest;
        // used for IDLE_AND_COMP_TAG
        assign hit[i] = ((tag_rdata[i] == addr_req_compTag[31:12]) && (v[i][addr_req_compTag[11:5]] == 1'b1)) ? 1'b1 : 1'b0;
        // used for READ_MEM
        for(j = 0;j < 8;j = j + 1) begin
            assign data_wen[i][j] = ((cached) && (m_rvalid) && (replaced_way == i) && (read_count == j)) ? 4'b1111 : 4'b0000;
            assign data_wdata[i][j] = m_rdata;
            // used for IDLE_AND_COMP_TAG, READ_MEM
            assign data_addr[i][j] = index_req_latest;
        end
        // used for WRITE_BACK
        assign tag_wen[i] = ((cached) && (current_state == WRITE_BACK) && (replaced_way == i));
        assign tag_wdata[i] = addr_req_compTag[31:12];
    end
endgenerate

// send data to CPU (at IDLE_AND_COMP_TAG or WRITE_BACK)
// assume the cpu get data from cache in 1 cycle, so don't have a reg to wait
// if hit, the cpu get data at IDLE_AND_COMP_TAG state
// else, the cpu get data at WRITE_BACK state
assign s_rvalid =
    ((current_state === IDLE_AND_COMP_TAG) && (addr_req_compTag === s_araddr)) ?
        s_rvalid_compTag
    :
        ((current_state === WRITE_BACK) ?
            1'b1
        :
            1'b0);

assign s_rdata = 
    (current_state == IDLE_AND_COMP_TAG) ?
        s_rdata_compTag
    :
        ((current_state == WRITE_BACK) ? 
            data_at_write_back
        :
            {32{1'b0}});

assign stall_mem = (current_state === READ_MEM) ? 1'b1 : 1'b0;

endmodule

// send request to ram
module Idle(
    input [31:0] s_araddr_i,
    input ren_i,
    input cached_i,

    output [31:0] addr_req_o,
    output wire ren_o,
    output wire cached_o
);
    assign addr_req_o = (ren_i) ? s_araddr_i : 32'h0000_0000;
    assign ren_o = ren_i;
    assign cached_o = cached_i;
endmodule
// determine hit or not & get data from memory
// if failed go to READ_MEM
module CompTag(
    input [31:0] data_data_i,
    input [1:0] hit_i,
    input ren_i,
    input cached_i,
    input handle_miss_done_i,

    output [31:0] s_rdata_o,
    output s_rvalid_o,
    output wire stall_compTag_o
);

    genvar i;
    generate
        assign s_rdata_o = data_data_i;
        assign s_rvalid_o = 
            ((cached_i === 1'b1) && (ren_i === 1'b1)) ? |hit_i : 1'b0;
        assign stall_compTag_o = 
            (cached_i === 1'b1) ?
                (ren_i & (~((|hit_i) | handle_miss_done_i)))
            :
                (ren_i & (~handle_miss_done_i));
    endgenerate

endmodule
// transfer addr req
module Idle_CompTag(
    input clock_i,
    input reset_i,
    input flush_i,
    input [1:0] stall_i,
    input [31:0] addr_req_idle_i,
    input ren_idle_i,
    input cached_idle_i,

    output reg [31:0] addr_req_compTag_o,
    output reg ren_compTag_o,
    output reg cached_compTag_o
);
    always @(posedge clock_i) begin
        if (reset_i == `RST_ENABLE) begin
            addr_req_compTag_o <= 32'h0000_0000;
            ren_compTag_o <= 1'b0;
        end else if ((|stall_i === 1'b1) || (flush_i)) begin
            addr_req_compTag_o <= addr_req_compTag_o;
            ren_compTag_o <= ren_compTag_o;
            cached_compTag_o <= cached_compTag_o;
        end else begin
            addr_req_compTag_o <= addr_req_idle_i;
            ren_compTag_o <= ren_idle_i;
            cached_compTag_o <= cached_idle_i;
        end
    end
endmodule