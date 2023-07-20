`include "defines.vh"
module ex(
    input                       rst,
    input                       clk,
    input   [31:0]              pc_i,
    input   [31:0]              rs_data_i,
    input   [31:0]              rt_data_i,
    input   [31:0]              instr_i,
    input   [7:0]               aluop_i,
    input   [4:0]               regfile_write_addr_i,
    input                       now_in_delayslot_i,
    input   [31:0]              exception_type_i,
    input                       regfile_write_enable_i,
    input                       ram_write_enable_i,
    input                       hi_write_enable_i,
    input                       lo_write_enable_i,
    input                       cp0_write_enable_i,
    input   [31:0]              hilo_data_i,
    input   [31:0]              cp0_data_i,
    input                       mem_to_reg_i,
    input   [31:0]              pc_return_addr_i,
    input   [31:0]              sign_extend_imm16_i,
    input   [31:0]              zero_extend_imm16_i,
    input   [31:0]              load_upper_imm16_i,
    
    input                       bypass_mem_hi_write_enable_i,
    input   [31:0]              bypass_mem_hi_write_data_i,
    input                       bypass_mem_lo_write_enable_i,
    input   [31:0]              bypass_mem_lo_write_data_i,
    input                       bypass_mem_cp0_write_enable_i,
    input   [4:0]               bypass_mem_cp0_write_addr_i,
    input   [31:0]              bypass_mem_cp0_write_data_i,
    input                       bypass_wb_hi_write_enable_i,
    input   [31:0]              bypass_wb_hi_write_data_i,
    input                       bypass_wb_lo_write_enable_i,
    input   [31:0]              bypass_wb_lo_write_data_i,
    
    input                       hilo_read_addr_i,
    input   [4:0]               cp0_read_addr_i,
    
    output  reg[31:0]           pc_o,
    output  reg[7:0]            aluop_o,
    output  reg                 now_in_delayslot_o,
    output  [31:0]              exception_type_o,
    output  reg                 regfile_write_enable_o,
    output  reg                 ram_write_enable_o,
    output  reg                 hi_write_enable_o,
    output  reg                 lo_write_enable_o,
    output  reg                 cp0_write_enable_o,
    output  reg[4:0]            regfile_write_addr_o,
    output  reg[4:0]            cp0_write_addr_o,
    output  reg[31:0]           alu_data_o,
    output  reg[31:0]           ram_write_data_o,
    output  reg[31:0]           hi_write_data_o,
    output  reg[31:0]           lo_write_data_o,
    output  reg[31:0]           cp0_write_data_o,
    output  reg                 mem_to_reg_o,
    output  reg                 exe_stall_request_o
);

reg is_overflow;
assign exception_type_o = {exception_type_i[31:30], is_overflow, exception_type_i[28:0]};

wire[31:0] alu_output_data;
wire[31:0] hilo_data_forward, cp0_data_forward;
wire[63:0] mul_data, div_data, hilo_write_data;
wire start, div_done, flag_unsigned, div_stall;
assign start = (aluop_i == `ALUOP_DIV || aluop_i == `ALUOP_DIVU) ? 1 : 0;
assign flag_unsigned = (aluop_i == `ALUOP_DIVU) ? 1 : 0;

