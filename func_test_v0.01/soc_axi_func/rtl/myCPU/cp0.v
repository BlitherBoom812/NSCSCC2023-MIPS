`include "defines.vh"
module cp0 (
    input        clock_i,
    input        reset_i,
    input [ 4:0] cp0_read_addr_i,
    input        cp0_write_enable_i,
    input [ 4:0] cp0_write_addr_i,
    input [31:0] cp0_write_data_i,
    input [31:0] exception_type_i,
    input [31:0] pc_i,
    input [31:0] exception_addr_i,
    input [ 5:0] int_i,
    input        now_in_delayslot_i,

    output reg [31:0] cp0_read_data_o,
    output reg [31:0] cp0_return_pc_o,
    output reg        timer_int_o,
    output reg        flush_o
);

    reg [31:0] cp0_badvaddr;
    reg [31:0] cp0_count;
    reg [31:0] cp0_compare;
    reg [31:0] cp0_status;
    reg [31:0] cp0_cause;
    reg [31:0] cp0_epc;

    reg        is_int;
    reg        timer_int;
    reg        flush;
    reg [31:0] cp0_return_pc;
    reg        exception_flag;

    always @(*) begin
        if (cp0_write_enable_i && cp0_read_addr_i == cp0_write_addr_i) begin
            if (cp0_write_addr_i == 5'd13)  // cp0_cause
                cp0_read_data_o = {cp0_cause[31:10], cp0_write_data_i[9:8], cp0_cause[7:0]};
            else if (cp0_write_addr_i == 5'd12)  //cp0_status
                cp0_read_data_o = {cp0_status[31:16], cp0_write_data_i[15:8], cp0_status[7:2], cp0_write_data_i[1:0]};
            else cp0_read_data_o = cp0_write_data_i;
        end else begin
            case (cp0_read_addr_i)
                5'd8:  //badVaddr
                cp0_read_data_o = cp0_badvaddr;
                5'd9:  //count:
                cp0_read_data_o = cp0_count;
                5'd11:  //compare
                cp0_read_data_o = cp0_compare;
                5'd12:  //status:
                cp0_read_data_o = cp0_status;
                5'd13:  //cause:
                cp0_read_data_o = cp0_cause;
                5'd14:  //epc:
                cp0_read_data_o = cp0_epc;
                default: cp0_read_data_o = 32'h0;
            endcase
        end
    end

    always @(posedge clock_i) begin
        if (reset_i == 1'b0) begin
            flush          <= 1'b0;
            timer_int      <= 1'b0;
            exception_flag <= 1'b0;
            cp0_return_pc  <= 32'b0;
            cp0_badvaddr   <= 32'b0;
            cp0_count      <= 32'b0;
            cp0_compare    <= 32'b0;
            cp0_status     <= 32'b00000000010000000000000000000000;
            cp0_cause      <= 32'b0;
            cp0_epc        <= 32'b0;
            cp0_read_data_o <= 32'b0;
            cp0_return_pc_o <= 32'b0;
            timer_int_o <= 1'b0;
            flush_o        <= 1'b0;
        end else begin
            exception_flag = (flush == 1'b1) ? 1 : 0;
            ;
            if (exception_flag) flush = 0;
            cp0_count = cp0_count + 1;
            if (cp0_compare != 32'b0 && cp0_compare == cp0_count) begin
                timer_int = 1;
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'h0000_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_INT;
            end else timer_int = 0;
            if (exception_type_i[31] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_ADEL;
                cp0_badvaddr     = pc_i;
            end else if (exception_type_i[30] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_RI;
            end else if (exception_type_i[29] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_OV;
            end else if (exception_type_i[28] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_BP;
            end else if (exception_type_i[27] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_SYS;
            end else if (exception_type_i[26] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_ADEL;
                cp0_badvaddr     = exception_addr_i;
            end else if (exception_type_i[25] == 1'b1) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i - 4;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_ADES;
                cp0_badvaddr     = exception_addr_i;
            end else if (exception_type_i[0] == 1'b1) begin
                cp0_status[`EXL] = 0;
                cp0_return_pc    = cp0_epc;
                flush            = 1'b1;
            end
            if (cp0_write_enable_i)
                case (cp0_write_addr_i)
                    5'd9:  cp0_count = cp0_write_data_i;  //count
                    5'd11: cp0_compare = cp0_write_data_i;  //compare
                    5'd12://status
                begin
                        cp0_status[15:8] = cp0_write_data_i[15:8];
                        cp0_status[1:0]  = cp0_write_data_i[1:0];
                    end
                    5'd13: cp0_cause[9:8] = cp0_write_data_i[9:8];
                    5'd14: cp0_epc = cp0_write_data_i;
                endcase
            if (cp0_cause[15:8] & cp0_status[15:8]) begin
                if (cp0_status[`EXL] == 0) begin
                    if (now_in_delayslot_i == 1'b1) begin
                        cp0_epc        = pc_i;
                        cp0_cause[`BD] = 1;
                    end else begin
                        cp0_epc        = pc_i + 4;
                        cp0_cause[`BD] = 0;
                    end
                    flush = 1'b1;
                end else flush = 1'b0;
                cp0_status[`EXL] = 1;
                cp0_return_pc    = 32'hbfc0_0380;
                cp0_cause[6:2]   = `EXCEP_CODE_INT;
            end
            cp0_return_pc_o <= cp0_return_pc;
            timer_int_o     <= timer_int;
            flush_o         <= flush;
        end
    end
endmodule
