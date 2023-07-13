//~ `New testbench
`timescale 1ns / 1ps
`include "../defines.v"

`define LINE_OFFSET_WIDTH 5 // For inst_cache_fifo is 6 (2^6 Bytes = 64 Bytes = 16 words per line); For my_ICache, is 5 (2^5 Bytes = 32 Bytes = 8 words per line)
`define SEND_NUM 8 // For inst_cache_fifo is 8; For my_ICache, is 4
module tb_inst_cache_fifo ();

    // top parameters
    parameter [6:0] SEND_NUM = `SEND_NUM;

    // inst_cache_fifo Parameters
    parameter PERIOD = 10;

    // inst_cache_fifo Inputs
    reg         rst = `RST_DISABLE;
    reg         clk = 0;
    wire        cache_ena;
    reg         m_arready = 0;
    reg  [31:0] m_rdata = 0;
    reg         m_rlast = 0;
    reg         m_rvalid = 0;
    reg  [31:0] s_araddr = 0;  // request addr from cpu
    reg         s_arvalid = 0;
    wire        flush;

    // inst_cache_fifo Outputs
    wire [31:0] m_araddr;  // request addr to ram
    wire        m_arvalid;
    wire        m_rready;
    wire [31:0] s_rdata;
    wire        s_rvalid;


    initial begin
        forever #(PERIOD / 2) clk = ~clk;
    end

    initial begin
        #(PERIOD * 2) rst = `RST_ENABLE;
        #(PERIOD * 2) rst = `RST_DISABLE;
    end

    inst_cache_fifo u_inst_cache_fifo (
        .rst      (rst),
        .clk      (clk),
        .cache_ena(cache_ena),
        .m_arready(m_arready),
        .m_rdata  (m_rdata),
        .m_rlast  (m_rlast),
        .m_rvalid (m_rvalid),
        .s_araddr (s_araddr),
        .s_arvalid(s_arvalid),
        .flush    (flush),

        .m_araddr (m_araddr),
        .m_arvalid(m_arvalid),
        .m_rready (m_rready),
        .s_rdata  (s_rdata),
        .s_rvalid (s_rvalid)
    );

    // goal: test icache
    // 1. verify testbench correctness (ok)
    // 1.1 test basic cache function (ok)
    // 1.2 test flush function: if flush, the cpu req state goes back to turn_on(ok)
    // (p.s the 1.2 will be useful when optimizing the sram_interface. 我们可以区分热启动和冷启动，冷启动时损失一个周期，热启动时不损失周期。)
    // 1.3 测试行替换功能(ok)
    // 2. test the new inst cache
    // 2.1 test basic cache function (ok)
    // 2.2 test cache_ena (ok)
    // 2.3 eliminate x & z (ok);
    // 2.4 bug: 7th inst error!. outputs 32'hf0000054. but 8th is right. reason: the problem of addr_req_r and s_araddr.
    // cpu simulation
    reg     [3:0] inst_req_count;  // count the number of inst request now
    reg     [2:0] cpu_state;
    integer       inst_fetch_cycle;  // calculate the cycles cost by one inst.
    reg           flush_done = 0;

    parameter [2:0] state_turn_on = 3'b00;  // state from cool start
    parameter [2:0] state_req = 3'b010;  // looping for request inst
    parameter [2:0] state_wait_inst_read = 3'b011;
    parameter [2:0] state_wait_data_read = 3'b100;
    parameter [2:0] state_wait_data_write = 3'b101;

    assign cache_ena = s_araddr[31];
    assign flush     = s_arvalid && (s_araddr == 32'hffff_ffff);

    initial begin
        inst_req_count   = 0;
        s_arvalid        = 0;
        cpu_state        = state_turn_on;
        inst_fetch_cycle = 0;
        flush_done       = 0;
    end
    // assume that 0xffff_ffff means flush for a cycle.
    task set_inst_addr();
        begin
            case (inst_req_count)
                0: s_araddr <= 32'hf000_0000;
                1: s_araddr <= 32'hf000_0004;
                2: s_araddr <= 32'hf000_0008;
                3: s_araddr <= 32'hf000_000C;
                4: s_araddr <= 32'hf000_0040;
                5: s_araddr <= 32'hf000_0044;
                6: s_araddr <= 32'hffff_ffff;
                7: s_araddr <= 32'hf000_0014;
                8: s_araddr <= 32'hf000_0018;
                default: s_araddr <= 32'hf000_0000;
            endcase
            inst_req_count   <= inst_req_count + 1;
            inst_fetch_cycle <= 0;
        end
    endtask

    task on_flush();
        begin
            $display("fetch inst[%h]: flush is on, time consuming: %d cycles", s_araddr, inst_fetch_cycle);
            s_arvalid  <= 1'b0;
            flush_done <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (rst == `RST_ENABLE) begin
            inst_req_count   <= 0;
            s_arvalid        <= 0;
            m_arready        <= 0;
            cpu_state        <= state_turn_on;
            inst_fetch_cycle <= 0;
            flush_done       <= 0;
            $display("start fetch inst");
        end else begin
            inst_fetch_cycle <= inst_fetch_cycle + 1;
            case (cpu_state)
                state_turn_on: begin
                    if (flush && (!flush_done)) begin
                        on_flush();
                        cpu_state <= state_turn_on;
                    end else if (flush_done) begin
                        flush_done <= 1'b0;
                        set_inst_addr();
                        s_arvalid <= 1'b1;
                        cpu_state <= state_req;
                    end else begin
                        set_inst_addr();
                        s_arvalid <= 1'b1;
                        cpu_state <= state_req;
                    end
                end
                state_req: begin
                    if (inst_req_count == 4'd10) begin
                        $display("fetch inst done");
                        $finish;
                    end else begin
                        if (flush && (!flush_done)) begin
                            on_flush();
                            cpu_state <= state_turn_on;
                        end else begin
                            if (s_rvalid == 1'b1) begin
                                $display("fetch inst[%h]: %h, time consuming: %d cycles", s_araddr, s_rdata, inst_fetch_cycle);
                                cpu_state        <= state_req;
                                inst_fetch_cycle <= 0;
                                set_inst_addr();
                                s_arvalid <= 1'b1;
                            end else begin
                                if (inst_fetch_cycle > 0) begin
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
                    if (m_arvalid == 1'b0) begin
                        m_arready <= 1'b0;
                        m_rdata   <= {m_araddr_reg[31:`LINE_OFFSET_WIDTH], send_count << 2};
                        if (send_count == SEND_NUM) begin
                            m_rlast    <= 1'b1;
                            m_rvalid   <= 1'b1;
                            send_count <= send_count + 1;
                        end else if (send_count == SEND_NUM + 1) begin
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
                end
            endcase
        end
    end

endmodule
