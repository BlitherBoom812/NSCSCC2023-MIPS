`include "defines.vh"
module id_ex(
    input                       reset_i,
    input                       clock_i,
    input                       exception_i,
    input   [3:0]               stall_i, 
    input   [31:0]              id_pc_i,
    input   [31:0]              id_rs_data_i,
    input   [31:0]              id_rt_data_i,
    input   [31:0]              id_inst_i,
    input   [7:0]               id_aluop_i,
    input   [4:0]               id_regfile_write_addr_i,
    input                       id_now_in_delayslot_i,
    input                       id_next_in_delayslot_i,
    input                       id_regfile_write_enable_i,
    input                       id_ram_write_enable_i,
    input                       id_hi_write_enable_i,
    input                       id_lo_write_enable_i,
    input                       id_cp0_write_enable_i,
    input                       id_mem_to_reg_i,
    input   [31:0]              id_pc_return_addr_i,
    input   [31:0]              id_hilo_data_i,
    input   [31:0]              id_cp0_data_i,
    input   [15:0]              id_imm16_i,
    input   [31:0]              id_exception_type_i,
    input                       id_hilo_read_addr_i,
    input   [4:0]               id_cp0_read_addr_i,
    
    output  reg [31:0]          ex_pc_o,
    output  reg [31:0]          ex_rs_data_o,
    output  reg [31:0]          ex_rt_data_o,
    output  reg [31:0]          ex_inst_o,
    output  reg [7:0]           ex_aluop_o,
    output  reg [4:0]           ex_regfile_write_addr_o,
    output  reg                 ex_now_in_delayslot_o,
    output  reg                 ex_regfile_write_enable_o,
    output  reg                 ex_ram_write_enable_o,
    output  reg                 ex_hi_write_enable_o,
    output  reg                 ex_lo_write_enable_o,
    output  reg                 ex_cp0_write_enable_o,
    output  reg [31:0]          ex_hilo_data_o,
    output  reg [31:0]          ex_cp0_data_o,
    output  reg                 ex_mem_to_reg_o,
    output  reg [31:0]          ex_pc_return_addr_o,
    output  reg [31:0]          ex_sign_extend_imm16_o,
    output  reg [31:0]          ex_zero_extend_imm16_o,
    output  reg [31:0]          ex_load_upper_imm16_o,
    output  reg                 ex_hilo_read_addr_o,
    output  reg [4:0]           ex_cp0_read_addr_o,
    output  reg                 ex_id_now_in_delayslot_o,
    output  reg [31:0]          ex_exception_type_o
);

wire inst_stall, id_stall, exe_stall, data_stall;
assign inst_stall = stall_i[0];
assign id_stall = stall_i[1];
assign exe_stall = stall_i[2];
assign data_stall = stall_i[3];

always @ (posedge clock_i) begin
    if (reset_i == 1'b0 || exception_i == 1'b1) begin
        ex_pc_o <= 32'b0;
        ex_rs_data_o <= 32'b0;
        ex_rt_data_o <= 32'b0;
        ex_inst_o <= 32'b0;
        ex_aluop_o <= 8'h00;
        ex_regfile_write_addr_o <= 5'b00000;
        ex_now_in_delayslot_o <= 1'b0;
        ex_exception_type_o <= 32'b0;
        ex_regfile_write_enable_o <= 1'b0;
        ex_ram_write_enable_o <= 1'b0;
        ex_hi_write_enable_o <= 1'b0;
        ex_lo_write_enable_o <= 1'b0;
        ex_cp0_write_enable_o <= 1'b0;
        ex_hilo_data_o <= 32'b0;
        ex_cp0_data_o <= 32'b0;
        ex_mem_to_reg_o <= 1'b0;
        ex_pc_return_addr_o <= 32'b0;
        ex_sign_extend_imm16_o <= 32'b0;
        ex_zero_extend_imm16_o <= 32'b0;
        ex_load_upper_imm16_o <= 32'b0;
        ex_hilo_read_addr_o <= 1'b0;
        ex_cp0_read_addr_o <= 5'b00000;
        ex_id_now_in_delayslot_o <= 1'b0;
        ex_exception_type_o <= 6'h0;
    end 
    else if (exe_stall == 1'b1 || data_stall == 1'b1); 
    else if (id_stall == 1'b1) begin
        ex_pc_o <= 32'b0;
        ex_rs_data_o <= 32'b0;
        ex_rt_data_o <= 32'b0;
        ex_inst_o <= 32'b0;
        ex_aluop_o <= 8'h00;
        ex_regfile_write_addr_o <= 5'b00000;
        ex_now_in_delayslot_o <= 1'b0;
        ex_exception_type_o <= 32'b0;
        ex_regfile_write_enable_o <= 1'b0;
        ex_ram_write_enable_o <= 1'b0;
        ex_hi_write_enable_o <= 1'b0;
        ex_lo_write_enable_o <= 1'b0;
        ex_cp0_write_enable_o <= 1'b0;
        ex_hilo_data_o <= 32'b0;
        ex_cp0_data_o <= 32'b0;
        ex_mem_to_reg_o <= 1'b0;
        ex_pc_return_addr_o <= 32'b0;
        ex_sign_extend_imm16_o <= 32'b0;
        ex_zero_extend_imm16_o <= 32'b0;
        ex_load_upper_imm16_o <= 32'b0;
        ex_hilo_read_addr_o <= 1'b0;
        ex_cp0_read_addr_o <= 5'b00000;
        ex_id_now_in_delayslot_o <= ex_id_now_in_delayslot_o; 
        ex_exception_type_o <= 6'h0;
    end 
    else begin
        ex_pc_o <= id_pc_i;
        ex_rs_data_o <= id_rs_data_i;
        ex_rt_data_o <= id_rt_data_i;
        ex_inst_o <= id_inst_i;
        ex_aluop_o <= id_aluop_i;
        ex_regfile_write_addr_o <= id_regfile_write_addr_i;
        ex_now_in_delayslot_o <= id_now_in_delayslot_i;
        ex_exception_type_o <= id_exception_type_i;
        ex_regfile_write_enable_o <= id_regfile_write_enable_i;
        ex_ram_write_enable_o <= id_ram_write_enable_i;
        ex_hi_write_enable_o <= id_hi_write_enable_i;
        ex_lo_write_enable_o <= id_lo_write_enable_i;
        ex_cp0_write_enable_o <= id_cp0_write_enable_i;
        ex_hilo_data_o <= id_hilo_data_i;
        ex_cp0_data_o <= id_cp0_data_i;
        ex_mem_to_reg_o <= id_mem_to_reg_i;
        ex_pc_return_addr_o <= id_pc_return_addr_i;
        ex_sign_extend_imm16_o <= {{16{id_imm16_i[15]}}, id_imm16_i};
        ex_zero_extend_imm16_o <= {16'h0000, id_imm16_i};
        ex_load_upper_imm16_o <= {id_imm16_i, 16'h0000};
        ex_hilo_read_addr_o <= id_hilo_read_addr_i;
        ex_cp0_read_addr_o <= id_cp0_read_addr_i;
        ex_id_now_in_delayslot_o <= id_next_in_delayslot_i;
        ex_exception_type_o <= id_exception_type_i;
    end
end
endmodule