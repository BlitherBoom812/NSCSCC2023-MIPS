//~ `New testbench
`timescale 1ns / 1ps
`include "defines.vh"

`define RAM_SIZE 1024
`define LINE_OFFSET_WIDTH 6 // For data_cache is 6 (2^6 Bytes = 64 Bytes = 16 words per line); For my_DCache, is 5 (2^5 Bytes = 32 Bytes = 8 words per line)
`define SEND_NUM 16 // (The num of words) For data_cache is 16; For my_DCache, is 8

`define TEST_REQ_NUM 8'd12

// PROBLEM: no implementation of full read & write(configuration about awlen, etc.)

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
    reg          m_wready;
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
        .s_addr   ({s_addr[31:2], 2'b00}),
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

    reg     [ 7:0] data_req_count;  // count the number of data request now
    reg     [ 2:0] cpu_state;
    integer        data_fetch_cycle;  // calculate the cycles cost by one data.
    reg            flush_done = 0;

    reg     [31:0] ram_top;
    reg     [31:0] ram_data                                                    [`RAM_SIZE - 1:0];
    reg     [31:0] ram_address                                                 [`RAM_SIZE - 1:0];

    parameter [2:0] state_turn_on = 3'b00;  // state from cool start
    parameter [2:0] state_req = 3'b010;  // looping for request data
    parameter [2:0] state_wait_inst_read = 3'b011;
    parameter [2:0] state_wait_data_read = 3'b100;
    parameter [2:0] state_wait_data_write = 3'b101;
    parameter [2:0] state_decode = 3'b110;

    assign cache_ena = s_addr[31];
    assign flush     = s_arvalid && (s_addr == 32'hffff_ffff);

    integer i;
    initial begin
        s_addr           = 0;
        s_arvalid        = 0;
        s_awvalid        = 0;
        s_wdata          = 0;

        data_req_count   = 0;
        cpu_state        = state_turn_on;
        data_fetch_cycle = 0;
        flush_done       = 0;

        ram_top          = 0;
        for (i = 0; i < `RAM_SIZE; i = i + 1) begin
            ram_data[i]    = 32'hffff_ffff;
            ram_address[i] = 32'hffff_ffff;
        end
    end
    // assume that 0xffff_ffff means flush for a cycle.
    // if odd, write; else read.
    // first bit means cache_ena
    // second hex means wen
    // write data is {addr[31:24], 345678}
    task set_data_addr();
        begin
            case (data_req_count)
                // read
                0:       s_addr <= 32'hf000_0000;  
                1:       s_addr <= 32'hb000_0004;  
                // write
                // read after write
                2:      s_addr <= 32'hff00_0000 + 1;  
                3:      s_addr <= 32'hff00_0000;  
                // write after read
                4:      s_addr <= 32'hff00_0000;  
                5:      s_addr <= 32'hff10_0000 + 1;  
                // replace
                6:      s_addr <= 32'hff20_0000 + 1;  
                7:      s_addr <= 32'hff30_0000 + 1;  
                8:      s_addr <= 32'hff40_0000 + 1;  
                9:      s_addr <= 32'hff40_0000;  
                10:      s_addr <= 32'hfc10_0000 + 1;
                11:      s_addr <= 32'hfc10_0000;              
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
            s_addr           <= 0;
            s_arvalid        <= 0;
            s_awvalid        <= 0;
            s_wdata          <= 0;

            data_req_count   <= 0;
            cpu_state        <= state_turn_on;
            data_fetch_cycle <= 0;
            flush_done       <= 0;
            ram_top          <= 0;

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
                        cpu_state <= state_decode;
                    end else begin
                        set_data_addr();
                        cpu_state <= state_decode;
                    end
                end
                state_decode: begin
                    if (s_addr[0] == 1 && (!(s_addr == 32'hffffffff))) begin
                        s_awvalid <= s_addr[27:24];
                        s_wdata   <= {s_addr[31:24], 24'h345678};
                    end else begin
                        s_arvalid <= 1'b1;
                    end
                    cpu_state <= state_req;
                end
                state_req: begin
                    if (data_req_count == `TEST_REQ_NUM + 1) begin
                        $display("accessing data done, inst num: %d", data_req_count);
                        for (i = 0;i < ram_top;i = i + 1) begin
                            $display("mem[%h] = %h", ram_address[i], ram_data[i]);
                        end
                        $finish;
                    end else begin
                        if (flush && (!flush_done)) begin
                            on_flush();
                            cpu_state <= state_turn_on;
                        end else begin
                            if (s_wready) begin
                                $display("write data[%h]: %h, time consuming: %d cycles", {s_addr[31:2], 2'b00}, {(s_addr[27] == 1'b1) ? s_wdata[31:24] : 8'hzz, (s_addr[26] == 1'b1) ? s_wdata[23:16] : 8'hzz, (s_addr[25] == 1'b1) ? s_wdata[15:8] : 8'hzz, (s_addr[24] == 1'b1) ? s_wdata[7:0] : 8'hzz},
                                         data_fetch_cycle);
                                cpu_state <= state_turn_on;
                            end else if (s_rvalid == 1'b1) begin
                                $display("read data[%h]: %h, time consuming: %d cycles", {s_addr[31:2], 2'b00}, s_rdata, data_fetch_cycle);
                                cpu_state        <= state_turn_on;
                                data_fetch_cycle <= 0;
                            end else begin
                                if (data_fetch_cycle > 0) begin
                                    s_arvalid <= 1'b0;
                                    s_awvalid <= 0;
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
    reg [                  31:0] m_awaddr_reg;
    reg                          write_state;
    // state
    parameter [7:0] RAM_IDLE = 1;
    parameter [7:0] RAM_READ = 2;
    parameter [7:0] RAM_WRITE = 3;
    initial begin
        ram_state    = RAM_IDLE;
        send_count   = 0;
        m_araddr_reg = 0;
        m_awaddr_reg = 0;
    end

    function [32:0] check_revised(input [31:0] address);
        reg [31:0] revised_index;
        reg        revised;
        begin
            revised = 0;
            for (i = 0; i < `RAM_SIZE; i = i + 1) begin
                if (ram_address[i] == address) begin
                    revised_index = i;
                    revised       = 1;
                end
            end
            check_revised = {revised, revised_index};
        end
    endfunction

    function [31:0] read_ram(input [31:0] address);
        reg [32:0] revised;
        begin
            revised  = check_revised(address);
            read_ram = (revised[32] == 1'b1) ? ram_data[revised[31:0]] : address;
            if (revised[32] == 1'b1) begin
                $display("read mem data[%h]: %h, revised: %d", address, read_ram, revised[32]);
            end
        end
    endfunction

    function write_ram(input [31:0] address, input [3:0] wen, input [31:0] wdata);
        reg [32:0] revised;
        reg [31:0] index;
        begin
            revised = check_revised(address);
            index   = revised[31:0];
            if (revised[32] == 1'b0) begin
                ram_data[ram_top] = {(wen[3] == 1'b1) ? wdata[31:24] : ram_data[ram_top][31:24], (wen[2] == 1'b1) ? wdata[23:16] : ram_data[ram_top][23:16], (wen[1] == 1'b1) ? wdata[15:8] : ram_data[ram_top][15:8], (wen[0] == 1'b1) ? wdata[7:0] : ram_data[ram_top][7:0]};
                // $display("revise mem data[%h]: %h, wen: %b", address, ram_data[ram_top], wen);
                ram_address[ram_top] = address;
                ram_top   = ram_top + 1;
                write_ram = 1;
            end else begin
                ram_data[index] = {(wen[3] == 1'b1) ? wdata[31:24] : ram_data[index][31:24], (wen[2] == 1'b1) ? wdata[23:16] : ram_data[index][23:16], (wen[1] == 1'b1) ? wdata[15:8] : ram_data[index][15:8], (wen[0] == 1'b1) ? wdata[7:0] : ram_data[index][7:0]};
                $display("revise mem data[%h]: %h, wen: %b", address, ram_data[index], wen);
                write_ram = 0;
            end
        end
    endfunction

    always @(posedge clk) begin
        if (rst == `RST_ENABLE) begin
            m_arready    <= 0;
            m_rdata      <= 0;
            m_rlast      <= 0;
            m_rvalid     <= 0;
            m_awready    <= 0;
            // m_wready     <= 0;
            m_bvalid     <= 0;

            ram_state    <= RAM_IDLE;
            send_count   <= 0;
            m_araddr_reg <= 0;
            m_awaddr_reg <= 0;
            $display("start ram");
        end else begin
            case (ram_state)
                RAM_IDLE: begin
                    if (m_awvalid == 1'b1) begin
                        m_awready    <= 1'b1;
                        send_count   <= 0;
                        ram_state    <= RAM_WRITE;
                        m_awaddr_reg <= m_awaddr;
                    end else if (m_arvalid == 1'b1) begin
                        m_arready    <= 1'b1;
                        send_count   <= 0;
                        ram_state    <= RAM_READ;
                        m_araddr_reg <= m_araddr;
                    end
                end
                RAM_READ: begin
                    if (cache_ena) begin
                        m_arready <= 1'b0;
                        m_rdata   <= read_ram({m_araddr_reg[31:`LINE_OFFSET_WIDTH], send_count << 2});
                        if (m_rready) begin
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
                        m_arready <= 1'b0;
                        m_rdata   <= read_ram({m_araddr_reg[31:2], 2'b00});
                        if (m_rready) begin
                            if (send_count == 0) begin
                                m_rlast    <= 1'b1;
                                m_rvalid   <= 1'b1;
                                send_count <= send_count + 1;
                            end else if (send_count == 1) begin
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
                end
                RAM_WRITE: begin
                    if (cache_ena) begin
                        m_awready <= 1'b0;
                        if (m_wvalid == 1'b1) begin
                            write_state <= write_ram({m_awaddr_reg[31:`LINE_OFFSET_WIDTH], send_count << 2}, m_wstrb, m_wdata);
                            if (m_wlast == 1'b1) begin
                                // m_wready   <= 1'b0;
                                send_count <= 0;
                                m_bvalid   <= 1'b1;
                                ram_state  <= RAM_IDLE;
                            end else begin
                                // m_wready   <= 1'b1;
                                send_count <= send_count + 1;
                                m_bvalid   <= 1'b0;
                            end
                        end else begin
                            // m_wready <= 1'b0;
                        end
                    end else begin
                        m_awready <= 1'b0;
                        if (m_wvalid == 1'b1) begin
                            write_state <= write_ram({m_awaddr_reg[31:2], 2'b00}, m_wstrb, m_wdata);
                            if (m_wlast == 1'b1) begin
                                // m_wready   <= 1'b0;
                                send_count <= 0;
                                m_bvalid   <= 1'b1;
                                ram_state  <= RAM_IDLE;
                            end else begin
                                // m_wready   <= 1'b1;
                                send_count <= send_count + 1;
                                m_bvalid   <= 1'b0;
                            end
                        end
                    end
                end
            endcase
        end
    end
    always @(*) begin
        m_wready = (ram_state == RAM_WRITE) ? 1'b1 : 1'b0;
    end
endmodule
