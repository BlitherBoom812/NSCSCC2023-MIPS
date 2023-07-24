//~ `New testbench
`timescale 1ns / 1ps
`include "defines.vh"


`define LINE_OFFSET_WIDTH 5 // For data_cache is 6 (2^6 Bytes = 64 Bytes = 16 words per line); For my_DCache, is 5 (2^5 Bytes = 32 Bytes = 8 words per line)
`define SEND_NUM 8 // (The num of words) For data_cache is 16; For my_DCache, is 8

`define TEST_REQ_NUM 4'd12

module tb_data_cache_fifo ();


    // top parameters
    // parameter [6:0] SEND_NUM = `SEND_NUM;

    // data_cache_fifo Parameters
    parameter PERIOD = 10;
    parameter IDLE = 4'd0;
    parameter COMP_TAG = 4'd1;
    parameter READ_MEM = 4'h2;
    parameter SELECT = 4'h3;
    parameter REPLACE = 4'h4;
    parameter REFILL = 4'h5;

    // data_cache_fifo Inputs
    reg          clk = 0;
    reg          rst = 0;
    wire         cache_ena;
    reg          m_arready = 0;
    reg  [ 31:0] m_rdata = 0;
    reg          m_rlast = 0;
    reg          m_rvalid = 0;
    reg          m_awready = 0;
    reg          m_wready = 0;
    reg          m_bvalid = 0;
    reg  [ 31:0] s_addr = 0;
    reg          s_arvalid = 0;
    reg  [  3:0] s_awvalid = 0;
    reg  [ 31:0] s_wdata = 0;
    wire         flush;

    // data_cache_fifo Outputs
    wire [ 31:0] m_araddr;
    wire         m_arvalid;
    wire         m_rready;
    wire [  3:0] m_awid;
    wire [7 : 0] m_awlen;
    wire [2 : 0] m_awsize;
    wire [1 : 0] m_awburst;
    wire [1 : 0] m_awlock;
    wire [3 : 0] m_awcache;
    wire [2 : 0] m_awprot;
    wire [ 31:0] m_awaddr;
    wire         m_awvalid;
    wire [  3:0] m_wid;
    wire [ 31:0] m_wdata;
    wire         m_wlast;
    wire [  3:0] m_wstrb;
    wire         m_wvalid;
    wire         m_bready;
    wire [ 31:0] s_rdata;
    wire         s_rvalid;
    wire         s_wready;


    initial begin
        forever #(PERIOD / 2) clk = ~clk;
    end

    initial begin
        #(PERIOD * 2) rst = `RST_ENABLE;
        #(PERIOD * 2) rst = `RST_DISABLE;
    end

    data_cache_fifo #(
        .IDLE    (IDLE),
        .COMP_TAG(COMP_TAG),
        .READ_MEM(READ_MEM),
        .SELECT  (SELECT),
        .REPLACE (REPLACE),
        .REFILL  (REFILL)
    ) u_data_cache_fifo (
        .clk      (clk),
        .rst      (rst),
        .cache_ena(cache_ena),
        .m_arready(m_arready),
        .m_rdata  (m_rdata[31:0]),
        .m_rlast  (m_rlast),
        .m_rvalid (m_rvalid),
        .m_awready(m_awready),
        .m_wready (m_wready),
        .m_bvalid (m_bvalid),
        .s_addr   (s_addr[31:0]),
        .s_arvalid(s_arvalid),
        .s_awvalid(s_awvalid[3:0]),
        .s_wdata  (s_wdata[31:0]),
        .flush    (flush),

        .m_araddr (m_araddr[31:0]),
        .m_arvalid(m_arvalid),
        .m_rready (m_rready),
        .m_awid   (m_awid[3:0]),
        .m_awlen  (m_awlen[7 : 0]),
        .m_awsize (m_awsize[2 : 0]),
        .m_awburst(m_awburst[1 : 0]),
        .m_awlock (m_awlock[1 : 0]),
        .m_awcache(m_awcache[3 : 0]),
        .m_awprot (m_awprot[2 : 0]),
        .m_awaddr (m_awaddr[31:0]),
        .m_awvalid(m_awvalid),
        .m_wid    (m_wid[3:0]),
        .m_wdata  (m_wdata[31:0]),
        .m_wlast  (m_wlast),
        .m_wstrb  (m_wstrb[3:0]),
        .m_wvalid (m_wvalid),
        .m_bready (m_bready),
        .s_rdata  (s_rdata[31:0]),
        .s_rvalid (s_rvalid),
        .s_wready (s_wready)
    );


    // goal: test dcache
    // 1. verify testbench correctness (ok)
    // 1.1 test basic cache function (ok)
    // 1.2 test flush function: if flush, the cpu req state goes back to turn_on(ok)
    // (p.s the 1.2 will be useful when optimizing the sram_interface. 我们可以区分热启动和冷启动，冷启动时损失一个周期，热启动时不损失周期。)
    // 2. test new dcache
    // 2.1 test read process(ok)
    // 2.2 test write process
    // 2.3 test read after write, and write after read

    reg     [3:0] data_req_count;  // count the number of data request now
    reg     [2:0] cpu_state;
    integer       data_fetch_cycle;  // calculate the cycles cost by one data.
    reg           flush_done = 0;

    parameter [2:0] state_turn_on = 3'b00;  // state from cool start
    parameter [2:0] state_req = 3'b010;  // looping for request data
    parameter [2:0] state_wait_inst_read = 3'b011;
    parameter [2:0] state_wait_data_read = 3'b100;
    parameter [2:0] state_wait_data_write = 3'b101;

    assign cache_ena = s_addr[31];
    // assign  cache_ena = 1'b1;
    assign flush     = s_arvalid && (s_addr == 32'hffff_ffff);

    initial begin
        data_req_count   = 0;
        s_arvalid        = 0;
        cpu_state        = state_turn_on;
        data_fetch_cycle = 0;
        flush_done       = 0;
    end
    // assume that 0xffff_ffff means flush for a cycle.
    task set_data_addr();
        begin
            case (data_req_count)
                0: s_addr <= 32'hf000_0000; // long
                1: s_addr <= 32'hb000_0004; // long
                2: s_addr <= 32'hf000_0008; // short
                3: s_addr <= 32'ha000_000C; // long
                4: s_addr <= 32'hf000_000C; // short
                5: s_addr <= 32'hb000_0004; // long
                6: s_addr <= 32'hffff_ffff; // flush
                7: s_addr <= 32'hf000_0014; // short
                8: s_addr <= 32'hb000_0018; // short
                9: s_addr <= 32'h0000_0004; // long
                10: s_addr <= 32'h0000_0008; // long
                11: s_addr <= 32'h0000_0024; // long
                default: s_addr <= 32'hf000_0000;
            endcase
            data_req_count   <= data_req_count + 1;
            data_fetch_cycle <= 0;
        end
    endtask

    task on_flush();
        begin
            $display("fetch data[%h]: flush is on, time consuming: %d cycles", s_addr, data_fetch_cycle);
            s_arvalid  <= 1'b0;
            flush_done <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (rst == `RST_ENABLE) begin
            data_req_count   <= 0;
            s_arvalid        <= 0;
            m_arready        <= 0;
            cpu_state        <= state_turn_on;
            data_fetch_cycle <= 0;
            flush_done       <= 0;
            $display("start fetch data");
        end else begin
            data_fetch_cycle <= data_fetch_cycle + 1;
            case (cpu_state)
                state_turn_on: begin
                    if (flush && (!flush_done)) begin
                        on_flush();
                        cpu_state <= state_turn_on;
                    end else if (flush_done) begin
                        flush_done <= 1'b0;
                        set_data_addr();
                        s_arvalid <= 1'b1;
                        cpu_state <= state_req;
                    end else begin
                        set_data_addr();
                        s_arvalid <= 1'b1;
                        cpu_state <= state_req;
                    end
                end
                state_req: begin
                    if (data_req_count == `TEST_REQ_NUM + 1) begin
                        $display("fetch data done");
                        $finish;
                    end else begin
                        if (flush && (!flush_done)) begin
                            on_flush();
                            cpu_state <= state_turn_on;
                        end else begin
                            if (s_rvalid == 1'b1) begin
                                $display("fetch data[%h]: %h, time consuming: %d cycles", s_addr, s_rdata, data_fetch_cycle);
                                cpu_state        <= state_req;
                                data_fetch_cycle <= 0;
                                set_data_addr();
                                s_arvalid <= 1'b1;
                            end else begin
                                if (data_fetch_cycle > 0) begin
                                    s_arvalid <= 1'b0;
                                end
                            end
                        end
                    end
                end
            endcase
        end
    end

    // ram simulation
    reg [                   7:0] ram_state;
    reg [`LINE_OFFSET_WIDTH-1:0] send_count;
    reg [                  31:0] m_araddr_reg;  // store the address of the current read request
    parameter [7:0] RAM_IDLE = 1;
    parameter [7:0] RAM_READ = 2;
    parameter [7:0] RAM_WRITE = 3;

    initial begin
        ram_state  = RAM_IDLE;
        m_arready  = 0;
        m_rlast    = 0;
        m_rvalid   = 0;
        send_count = 0;
    end

    always @(posedge clk) begin
        if (rst == `RST_ENABLE) begin
            ram_state  <= RAM_IDLE;
            m_arready  <= 0;
            m_rlast    <= 0;
            m_rvalid   <= 0;
            send_count <= 0;
            $display("start ram");
        end else begin
            case (ram_state)
                RAM_IDLE: begin
                    if (m_arvalid == 1'b1) begin
                        m_arready    <= 1'b1;
                        send_count   <= 0;
                        ram_state    <= RAM_READ;
                        m_araddr_reg <= m_araddr;
                    end
                end
                RAM_READ: begin
                    if (cache_ena) begin
                        if (m_arvalid == 1'b0) begin
                            m_arready <= 1'b0;
                            m_rdata   <= {m_araddr_reg[31:`LINE_OFFSET_WIDTH], send_count << 2};
                            if (send_count == (`SEND_NUM - 1)) begin
                                m_rlast    <= 1'b1;
                                m_rvalid   <= 1'b1;
                                send_count <= send_count + 1;
                            end else if (send_count == `SEND_NUM) begin
                                m_rlast    <= 1'b0;
                                m_rvalid   <= 1'b0;
                                send_count <= 0;
                                ram_state  <= RAM_IDLE;
                            end else begin
                                m_rlast    <= 1'b0;
                                m_rvalid   <= 1'b1;
                                send_count <= send_count + 1;
                            end
                        end
                    end else begin
                    end
                end
            endcase
        end
    end


endmodule
