`include "defines.vh"
module mem_wb(
    input                   clk,
    input                   rst,
    input                   exception,
    input   [3:0]           stall,
    input                   mem_regfile_write_enable,
    input   [4:0]           mem_regfile_write_addr,
    input                   mem_hi_write_enable,
    input                   mem_lo_write_enable,
    input   [31:0]          mem_hi_write_data,
    input   [31:0]          mem_lo_write_data,
    input                   mem_cp0_write_enable,
    input   [4:0]           mem_cp0_write_addr,
    input   [31:0]          mem_cp0_write_data,
    input   [31:0]          mem_regfile_write_data,
    input   [31:0]          in_wb_pc,

    output  reg             wb_regfile_write_enable,
    output  reg[4:0]        wb_regfile_write_addr,
    output  reg[31:0]       wb_regfile_write_data,
    output  reg             wb_hi_write_enable,
    output  reg[31:0]       wb_hi_write_data,
    output  reg             wb_lo_write_enable,
    output  reg[31:0]       wb_lo_write_data,
    output  reg             wb_cp0_write_enable,
    output  reg[4:0]        wb_cp0_write_addr,
    output  reg[31:0]       wb_cp0_write_data,
    output  reg[31:0]       wb_pc
);

wire inst_stall, id_stall, exe_stall, data_stall;
assign inst_stall = stall[0];
assign id_stall = stall[1];
assign exe_stall = stall[2];
assign data_stall = stall[3];

always @ (posedge clk) begin
    if (rst == 1'b0 || exception == 1'b1) begin
        wb_regfile_write_enable <= 1'b0;
        wb_regfile_write_addr <= 5'b0;
        wb_regfile_write_data <= 32'b0;
        wb_hi_write_enable <= 1'b0;
        wb_hi_write_data <= 32'b0;
        wb_lo_write_enable <= 1'b0;
        wb_lo_write_data <= 32'b0;
        wb_cp0_write_enable <= 1'b0;
        wb_cp0_write_addr <= 5'b0;
        wb_cp0_write_data <= 32'b0;
        wb_pc <= 32'b0;
    end 
    else if (data_stall == 1'b1 || exe_stall == 1'b1);
    else begin
        wb_regfile_write_enable <= mem_regfile_write_enable;
        wb_regfile_write_addr <= mem_regfile_write_addr;
        wb_regfile_write_data <= mem_regfile_write_data;
        wb_hi_write_enable <= mem_hi_write_enable;
        wb_hi_write_data <= mem_hi_write_data;
        wb_lo_write_enable <= mem_lo_write_enable;
        wb_lo_write_data <= mem_lo_write_data;
        wb_cp0_write_enable <= mem_cp0_write_enable;
        wb_cp0_write_addr <= mem_cp0_write_addr;
        wb_cp0_write_data <= mem_cp0_write_data;
        wb_pc <= in_wb_pc;
    end
end
endmodule