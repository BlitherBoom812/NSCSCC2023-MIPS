`include "defines.vh"
module mem_wb(
    input                   clock_i,
    input                   reset_i,
    input                   exception_i,
    input   [3:0]           stall_i,
    input                   mem_regfile_write_enable_i,
    input   [4:0]           mem_regfile_write_addr_i,
    input                   mem_hi_write_enable_i,
    input                   mem_lo_write_enable_i,
    input   [31:0]          mem_hi_write_data_i,
    input   [31:0]          mem_lo_write_data_i,
    input                   mem_cp0_write_enable_i,
    input   [4:0]           mem_cp0_write_addr_i,
    input   [31:0]          mem_cp0_write_data_i,
    input   [31:0]          mem_regfile_write_data_i,
    input   [31:0]          in_wb_pc_i,

    output  reg             wb_regfile_write_enable_o,
    output  reg[4:0]        wb_regfile_write_addr_o,
    output  reg[31:0]       wb_regfile_write_data_o,
    output  reg             wb_hi_write_enable_o,
    output  reg[31:0]       wb_hi_write_data_o,
    output  reg             wb_lo_write_enable_o,
    output  reg[31:0]       wb_lo_write_data_o,
    output  reg             wb_cp0_write_enable_o,
    output  reg[4:0]        wb_cp0_write_addr_o,
    output  reg[31:0]       wb_cp0_write_data_o,
    output  reg[31:0]       wb_pc_o
);

wire inst_stall_i, id_stall_i, exe_stall_i, data_stall_i;
assign inst_stall_i = stall_i[0];
assign id_stall_i = stall_i[1];
assign exe_stall_i = stall_i[2];
assign data_stall_i = stall_i[3];

always @ (posedge clock_i) begin
    if (reset_i == 1'b0 || exception_i == 1'b1) begin
        wb_regfile_write_enable_o <= 1'b0;
        wb_regfile_write_addr_o <= 5'b0;
        wb_regfile_write_data_o <= 32'b0;
        wb_hi_write_enable_o <= 1'b0;
        wb_hi_write_data_o <= 32'b0;
        wb_lo_write_enable_o <= 1'b0;
        wb_lo_write_data_o <= 32'b0;
        wb_cp0_write_enable_o <= 1'b0;
        wb_cp0_write_addr_o <= 5'b0;
        wb_cp0_write_data_o <= 32'b0;
        wb_pc_o <= 32'b0;
    end 
    else if (data_stall_i == 1'b1 || exe_stall_i == 1'b1);
    else begin
        wb_regfile_write_enable_o <= mem_regfile_write_enable_i;
        wb_regfile_write_addr_o <= mem_regfile_write_addr_i;
        wb_regfile_write_data_o <= mem_regfile_write_data_i;
        wb_hi_write_enable_o <= mem_hi_write_enable_i;
        wb_hi_write_data_o <= mem_hi_write_data_i;
        wb_lo_write_enable_o <= mem_lo_write_enable_i;
        wb_lo_write_data_o <= mem_lo_write_data_i;
        wb_cp0_write_enable_o <= mem_cp0_write_enable_i;
        wb_cp0_write_addr_o <= mem_cp0_write_addr_i;
        wb_cp0_write_data_o <= mem_cp0_write_data_i;
        wb_pc_o <= in_wb_pc_i;
    end
end
endmodule