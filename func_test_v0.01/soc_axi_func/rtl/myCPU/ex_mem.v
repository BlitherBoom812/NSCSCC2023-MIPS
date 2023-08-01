`include "defines.vh"
module ex_mem (
    input        reset_i,
    input        clock_i,
    input        exception_i,
    input [ 3:0] stall_i,
    input [31:0] exe_pc_i,
    input [ 7:0] exe_aluop_i,
    input        exe_now_in_delayslot_i,
    input [31:0] exe_exception_type_i,
    input        exe_regfile_write_enable_i,
    input        exe_ram_write_enable_i,
    input        exe_hi_write_enable_i,
    input        exe_lo_write_enable_i,
    input        exe_cp0_write_enable_i,
    input [ 4:0] exe_regfile_write_addr_i,
    input [ 4:0] exe_cp0_write_addr_i,
    input [31:0] exe_alu_data_i,
    input [31:0] exe_ram_write_data_i,
    input [31:0] exe_hi_write_data_i,
    input [31:0] exe_lo_write_data_i,
    input [31:0] exe_cp0_write_data_i,
    input        exe_mem_to_reg_i,

    output reg [31:0] mem_pc_o,
    output reg [ 7:0] mem_aluop_o,
    output reg        mem_now_in_delayslot_o,
    output reg [31:0] mem_exception_type_o,
    output reg        mem_regfile_write_enable_o,
    output reg        mem_ram_write_enable_o,
    output reg        mem_hi_write_enable_o,
    output reg        mem_lo_write_enable_o,
    output reg        mem_cp0_write_enable_o,
    output reg [ 4:0] mem_regfile_write_addr_o,
    output reg [31:0] mem_ram_write_addr_o,
    output reg [ 4:0] mem_cp0_write_addr_o,
    output reg [31:0] mem_alu_data_o,
    output reg [31:0] mem_ram_write_data_o,
    output reg [31:0] mem_hi_write_data_o,
    output reg [31:0] mem_lo_write_data_o,
    output reg [31:0] mem_cp0_write_data_o,
    output reg        mem_mem_to_reg_o,
    output reg [31:0] mem_ram_read_addr_o
);

    wire inst_stall, id_stall, exe_stall, data_stall;
    assign inst_stall = stall_i[0];
    assign id_stall   = stall_i[1];
    assign exe_stall  = stall_i[2];
    assign data_stall = stall_i[3];

    always @(posedge clock_i) begin
        if (reset_i == 1'b0 || exception_i == 1'b1) begin
            mem_pc_o                   <= 32'b0;
            mem_aluop_o                <= 8'h00;
            mem_now_in_delayslot_o     <= 1'b0;
            mem_exception_type_o       <= 32'b0;
            mem_regfile_write_enable_o <= 1'b0;
            mem_ram_write_enable_o     <= 1'b0;
            mem_hi_write_enable_o      <= 1'b0;
            mem_lo_write_enable_o      <= 1'b0;
            mem_cp0_write_enable_o     <= 1'b0;
            mem_regfile_write_addr_o   <= 5'b0;
            mem_ram_write_addr_o       <= 32'b0;
            mem_cp0_write_addr_o       <= 32'b0;
            mem_alu_data_o             <= 32'b0;
            mem_ram_write_data_o       <= 32'b0;
            mem_hi_write_data_o        <= 32'b0;
            mem_lo_write_data_o        <= 32'b0;
            mem_cp0_write_data_o       <= 32'b0;
            mem_mem_to_reg_o           <= 1'b0;
            mem_ram_read_addr_o        <= 32'b0;
        end else
        if (exe_stall == 1'b1);
        else begin
            if (data_stall == 1'b0) begin
                mem_pc_o                   <= exe_pc_i;
                mem_aluop_o                <= exe_aluop_i;
                mem_now_in_delayslot_o     <= exe_now_in_delayslot_i;
                mem_exception_type_o       <= exe_exception_type_i;
                mem_regfile_write_enable_o <= exe_regfile_write_enable_i;
                mem_ram_write_enable_o     <= exe_ram_write_enable_i;
                mem_hi_write_enable_o      <= exe_hi_write_enable_i;
                mem_lo_write_enable_o      <= exe_lo_write_enable_i;
                mem_cp0_write_enable_o     <= exe_cp0_write_enable_i;
                mem_regfile_write_addr_o   <= exe_regfile_write_addr_i;
                mem_ram_write_addr_o       <= exe_alu_data_i;
                mem_cp0_write_addr_o       <= exe_cp0_write_addr_i;
                mem_alu_data_o             <= exe_alu_data_i;
                mem_ram_write_data_o       <= exe_ram_write_data_i;
                mem_hi_write_data_o        <= exe_hi_write_data_i;
                mem_lo_write_data_o        <= exe_lo_write_data_i;
                mem_cp0_write_data_o       <= exe_cp0_write_data_i;
                mem_mem_to_reg_o           <= exe_mem_to_reg_i;
                mem_ram_read_addr_o        <= exe_alu_data_i;
            end
        end
    end
endmodule
