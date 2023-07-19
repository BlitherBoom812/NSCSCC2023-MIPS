`include "defines.vh"
module id_ex(
    input                       rst,
    input                       clk,
    input                       exception,
    input   [3:0]               stall, 
    input   [31:0]              id_pc,
    input   [31:0]              id_rs_data,
    input   [31:0]              id_rt_data,
    input   [31:0]              id_instr,
    input   [7:0]               id_aluop,
    input   [4:0]               id_regfile_write_addr,
    input                       id_now_in_delayslot,
    input                       id_next_in_delayslot,
    input                       id_regfile_write_enable,
    input                       id_ram_write_enable,
    input                       id_hi_write_enable,
    input                       id_lo_write_enable,
    input                       id_cp0_write_enable,
    input                       id_mem_to_reg,
    input   [31:0]              id_pc_return_addr,
    input   [31:0]              id_hilo_data,
    input   [31:0]              id_cp0_data,
    input   [15:0]              id_imm16,
    input   [31:0]              id_exception_type,
    input                       id_hilo_read_addr,
    input   [4:0]               id_cp0_read_addr,
    
    output  reg[31:0]           ex_pc,
    output  reg[31:0]           ex_rs_data,
    output  reg[31:0]           ex_rt_data,
    output  reg[31:0]           ex_instr,
    output  reg[7:0]            ex_aluop,
    output  reg[4:0]            ex_regfile_write_addr,
    output  reg                 ex_now_in_delayslot,
    output  reg                 ex_regfile_write_enable,
    output  reg                 ex_ram_write_enable,
    output  reg                 ex_hi_write_enable,
    output  reg                 ex_lo_write_enable,
    output  reg                 ex_cp0_write_enable,
    output  reg[31:0]           ex_hilo_data,
    output  reg[31:0]           ex_cp0_data,
    output  reg                 ex_mem_to_reg,
    output  reg[31:0]           ex_pc_return_addr,
    output  reg[31:0]           ex_sign_extend_imm16,
    output  reg[31:0]           ex_zero_extend_imm16,
    output  reg[31:0]           ex_load_upper_imm16,
    output  reg                 ex_hilo_read_addr,
    output  reg[4:0]            ex_cp0_read_addr,
    output  reg                 ex_id_now_in_delayslot,
    output  reg [31:0]          ex_exception_type
);

wire inst_stall, id_stall, exe_stall, data_stall;
assign inst_stall = stall[0];
assign id_stall = stall[1];
assign exe_stall = stall[2];
assign data_stall = stall[3];

always @ (posedge clk) begin
    if (rst == 1'b0 || exception == 1'b1) begin
        ex_pc <= 32'b0;
        ex_rs_data <= 32'b0;
        ex_rt_data <= 32'b0;
        ex_instr <= 32'b0;
        ex_aluop <= 8'h00;
        ex_regfile_write_addr <= 5'b00000;
        ex_now_in_delayslot <= 1'b0;
        ex_exception_type <= 32'b0;
        ex_regfile_write_enable <= 1'b0;
        ex_ram_write_enable <= 1'b0;
        ex_hi_write_enable <= 1'b0;
        ex_lo_write_enable <= 1'b0;
        ex_cp0_write_enable <= 1'b0;
        ex_hilo_data <= 32'b0;
        ex_cp0_data <= 32'b0;
        ex_mem_to_reg <= 1'b0;
        ex_pc_return_addr <= 32'b0;
        ex_sign_extend_imm16 <= 32'b0;
        ex_zero_extend_imm16 <= 32'b0;
        ex_load_upper_imm16 <= 32'b0;
        ex_hilo_read_addr <= 1'b0;
        ex_cp0_read_addr <= 5'b00000;
        ex_id_now_in_delayslot <= 1'b0;
        ex_exception_type <= 6'h0;
    end 
    else if (exe_stall == 1'b1 || data_stall == 1'b1); 
    else if (inst_stall == 1'b1 || id_stall == 1'b1) begin
        ex_pc <= 32'b0;
        ex_rs_data <= 32'b0;
        ex_rt_data <= 32'b0;
        ex_instr <= 32'b0;
        ex_aluop <= 8'h00;
        ex_regfile_write_addr <= 5'b00000;
        ex_now_in_delayslot <= 1'b0;
        ex_exception_type <= 32'b0;
        ex_regfile_write_enable <= 1'b0;
        ex_ram_write_enable <= 1'b0;
        ex_hi_write_enable <= 1'b0;
        ex_lo_write_enable <= 1'b0;
        ex_cp0_write_enable <= 1'b0;
        ex_hilo_data <= 32'b0;
        ex_cp0_data <= 32'b0;
        ex_mem_to_reg <= 1'b0;
        ex_pc_return_addr <= 32'b0;
        ex_sign_extend_imm16 <= 32'b0;
        ex_zero_extend_imm16 <= 32'b0;
        ex_load_upper_imm16 <= 32'b0;
        ex_hilo_read_addr <= 1'b0;
        ex_cp0_read_addr <= 5'b00000;
        ex_id_now_in_delayslot <= ex_id_now_in_delayslot; 
        ex_exception_type <= 6'h0;
    end 
    else begin
        ex_pc <= id_pc;
        ex_rs_data <= id_rs_data;
        ex_rt_data <= id_rt_data;
        ex_instr <= id_instr;
        ex_aluop <= id_aluop;
        ex_regfile_write_addr <= id_regfile_write_addr;
        ex_now_in_delayslot <= id_now_in_delayslot;
        ex_exception_type <= id_exception_type;
        ex_regfile_write_enable <= id_regfile_write_enable;
        ex_ram_write_enable <= id_ram_write_enable;
        ex_hi_write_enable <= id_hi_write_enable;
        ex_lo_write_enable <= id_lo_write_enable;
        ex_cp0_write_enable <= id_cp0_write_enable;
        ex_hilo_data <= id_hilo_data;
        ex_cp0_data <= id_cp0_data;
        ex_mem_to_reg <= id_mem_to_reg;
        ex_pc_return_addr <= id_pc_return_addr;
        ex_sign_extend_imm16 <= {{16{id_imm16[15]}}, id_imm16};
        ex_zero_extend_imm16 <= {16'h0000, id_imm16};
        ex_load_upper_imm16 <= {id_imm16, 16'h0000};
        ex_hilo_read_addr <= id_hilo_read_addr;
        ex_cp0_read_addr <= id_cp0_read_addr;
        ex_id_now_in_delayslot <= id_next_in_delayslot;
        ex_exception_type <= id_exception_type;
    end
end
endmodule