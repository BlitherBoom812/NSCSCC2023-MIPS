`include "defines.vh"
module sram_interface (
    input wire clock_i,
    input wire reset_i,
    input wire flush_i,

    // from and to cpu
    input  wire [31:0] inst_cpu_addr_i,
    input  wire        inst_cpu_ren_i,
    input  wire        inst_cpu_cache_ena_i,
    output wire [31:0] inst_cpu_rdata_o,
    output wire        inst_cpu_ok_o,
    output wire        inst_cpu_stall_o,

    input  wire [31:0] data_cpu_addr_i,
    input  wire        data_cpu_ren_i,
    input  wire [ 3:0] data_cpu_wen_i,
    input  wire [31:0] data_cpu_wdata_i,
    output wire [31:0] data_cpu_rdata_o,
    output wire        data_cpu_stall_o,

    // from and to cache
    input  wire        inst_cache_ok_i,
    input  wire [31:0] inst_cache_rdata_i,
    output wire [31:0] inst_cache_addr_o,
    output wire        inst_cache_ren_o,

    input  wire        data_cache_read_ok_i,
    input  wire        data_cache_write_ok_i,
    input  wire [31:0] data_cache_rdata_i,
    output wire [31:0] data_cache_addr_o,
    output reg  [ 3:0] data_cache_wen_o,
    output reg         data_cache_ren_o,
    output reg  [31:0] data_cache_wdata_o,

    output wire inst_cache_ena_o,
    output reg  data_cache_ena_o,
    output reg  is_inst_read_o,
    output reg  is_data_read_o,

    output wire is_flush_o
);

    //MMU 
    assign inst_cache_addr_o = (inst_cpu_addr_i[31:30] == 2'b10) ? {3'b000, inst_cpu_addr_i[28:0]} : inst_cpu_addr_i;
    assign data_cache_addr_o = (data_cpu_addr_i[31:30] == 2'b10) ? {3'b000, data_cpu_addr_i[28:0]} : data_cpu_addr_i;

    parameter [2:0] state_idle = 3'b000;
    parameter [2:0] state_req = 3'b001;
    parameter [2:0] state_data_read_wait_inst_ok = 3'b010;
    parameter [2:0] state_data_write_wait_inst_ok = 3'b011;
    parameter [2:0] state_wait_data_read = 3'b100;
    parameter [2:0] state_wait_data_write = 3'b101;
    parameter [2:0] state_wait_inst_read = 3'b110;
    reg [ 2:0] state;

    reg data_raddr_r;

    reg [ 3:0] data_wen_r;
    reg [31:0] data_waddr_r;
    reg [31:0] data_wdata_r;

    reg [31:0] dcache_rdata_buf;

    assign is_flush_o       = flush_i;

    // inst signal pass
    assign inst_cpu_rdata_o = inst_cache_rdata_i;
    assign inst_cpu_ok_o    = inst_cache_ok_i;
    assign inst_cache_ren_o = inst_cpu_ren_i;
    assign inst_cache_ena_o = inst_cpu_cache_ena_i;

    function [1 + 1 + 32 - 1:0] inst_cpu_stall_data_cpu_stall_data_cpu_rdata(input [2:0] state, input flush, input is_inst_read, input inst_cache_ok, input [31:0] inst_cache_rdata, input data_cpu_ren, input [3:0] data_cpu_wen, input [31:0] dcache_rdata_buf, input data_cache_read_ok, input data_cache_write_ok);
        reg        inst_cpu_stall;
        reg        data_cpu_stall;
        reg [31:0] data_cpu_rdata;
        begin
            case (state)
                state_idle: begin
                    inst_cpu_stall = 1'b1;
                    data_cpu_stall = 1'b1;
                    data_cpu_rdata = 32'b0;
                end
                state_req: begin
                    if (flush) begin
                        inst_cpu_stall = 1'b0;
                        data_cpu_stall = 1'b0;
                        data_cpu_rdata = 32'b0;
                    end else if (((|data_cpu_wen | data_cpu_ren) == 1'b1)) begin
                        inst_cpu_stall = ~inst_cache_ok_i;
                        data_cpu_stall = 1'b1;
                        data_cpu_rdata = dcache_rdata_buf;
                    end else begin
                        inst_cpu_stall = ~inst_cache_ok_i;
                        data_cpu_stall = 1'b0;
                        data_cpu_rdata = 32'b0;
                    end
                end
                state_wait_inst_read: begin
                    inst_cpu_stall = ~inst_cache_ok_i;
                    data_cpu_stall = 1'b0;
                    data_cpu_rdata = 32'b0;
                end
                state_data_read_wait_inst_ok: begin
                    inst_cpu_stall = ~inst_cache_ok_i;
                    data_cpu_stall = 1'b1;
                    data_cpu_rdata = 32'b0;
                end
                state_data_write_wait_inst_ok: begin
                    inst_cpu_stall = ~inst_cache_ok_i;
                    data_cpu_stall = 1'b1;
                    data_cpu_rdata = 32'b0;
                end
                state_wait_data_read: begin
                    if (flush) begin
                        inst_cpu_stall = 1'b0;
                        data_cpu_stall = 1'b0;
                        data_cpu_rdata = 32'b0;
                    end else begin
                        inst_cpu_stall = ~data_cache_read_ok;
                        data_cpu_stall = ~data_cache_read_ok;
                        data_cpu_rdata = 32'b0;
                    end
                end
                state_wait_data_write: begin
                    if (flush) begin
                        inst_cpu_stall = 1'b0;
                        data_cpu_stall = 1'b0;
                        data_cpu_rdata = 32'b0;
                    end else begin
                        inst_cpu_stall = ~data_cache_write_ok;
                        data_cpu_stall = ~data_cache_write_ok;
                        data_cpu_rdata = 32'b0;
                    end
                end
                default: begin
                    inst_cpu_stall = 1'b0;
                    data_cpu_stall = 1'b0;
                    data_cpu_rdata = 32'b0;
                end
            endcase
            inst_cpu_stall_data_cpu_stall_data_cpu_rdata[1+1+32-1] = inst_cpu_stall;
            inst_cpu_stall_data_cpu_stall_data_cpu_rdata[1+32-1]   = data_cpu_stall;
            inst_cpu_stall_data_cpu_stall_data_cpu_rdata[32-1:0]   = data_cpu_rdata;
        end
    endfunction

    assign {inst_cpu_stall_o, data_cpu_stall_o, data_cpu_rdata_o} = inst_cpu_stall_data_cpu_stall_data_cpu_rdata(state, flush_i, is_inst_read_o, inst_cache_ok_i, inst_cache_rdata_i, data_cpu_ren_i, data_cpu_wen_i, dcache_rdata_buf, data_cache_read_ok_i, data_cache_write_ok_i);

    task set_inst_read();
        begin
            data_cache_wen_o <= 4'b0000;
            data_cache_ren_o <= 1'b0;
            is_inst_read_o   <= 1'b1;
            is_data_read_o   <= 1'b0;
            data_cache_ena_o <= 1'b0;
        end
    endtask

    task set_data_read(input [31:0] data_raddr);
        begin
            data_cache_ren_o <= 1'b1;
            data_cache_wen_o <= 4'b0000;
            is_inst_read_o   <= 1'b0;
            is_data_read_o   <= 1'b1;
            data_cache_ena_o <= (data_raddr[31:29] == 3'b101) ? 1'b0 : 1'b1;
        end
    endtask

    task set_data_write(input [3:0] data_wen, input [31:0] data_waddr, input [31:0] data_wdata);
        begin
            data_cache_wen_o   <= data_wen;
            data_cache_ren_o   <= 1'b0;
            is_inst_read_o     <= 1'b0;
            is_data_read_o     <= 1'b1;
            data_cache_ena_o   <= (data_waddr[31:29] == 3'b101) ? 1'b0 : 1'b1;
            data_cache_wdata_o <= data_wdata;
        end
    endtask

    always @(posedge clock_i) begin
        if (reset_i == `RST_ENABLE) begin
            state            <= state_idle;
            dcache_rdata_buf <= 32'b0;
            is_inst_read_o   <= 1'b0;
            is_data_read_o   <= 1'b0;
            data_cache_ena_o <= 1'b0;
            data_wen_r       <= 3'b0;
            data_waddr_r     <= 3'b0;
            data_wdata_r     <= 32'b0;
        end else begin
            case (state)
                state_idle: begin
                    state            <= state_req;
                    data_cache_wen_o <= 4'b0000;
                    data_cache_ren_o <= 1'b0;
                    is_inst_read_o   <= 1'b0;
                    is_data_read_o   <= 1'b0;
                end
                state_req: begin
                    if (data_cpu_ren_i == 1'b1) begin
                        if (inst_cpu_ren_i) begin
                            data_raddr_r <= data_cpu_addr_i;
                            set_inst_read();
                            state <= state_data_read_wait_inst_ok;
                        end else begin
                            if (inst_cache_ok_i) begin
                                set_data_read(data_cpu_addr_i);
                                state <= state_wait_data_read;
                            end else begin
                                data_raddr_r <= data_cpu_addr_i;
                                // set_inst_read();
                                state <= state_data_read_wait_inst_ok;
                            end
                        end

                    end else if (data_cpu_wen_i != 4'b0000) begin
                        if (inst_cpu_ren_i) begin
                            data_wen_r   <= data_cpu_wen_i;
                            data_waddr_r <= data_cpu_addr_i;
                            data_wdata_r <= data_cpu_wdata_i;
                            set_inst_read();
                            state <= state_data_write_wait_inst_ok;
                        end else begin
                            if (inst_cache_ok_i) begin
                                set_data_write(data_cpu_wen_i, data_cpu_addr_i, data_cpu_wdata_i);
                                state <= state_wait_data_write;
                            end else begin
                                data_wen_r   <= data_cpu_wen_i;
                                data_waddr_r <= data_cpu_addr_i;
                                data_wdata_r <= data_cpu_wdata_i;
                                // set_inst_read();
                                state <= state_data_write_wait_inst_ok;
                            end
                        end
                    end else begin
                        if (inst_cpu_ren_i) begin
                            set_inst_read();
                            if (inst_cache_ok_i) begin
                                state <= state_req;
                            end else begin
                                state <= state_wait_inst_read;
                            end
                        end
                    end
                end
                state_wait_inst_read: begin
                    if (data_cpu_ren_i == 1'b1) begin
                        set_inst_read();
                        state <= state_data_read_wait_inst_ok;
                    end else if (data_cpu_wen_i != 4'b0000) begin
                        if (inst_cache_ok_i) begin
                            set_data_write(data_cpu_wen_i, data_cpu_addr_i, data_cpu_wdata_i);
                            state <= state_wait_data_write;
                        end else begin
                            data_wen_r   <= data_cpu_wen_i;
                            data_waddr_r <= data_cpu_addr_i;
                            data_wdata_r <= data_cpu_wdata_i;
                            // set_inst_read();
                            state <= state_data_write_wait_inst_ok;
                        end
                    end else begin
                        // set_inst_read();
                        if (inst_cache_ok_i) begin
                            state <= state_req;
                        end else begin
                            state <= state_wait_inst_read;
                        end
                    end
                end
                state_data_read_wait_inst_ok: begin
                    if ((inst_cache_ok_i === 1'b1)) begin
                        set_data_read(data_raddr_r);
                        state <= state_wait_data_read;
                    end
                end
                state_data_write_wait_inst_ok: begin
                    if ((inst_cache_ok_i === 1'b1)) begin
                        set_data_write(data_wen_r, data_waddr_r, data_wdata_r);
                        state <= state_wait_data_write;
                    end
                end
                state_wait_data_read: begin
                    data_cache_ren_o <= 1'b0;
                    if (data_cache_read_ok_i) begin
                        state            <= state_req;
                        is_inst_read_o   <= 1'b1;
                        is_data_read_o   <= 1'b0;
                        dcache_rdata_buf <= data_cache_rdata_i;
                    end
                    if (flush_i == 1'b1) state <= state_req;
                end
                state_wait_data_write: begin
                    if (data_cache_write_ok_i) begin
                        data_cache_wen_o <= 4'b0000;
                        state            <= state_req;
                        is_inst_read_o   <= 1'b1;
                        is_data_read_o   <= 1'b0;
                    end
                    if (flush_i == 1'b1) state <= state_req;
                end
            endcase
        end
    end
endmodule
