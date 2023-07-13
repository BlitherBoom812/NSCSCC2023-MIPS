`include "defines.v"

module inst_cache_fifo(
    input         rst            ,
    input         clk            ,
    input         cache_ena      ,
    
    // master
    output [31:0] m_araddr       ,
    output        m_arvalid      ,
    input         m_arready      ,
    input  [31:0] m_rdata        ,  // cache作为主设备从内存（从设备）中读取得到的数据
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
parameter IDLE = 4'd0;  // wait addr and request
parameter COMP_TAG = 4'd1;   // compare tag between addr and tagv & update lru
parameter READ_MEM = 4'h2;  // read new block from mem to addr, and write new block inst cache
parameter WRITE_BACK = 4'h3;    // update tagv and lru & send missing data back to cpu
reg [3:0] current_state = IDLE;
//-----------------------memory definition------------------------//
// tag & v ram
// depth = 128, width = 20, 2 instances
// 19:0 is tag
wire tag_wen [1:0];
wire [6:0] tag_addr [1:0];  // index(0~127)
wire [19:0] tag_wdata [1:0];    // tag write data
wire [19:0] tag_rdata [1:0];    // tag read data
genvar i;
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

reg [127:0] v [1:0];// v(0~127, 2 way)
reg [127:0] lru;    // lru(0~127)

// data ram
// 128 sets, 2 way/set, 8 bank/way => 16 bank/set.
// depth = 128, width = 32, 16 instances.
wire [3:0] data_wen [1:0][7:0]; // control 4 bytes wen
wire [6:0] data_addr [1:0][7:0];  // index(0~127)
wire [31:0] data_wdata [1:0][7:0];    // data write data
wire [31:0] data_rdata [1:0][7:0];    // data read data
genvar j, k;
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

//-----------------------signal definition-----------------------//
wire [1:0] hit;
wire replaced_way;
reg [31:0] addr_req;
// reg s_rvalid_r;
reg m_arvalid_r;
reg m_rready_r;
//-----------------------state transition------------------------//
reg [2:0] read_count = 3'd0;    // transfer 8 words(banks) per time
reg [31:0] data_at_write_back = 32'h0000_0000;
integer index;
always @(posedge clk) begin
    if(rst == `RST_ENABLE) begin
        current_state <= IDLE;
        for (index = 0;index < 2;index = index + 1) begin
            v[index] <= {128{1'b0}};
        end

        lru <= {128{1'b0}};

        addr_req <= 32'h0000_0000;

        m_arvalid_r <= 1'b0;
        m_rready_r <= 1'b0;

        read_count <= 3'd0;
        data_at_write_back <= 32'h0000_0000;

    end else begin
        case (current_state)
            IDLE: begin
                if(!flush) begin
                    if (s_arvalid == 1'b1) begin
                        addr_req <= s_araddr;
                        current_state <= COMP_TAG;
                    end
                end
            end

            COMP_TAG: begin
                if (|hit) begin
                    current_state <= IDLE;
                    lru[addr_req[11:5]] <= (hit[0] == 1'b1) ? 1'b0 : 1'b1;
                end
                else begin
                    current_state <= READ_MEM;
                    read_count <= 3'd0;
                    m_arvalid_r <= 1'b1;
                    m_rready_r <= 1'b1;
                end
            end

            // read mem & write to data ram
            READ_MEM: begin
                if (m_arready == 1'b1) begin
                    m_arvalid_r <= 1'b0;
                end
                if (m_rvalid) begin
                    read_count <= read_count + 1'b1;
                    // if axi outputs data needed, then put it into data_at_write_back, and send to s_rdata at WRITE_BACK
                    if (read_count == addr_req[4:2]) begin
                        data_at_write_back <= m_rdata;
                    end
                    // write data to data ram (see assign)
                end
                if (m_rlast == 1'b1) begin 
                    current_state <= WRITE_BACK;
                    read_count <= 3'b0;
                end
            end

            // update tagv & send missing data back to cpu
            WRITE_BACK: begin
                current_state <= IDLE;
                // update tagv
                begin
                    v[hit] <= v[hit] | (1 << addr_req[11:5]);
                end
            end
            default: ;
        endcase
    end
end

//-----------------------wire assign------------------------//
// don't know when the axi_ram will reply with arready=1, so have a reg to wait for that
assign replaced_way = lru[addr_req[11:5]];
assign m_arvalid = m_arvalid_r;
assign m_rready = 1'b1;

generate
for(i = 0;i < 2;i = i + 1) begin: gen_u1
    // used for IDLE
    assign tag_addr[i] = s_araddr[11:5];
    // used for COMP_TAG
    assign hit[i] = (tag_rdata[i] == addr_req[31:12]) && (v[i][addr_req[11:5]] == 1'b1);
    // used for READ_MEM
    // read from memory, offset width = 5 bits.
    assign m_araddr = {addr_req[31:5], {5{1'b0}}};
    // write for memory
    for(j = 0;j < 8;j = j + 1) begin
        assign data_wen[i][j] = ((m_rvalid) && (replaced_way == i) && (read_count == j)) ? 4'b1111 : 4'b0000;
        assign data_wdata[i][j] = m_rdata;
        assign data_addr[i][j] = addr_req[11:5];
    end
    // used for WRITE_BACK
    assign tag_wen[i] = ((current_state == WRITE_BACK) && (replaced_way == i));
    assign tag_wdata[i] = addr_req[31:12];
    assign tag_addr[i] = addr_req[11:5];
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
            data_rdata[0][addr_req[4:2]]
        :
            data_rdata[1][addr_req[4:2]])
    :
        ((current_state == WRITE_BACK) ? 
            data_at_write_back
        :
            {32{1'b0}});

endmodule