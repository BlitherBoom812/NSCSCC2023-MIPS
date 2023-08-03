`include "defines.vh"
module mem (
    input        reset_i,
    input [31:0] pc_i,
    input [ 7:0] aluop_i,
    input        data_stall_i,
    input        now_in_delayslot_i,
    input [31:0] exception_type_i,
    input        regfile_write_enable_i,
    input        ram_write_enable_i,
    input        hi_write_enable_i,
    input        lo_write_enable_i,
    input        cp0_write_enable_i,
    input [ 4:0] regfile_write_addr_i,
    input [31:0] ram_write_addr_i,
    input [ 4:0] cp0_write_addr_i,
    input [31:0] alu_data_i,
    input [31:0] ram_write_data_i,
    input [31:0] hi_write_data_i,
    input [31:0] lo_write_data_i,
    input [31:0] cp0_write_data_i,
    input        mem_to_reg_i,
    input [31:0] ram_read_addr_i,
    input [31:0] ram_read_data_i,

    output wire        mem_stall_request_o,
    output reg  [31:0] store_pc_o,
    output reg  [31:0] access_mem_addr_o,
    output reg         now_in_delayslot_o,
    output reg  [31:0] exception_type_o,
    output             regfile_write_enable_o,
    output      [ 4:0] regfile_write_addr_o,
    output             hi_write_enable_o,
    output      [31:0] hi_write_data_o,
    output             lo_write_enable_o,
    output      [31:0] lo_write_data_o,
    output             cp0_write_enable_o,
    output      [ 4:0] cp0_write_addr_o,
    output      [31:0] cp0_write_data_o,
    output      [31:0] regfile_write_data_o,
    output reg  [ 3:0] ram_write_select_o,
    output reg         ram_write_enable_o,
    output reg  [31:0] ram_write_addr_o,
    output reg  [31:0] ram_write_data_o,
    output reg  [31:0] ram_read_addr_o,
    output reg         ram_read_enable_o
);

    reg is_read_bad_addr, is_write_bad_addr;
    reg [31:0] ram_data_o;

    assign regfile_write_enable_o = (reset_i == 1'b0) ? 32'h0 : ((exception_type_i != 32'h0) ? 1'b0 : regfile_write_enable_i);
    assign regfile_write_addr_o   = (reset_i == 1'b0) ? 5'b0 : regfile_write_addr_i;
    assign hi_write_enable_o      = (reset_i == 1'b0) ? 1'b0 : hi_write_enable_i;
    assign hi_write_data_o        = (reset_i == 1'b0) ? 32'b0 : hi_write_data_i;
    assign lo_write_enable_o      = (reset_i == 1'b0) ? 1'b0 : lo_write_enable_i;
    assign lo_write_data_o        = (reset_i == 1'b0) ? 32'b0 : lo_write_data_i;
    assign cp0_write_enable_o     = (reset_i == 1'b0) ? 1'b0 : cp0_write_enable_i;
    assign cp0_write_addr_o       = (reset_i == 1'b0) ? 5'b0 : cp0_write_addr_i;
    assign cp0_write_data_o       = (reset_i == 1'b0) ? 32'b0 : cp0_write_data_i;
    assign regfile_write_data_o   = (reset_i == 1'b0) ? 32'b0 : (mem_to_reg_i == 1'b1) ? ram_data_o : alu_data_i;

    always @(*) begin
        if (reset_i == 1'b0) begin
            ram_read_addr_o   <= 32'b0;
            ram_data_o        <= 32'b0;
            is_read_bad_addr  <= 1'b0;
            ram_read_enable_o <= 1'b0;
        end else begin
            ram_read_addr_o <= {ram_read_addr_i[31:2], 2'b00};
            case (aluop_i)
                `ALUOP_LB: begin
                    is_read_bad_addr  <= 1'b0;
                    ram_read_enable_o <= 1'b1;
                    case (ram_read_addr_i[1:0])
                        2'b00:   ram_data_o <= {{24{ram_read_data_i[7]}}, ram_read_data_i[7:0]};
                        2'b01:   ram_data_o <= {{24{ram_read_data_i[15]}}, ram_read_data_i[15:8]};
                        2'b10:   ram_data_o <= {{24{ram_read_data_i[23]}}, ram_read_data_i[23:16]};
                        2'b11:   ram_data_o <= {{24{ram_read_data_i[31]}}, ram_read_data_i[31:24]};
                        default: ram_data_o <= 32'b0;
                    endcase
                end
                `ALUOP_LBU: begin
                    is_read_bad_addr  <= 1'b0;
                    ram_read_enable_o <= 1'b1;
                    case (ram_read_addr_i[1:0])
                        2'b00:   ram_data_o <= {{24'h000000}, ram_read_data_i[7:0]};
                        2'b01:   ram_data_o <= {{24'h000000}, ram_read_data_i[15:8]};
                        2'b10:   ram_data_o <= {{24'h000000}, ram_read_data_i[23:16]};
                        2'b11:   ram_data_o <= {{24'h000000}, ram_read_data_i[31:24]};
                        default: ram_data_o <= 32'b0;
                    endcase
                end
                `ALUOP_LH: begin
                    is_read_bad_addr  <= (ram_read_addr_i[0] == 1'b0) ? 1'b0 : 1'b1;
                    ram_read_enable_o <= 1'b1;
                    case (ram_read_addr_i[1:0])
                        2'b00:   ram_data_o <= {{16{ram_read_data_i[15]}}, ram_read_data_i[15:0]};
                        2'b10:   ram_data_o <= {{16{ram_read_data_i[31]}}, ram_read_data_i[31:16]};
                        default: ram_data_o <= 32'b0;
                    endcase
                end
                `ALUOP_LHU: begin
                    is_read_bad_addr  <= (ram_read_addr_i[0] == 1'b0) ? 1'b0 : 1'b1;
                    ram_read_enable_o <= 1'b1;
                    case (ram_read_addr_i[1:0])
                        2'b00:   ram_data_o <= {{16'h0000}, ram_read_data_i[15:0]};
                        2'b10:   ram_data_o <= {{16'h0000}, ram_read_data_i[31:16]};
                        default: ram_data_o <= 32'b0;
                    endcase
                end
                `ALUOP_LW: begin
                    is_read_bad_addr  <= (ram_read_addr_i[1:0] == 2'b00) ? 1'b0 : 1'b1;
                    ram_read_enable_o <= 1'b1;
                    ram_data_o        <= ram_read_data_i;
                end
                default: begin
                    is_read_bad_addr  <= 1'b0;
                    ram_data_o        <= 32'b0;
                    ram_read_enable_o <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        if (reset_i == 1'b0) begin
            ram_write_select_o <= 4'b0000;
            ram_write_enable_o <= 1'b0;
            ram_write_addr_o   <= 32'b0;
            ram_write_data_o   <= 32'b0;
            is_write_bad_addr  <= 1'b0;
        end else begin
            ram_write_addr_o   <= {ram_write_addr_i[31:2], 2'b00};
            ram_write_enable_o <= (is_write_bad_addr == 1'b1) ? 1'b0 : ram_write_enable_i;
            case (aluop_i)
                `ALUOP_SB: begin
                    is_write_bad_addr <= 1'b0;
                    ram_write_data_o  <= {ram_write_data_i[7:0], ram_write_data_i[7:0], ram_write_data_i[7:0], ram_write_data_i[7:0]};
                    case (ram_write_addr_i[1:0])
                        2'b00:   ram_write_select_o <= 4'b0001;
                        2'b01:   ram_write_select_o <= 4'b0010;
                        2'b10:   ram_write_select_o <= 4'b0100;
                        2'b11:   ram_write_select_o <= 4'b1000;
                        default: ram_write_select_o <= 4'b0000;
                    endcase
                end
                `ALUOP_SH: begin
                    is_write_bad_addr <= (ram_write_addr_i[0] == 1'b0) ? 1'b0 : 1'b1;
                    ram_write_data_o  <= {ram_write_data_i[15:0], ram_write_data_i[15:0]};
                    case (ram_write_addr_i[1:0])
                        2'b00:   ram_write_select_o <= 4'b0011;
                        2'b10:   ram_write_select_o <= 4'b1100;
                        default: ram_write_select_o <= 4'b0000;
                    endcase
                end
                `ALUOP_SW: begin
                    is_write_bad_addr  <= (ram_write_addr_i[1:0] == 2'b00) ? 1'b0 : 1'b1;
                    ram_write_data_o   <= ram_write_data_i;
                    ram_write_select_o <= 4'b1111;
                end
                default: begin
                    ram_write_data_o   <= ram_write_data_i;
                    ram_write_select_o <= 4'b0000;
                    is_write_bad_addr  <= 1'b0;
                end
            endcase
        end
    end

    assign mem_stall_request_o = data_stall_i;

    always @(*) begin
        if (reset_i == 1'b0) begin
            store_pc_o         <= 32'b0;
            access_mem_addr_o  <= 32'b0;
            now_in_delayslot_o <= 1'b0;
            exception_type_o   <= 32'b0;
        end else begin
            store_pc_o         <= pc_i;
            now_in_delayslot_o <= now_in_delayslot_i;
            case (aluop_i)
                `ALUOP_LB, `ALUOP_LH, `ALUOP_LBU, `ALUOP_LHU, `ALUOP_LW: begin
                    access_mem_addr_o <= ram_read_addr_i;
                    exception_type_o  <= {exception_type_i[31:27], is_read_bad_addr, exception_type_i[25:0]};
                end
                `ALUOP_SB, `ALUOP_SH, `ALUOP_SW: begin
                    access_mem_addr_o <= ram_write_addr_i;
                    exception_type_o  <= {exception_type_i[31:26], is_write_bad_addr, exception_type_i[24:0]};
                end
                default: begin
                    access_mem_addr_o <= 32'b0;
                    exception_type_o  <= exception_type_i;
                end
            endcase
        end
    end
endmodule
