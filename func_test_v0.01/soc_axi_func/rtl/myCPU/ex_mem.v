`include "defines.vh"
module ex_mem(
    input                       rst,
    input                       clk,
    input                       exception,
    input   [3:0]               stall,
    input   [31:0]              exe_pc,
    input   [7:0]               exe_aluop,
    input                       exe_now_in_delayslot,
    input   [31:0]              exe_exception_type,
    input                       exe_regfile_write_enable,
    input                       exe_ram_write_enable,
    input                       exe_hi_write_enable,
    input                       exe_lo_write_enable,
    input                       exe_cp0_write_enable,
    input   [4:0]               exe_regfile_write_addr,
    input   [4:0]               exe_cp0_write_addr,
    input   [31:0]              exe_alu_data,
    input   [31:0]              exe_ram_write_data,
    input   [31:0]              exe_hi_write_data,
    input   [31:0]              exe_lo_write_data,
    input   [31:0]              exe_cp0_write_data,
    input                       exe_mem_to_reg,
    
    output  reg[31:0]           mem_pc,
    output  reg[7:0]            mem_aluop,
    output  reg                 mem_now_in_delayslot,
    output  reg[31:0]           mem_exception_type,
    output  reg                 mem_regfile_write_enable,
    output  reg                 mem_ram_write_enable,
    output  reg                 mem_hi_write_enable,
    output  reg                 mem_lo_write_enable,
    output  reg                 mem_cp0_write_enable,
    output  reg[4:0]            mem_regfile_write_addr,
    output  reg[31:0]           mem_ram_write_addr,
    output  reg[4:0]            mem_cp0_write_addr,
    output  reg[31:0]           mem_alu_data,
    output  reg[31:0]           mem_ram_write_data,
    output  reg[31:0]           mem_hi_write_data,
    output  reg[31:0]           mem_lo_write_data,
    output  reg[31:0]           mem_cp0_write_data,
    output  reg                 mem_mem_to_reg,
    output  reg[31:0]           mem_ram_read_addr
);

wire inst_stall, id_stall, exe_stall, data_stall;
assign inst_stall = stall[0];
assign id_stall = stall[1];
assign exe_stall = stall[2];
assign data_stall = stall[3];

always @ (posedge clk) begin
    if (rst == 1'b0 || exception == 1'b1) begin
        mem_pc <= 32'b0;
        mem_aluop <= 8'h00;
        mem_now_in_delayslot <= 1'b0;
        mem_exception_type <= 32'b0;
        mem_regfile_write_enable <= 1'b0;
        mem_ram_write_enable <= 1'b0;
        mem_hi_write_enable <= 1'b0;
        mem_lo_write_enable <= 1'b0;
        mem_cp0_write_enable <= 1'b0;
        mem_regfile_write_addr <= 5'b0;
        mem_ram_write_addr <= 32'b0;
        mem_cp0_write_addr <= 32'b0;
        mem_alu_data <= 32'b0;
        mem_ram_write_data <= 32'b0;
        mem_hi_write_data <= 32'b0;
        mem_lo_write_data <= 32'b0;
        mem_cp0_write_data <= 32'b0;
        mem_mem_to_reg <= 1'b0;
        mem_ram_read_addr <= 32'b0;
    end 
    else if (exe_stall == 1'b1); 
    else begin
        if (data_stall == 1'b0) begin
            mem_pc <= exe_pc;
            mem_aluop <= exe_aluop;
            mem_now_in_delayslot <= exe_now_in_delayslot;
            mem_exception_type <= exe_exception_type;
            mem_regfile_write_enable <= exe_regfile_write_enable;
            mem_ram_write_enable <= exe_ram_write_enable;
            mem_hi_write_enable <= exe_hi_write_enable;
            mem_lo_write_enable <= exe_lo_write_enable;
            mem_cp0_write_enable <= exe_cp0_write_enable;
            mem_regfile_write_addr <= exe_regfile_write_addr;
            mem_ram_write_addr <= exe_alu_data;
            mem_cp0_write_addr <= exe_cp0_write_addr;
            mem_alu_data <= exe_alu_data;
            mem_ram_write_data <= exe_ram_write_data;
            mem_hi_write_data <= exe_hi_write_data;
            mem_lo_write_data <= exe_lo_write_data;
            mem_cp0_write_data <= exe_cp0_write_data;
            mem_mem_to_reg <= exe_mem_to_reg;
            mem_ram_read_addr <= exe_alu_data;
        end
    end
end
endmodule