reg div_done_t;
assign div_stall = (aluop_i == `ALUOP_DIV || aluop_i == `ALUOP_DIVU) ? !div_done_t : 0;
reg [31:0] pre_pc;
always @ (posedge clk) begin
    if (rst == 1'b0) begin
        pre_pc = 32'b0;
        div_done_t = 1'b0;
    end 
    else begin
        if (pre_pc != pc_i) begin
            pre_pc = pc_i;
            div_done_t = 1'b0;
        end 
        else begin
            if (div_done == 1'b1) div_done_t = 1'b1; 
        end
    end
end

assign hilo_data_forward = get_hilo_data_forward(hilo_data_i, hilo_read_addr_i,
                                                bypass_mem_hi_write_enable_i, bypass_mem_hi_write_data_i,
                                                bypass_mem_lo_write_enable_i, bypass_mem_lo_write_data_i,
                                                bypass_wb_hi_write_enable_i, bypass_wb_hi_write_data_i,
                                                bypass_wb_lo_write_enable_i, bypass_wb_lo_write_data_i);

function [31:0] get_hilo_data_forward(input [31:0] hilo_data, input hilo_read_addr, input bypass_mem_hi_write_enable,
                                      input [31:0] bypass_mem_hi_write_data, input bypass_mem_lo_write_enable,
                                      input [31:0] bypass_mem_lo_write_data, input bypass_wb_hi_write_enable,
                                      input [31:0] bypass_wb_hi_write_data, input bypass_wb_lo_write_enable,
                                      input [31:0] bypass_wb_lo_write_data);
    begin
        get_hilo_data_forward = hilo_data;       
        if (hilo_read_addr == 0) begin //  read lo reg
            if (bypass_wb_lo_write_enable) get_hilo_data_forward = bypass_wb_lo_write_data;
            if (bypass_mem_lo_write_enable) get_hilo_data_forward = bypass_mem_lo_write_data;
        end 
        else begin // read hi reg
            if (bypass_wb_hi_write_enable) get_hilo_data_forward = bypass_wb_hi_write_data;
            if (bypass_mem_hi_write_enable) get_hilo_data_forward = bypass_mem_hi_write_data;
        end
    end
endfunction

assign cp0_data_forward = (bypass_mem_cp0_write_enable_i == 1 && bypass_mem_cp0_write_addr_i == cp0_read_addr_i) ? bypass_mem_cp0_write_data_i : cp0_data_i;
    
always @ (*) begin
    if (rst == 1'b0) begin
        pc_o <= 32'b0;
        aluop_o <= 8'h00;
        now_in_delayslot_o <= 1'b0;
        regfile_write_enable_o <= 1'b0;
        ram_write_enable_o <= 1'b0;
        hi_write_enable_o <= 1'b0;
        lo_write_enable_o <= 1'b0;
        cp0_write_enable_o <= 1'b0;
        regfile_write_addr_o <= 5'b00000;
        cp0_write_addr_o <= 5'b00000;
        alu_data_o <= 32'b0;
        ram_write_data_o <= 32'b0;
        hi_write_data_o <= 32'b0;
        lo_write_data_o <= 32'b0;
        cp0_write_data_o <= 32'b0;
        mem_to_reg_o <= 1'b0;
        exe_stall_request_o <= 1'b0;
        is_overflow <= 1'b0;
    end 
    else begin
        pc_o <= pc_i;
        aluop_o <= aluop_i;
        now_in_delayslot_o <= now_in_delayslot_i;
        regfile_write_enable_o <= regfile_write_enable_i;
        ram_write_enable_o <= ram_write_enable_i;
        hi_write_enable_o <= hi_write_enable_i;
        lo_write_enable_o <= lo_write_enable_i;
        cp0_write_enable_o <= cp0_write_enable_i;
        regfile_write_addr_o <= get_regfile_write_addr(aluop_i, regfile_write_addr_i, rs_data_i, rt_data_i, sign_extend_imm16_i, alu_output_data, instr_i); // get regfile write addr
        is_overflow <= get_is_overflow(aluop_i, rs_data_i, rt_data_i, sign_extend_imm16_i, alu_output_data);
        cp0_write_addr_o <= instr_i[15:11];  // MTC0:cp0 write addr is rd
        alu_data_o <= alu_output_data; 
        
        ram_write_data_o <= rt_data_i;
        
        hi_write_data_o <= hilo_write_data[63:32];
        lo_write_data_o <= hilo_write_data[31:0];
        
        cp0_write_data_o <= rt_data_i;
        mem_to_reg_o <= mem_to_reg_i;
        exe_stall_request_o <= div_stall;
    end
end
    
assign alu_output_data = get_alu_data(aluop_i, instr_i, rs_data_i, rt_data_i, sign_extend_imm16_i, zero_extend_imm16_i,
                                       load_upper_imm16_i, pc_return_addr_i, hilo_data_forward, cp0_data_forward);

function [31:0] get_alu_data(input [7:0] aluop, input [31:0] instr, input [31:0] rs_value, input [31:0] rt_value,
                             input [31:0] sign_extend_imm16, input [31:0] zero_extend_imm16, input [31:0] load_upper_imm16,
                             input [31:0] pc_return_addr, input [31:0] hilo_data_forward, input [31:0] cp0_data_forward);
    case (aluop)
        `ALUOP_ADD : get_alu_data = rs_value + rt_value;        
        `ALUOP_ADDI : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_ADDU : get_alu_data = rs_value + rt_value;        
        `ALUOP_ADDIU : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_SUB : get_alu_data = rs_value - rt_value;        
        `ALUOP_SUBU : get_alu_data = rs_value - rt_value;        
        `ALUOP_SLT : get_alu_data = $signed(rs_value) < $signed(rt_value);        
        `ALUOP_SLTI : get_alu_data = $signed(rs_value) < $signed(sign_extend_imm16);        
        `ALUOP_SLTU : get_alu_data = $unsigned(rs_value) < $unsigned(rt_value);        
        `ALUOP_SLTIU : get_alu_data = $unsigned(rs_value) < $unsigned(sign_extend_imm16);        
        `ALUOP_AND : get_alu_data = rs_value & rt_value;        
        `ALUOP_ANDI : get_alu_data = rs_value & zero_extend_imm16;        
        `ALUOP_LUI : get_alu_data = load_upper_imm16;        
        `ALUOP_NOR : get_alu_data = ~(rs_value | rt_value);        
        `ALUOP_OR : get_alu_data = rs_value | rt_value;        
        `ALUOP_ORI : get_alu_data = rs_value | zero_extend_imm16;        
        `ALUOP_XOR : get_alu_data = rs_value ^ rt_value;        
        `ALUOP_XORI : get_alu_data = rs_value ^ zero_extend_imm16;        
        `ALUOP_SLL : get_alu_data = rt_value << instr[10:6];        
        `ALUOP_SLLV : get_alu_data = rt_value << rs_value[4:0];        
        `ALUOP_SRA : get_alu_data = $signed(rt_value) >>> instr[10:6];        
        `ALUOP_SRAV : get_alu_data = $signed(rt_value) >>> rs_value[4:0];        
        `ALUOP_SRL : get_alu_data = rt_value >> instr[10:6];        
        `ALUOP_SRLV : get_alu_data = rt_value >> rs_value[4:0];        
        `ALUOP_BGEZAL : get_alu_data = pc_return_addr;        
        `ALUOP_BLTZAL : get_alu_data = pc_return_addr;        
        `ALUOP_JAL : get_alu_data = pc_return_addr;        
        `ALUOP_JALR : get_alu_data = pc_return_addr;        
        `ALUOP_MFHI : get_alu_data = hilo_data_forward;        
        `ALUOP_MFLO : get_alu_data = hilo_data_forward;        
        `ALUOP_LB : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_LBU :  get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_LH : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_LHU : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_LW : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_SB :  get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_SH : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_SW : get_alu_data = rs_value + sign_extend_imm16;        
        `ALUOP_MFC0 : get_alu_data = cp0_data_forward;        
        default : get_alu_data = 0;       
    endcase
endfunction

function get_is_overflow(input [7:0] aluop, input [31:0] rs_value, input [31:0] rt_value, input [31:0] sign_extend_imm16, input [31:0] alu_output_data);
    begin
        get_is_overflow = 0;
        case(aluop)
        `ALUOP_ADD: begin
            if ({rs_value[31], rt_value[31], alu_output_data[31]} == 3'b001||{rs_value[31], rt_value[31], alu_output_data[31]} == 3'b110)
	            get_is_overflow = 1;
        end
        `ALUOP_ADDI: begin
            if ({rs_value[31], sign_extend_imm16[31], alu_output_data[31]} == 3'b001||{rs_value[31], sign_extend_imm16[31], alu_output_data[31]} == 3'b110)
	            get_is_overflow = 1;
        end
        `ALUOP_SUB: begin
            if ({rs_value[31], rt_value[31], alu_output_data[31]} == 3'b011|| {rs_value[31], rt_value[31], alu_output_data[31]} == 3'b100)
                get_is_overflow = 1;
        end 
        default: get_is_overflow = 0;
        endcase
    end
endfunction

function [4:0] get_regfile_write_addr(input [7:0] aluop, input [4:0] regfile_write_addr, input [31:0] rs_value,
                                      input [31:0] rt_value, input [31:0] sign_extend_imm16, input [31:0] alu_output_data,
                                      input [31:0] instr);
    begin
        get_regfile_write_addr = regfile_write_addr;        
        case(aluop)
        `ALUOP_ADD: begin
            if ((rs_value[31] == 0 && rt_value[31] == 0 && alu_output_data[31] == 1) || (rs_value[31] == 1 && rt_value[31] == 1 && alu_output_data[31] == 0))
	            get_regfile_write_addr = 0;
        end
        `ALUOP_ADDI: begin
            if ((rs_value[31] == 0 && sign_extend_imm16[31] == 0 && alu_output_data[31] == 1) || (rs_value[31] == 1 && sign_extend_imm16[31] == 1 && alu_output_data[31] == 0))
	            get_regfile_write_addr = 0;
        end
        `ALUOP_SUB: begin
            if ((rs_value[31] == 0 && rt_value[31] == 1 && alu_output_data[31] == 1)|| rs_value[31] == 1 && rt_value[31] == 0 && alu_output_data[31] == 0)
                get_regfile_write_addr = 0;
        end
        `ALUOP_JAL:     get_regfile_write_addr = 5'b11111;
        `ALUOP_BLTZAL:  get_regfile_write_addr = 5'b11111;
        `ALUOP_BGEZAL:  get_regfile_write_addr = 5'b11111;            
        `ALUOP_MFC0: get_regfile_write_addr = instr[20:16];
        default: get_regfile_write_addr = regfile_write_addr;
        endcase
    end
endfunction

assign mul_data = get_mult_data(aluop_i, rs_data_i, rt_data_i);
    
function [63:0] get_mult_data(input [7:0] aluop, input [31:0] rs_value, input [31:0] rt_value);
    begin
        case (aluop)
            `ALUOP_MULT : get_mult_data = $signed(rs_value) * $signed(rt_value);
            `ALUOP_MULTU : get_mult_data = $unsigned(rs_value) * $unsigned(rt_value);
            default : get_mult_data = 0;
        endcase
    end
endfunction

assign hilo_write_data = get_hilo_write_data(aluop_i, mul_data, div_data, rs_data_i);
    
function [63:0] get_hilo_write_data(input [7:0] aluop, input [63:0] mul_data, input [63:0] div_data, input [31:0] rs_value);
    begin
        case (aluop)
            `ALUOP_MTHI, `ALUOP_MTLO : get_hilo_write_data = {rs_value, rs_value};
            `ALUOP_MULT, `ALUOP_MULTU : get_hilo_write_data = mul_data;
            `ALUOP_DIV, `ALUOP_DIVU : get_hilo_write_data = div_data;
            default : get_hilo_write_data = 0;
        endcase
    end
endfunction

div_wrapper div_wrapper0(
    .clock(clk),
    .reset(rst),
    .start(start),
    .flag_unsigned(flag_unsigned),
    .operand1(rs_data_i),
    .operand2(rt_data_i),
    .result(div_data),
    .done(div_done)
);
endmodule