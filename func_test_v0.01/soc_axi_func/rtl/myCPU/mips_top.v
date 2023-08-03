`include "defines.vh"
module mips_top (
    input clock_i,
    input reset_i,

    input  [5:0] interrupt_i,
    output       time_int_out_o,

    output [31:0] inst_sram_addr_o,
    output inst_sram_ren_o,
    output inst_sram_cache_ena_o,
    input  [31:0] inst_sram_rdata_i,
    input inst_sram_ok_i,

    output        data_sram_ren_o,
    output [ 3:0] data_sram_wen_o,
    output [31:0] data_sram_addr_o,
    output [31:0] data_sram_wdata_o,
    input  [31:0] data_sram_rdata_o,

    output [31:0] debug_wb_pc_o,
    output [ 3:0] debug_wb_wen_o,
    output [ 4:0] debug_wb_num_o,
    output [31:0] debug_wb_data_o,

    input inst_stall_i,
    input data_stall_i,

    output flush_o
);

    wire [31:0] if_pc_if_postif;
    wire [31:0] if_exception_type_if_postif;

    wire [31:0] if_postif_pc_postif;
    wire [31:0] if_postif_exception_type_postif;
    wire if_postif_inst_ren_postif;
    wire if_postif_inst_valid_postif;

    wire [31:0] postif_pc_postif_id;
    wire [31:0] postif_inst_postif_id;
    wire [31:0] postif_exception_type_postif_id;
    wire postif_inst_ren_postif_id;
    wire postif_inst_ok_postif_id;
    wire postif_inst_valid_postif_id;
    wire        postif_stall_request;

    wire [31:0] postif_id_pc_id;
    wire [31:0] postif_id_inst_id;
    wire [31:0] postif_id_exception_type_id;
    wire postif_id_inst_valid_id;

    wire [31:0] regfile_rs_data_id, regfile_rt_data_id;
    wire [31:0] id_pc_id_ex;
    wire [31:0] id_inst_id_ex;
    wire [31:0] id_rs_data_id_ex, id_rt_data_id_ex;
    wire [7:0] id_aluop_id_ex;
    wire [4:0] id_regfile_write_addr_id_ex;
    wire id_now_in_delayslot_id_ex, id_next_in_delayslot_id_ex;
    wire id_stall_request;
    wire id_regfile_write_enable_id_ex, id_ram_write_enable_id_ex, id_hi_write_enable_id_ex, id_lo_write_enable_id_ex, id_cp0_write_enable_id_ex;
    wire        id_mem_to_reg_id_ex;
    wire [31:0] id_pc_return_addr_id_ex;
    wire [ 4:0] id_cp0_read_addr_id_ex;
    wire        id_hilo_read_addr_id_ex;
    wire [15:0] id_imm16_id_ex;
    wire [31:0] id_exception_type_id_ex;
    wire        id_branch_enable;
    wire [31:0] id_branch_addr;

    wire [31:0] hilo_data_id_ex, cp0_data_id_ex;
    wire [31:0] id_ex_pc_ex;
    wire [31:0] id_ex_rs_data_ex, id_ex_rt_data_ex;
    wire [31:0] id_ex_inst_ex;
    wire [ 7:0] id_ex_aluop_ex;
    wire [ 4:0] id_ex_regfile_write_addr_ex;
    wire        id_ex_now_in_delayslot_ex;
    wire [31:0] id_ex_exception_type_ex;
    wire id_ex_regfile_write_enable_ex, id_ex_ram_write_enable_ex, id_ex_hi_write_enable_ex, id_ex_lo_write_enable_ex, id_ex_cp0_write_enable_ex;
    wire [31:0] id_ex_hilo_data_ex, id_ex_cp0_data_ex;
    wire        id_ex_mem_to_reg_ex;
    wire [31:0] id_ex_pc_return_addr_ex;
    wire [31:0] id_ex_sign_extend_imm16_ex;
    wire [31:0] id_ex_zero_extend_imm16_ex;
    wire [31:0] id_ex_load_upper_imm16_ex;
    wire        id_ex_hilo_read_addr_ex;
    wire [ 4:0] id_ex_cp0_read_addr_ex;
    wire        exe_id_now_in_delayslot;

    wire [31:0] ex_pc_ex_mem;
    wire [ 7:0] ex_aluop_ex_mem;
    wire        ex_now_in_delayslot_ex_mem;
    wire [31:0] ex_exception_type_ex_mem;
    wire ex_regfile_write_enable_ex_mem, ex_ram_write_enable_ex_mem, ex_hi_write_enable_ex_mem, ex_lo_write_enable_ex_mem, ex_cp0_write_enable_ex_mem;
    wire [ 4:0] ex_regfile_write_addr_ex_mem;
    wire [ 4:0] ex_cp0_write_addr_ex_mem;
    wire [31:0] ex_alu_data_ex_mem;
    wire [31:0] ex_ram_write_data_ex_mem;
    wire [31:0] ex_hi_write_data_ex_mem;
    wire [31:0] ex_lo_write_data_ex_mem;
    wire [31:0] ex_cp0_write_data_ex_mem;
    wire        ex_mem_to_reg_ex_mem;
    wire        exe_stall_request;

    wire [31:0] ex_mem_pc_mem;
    wire [ 7:0] ex_mem_aluop_mem;
    wire        ex_mem_now_in_delayslot_mem;
    wire [31:0] ex_mem_exception_type_mem;
    wire ex_mem_regfile_write_enable_mem, ex_mem_ram_write_enable_mem, ex_mem_hi_write_enable_mem, ex_mem_lo_write_enable_mem, ex_mem_cp0_write_enable_mem;
    wire [ 4:0] ex_mem_regfile_write_addr_mem;
    wire [31:0] ex_mem_ram_write_addr_mem;
    wire [ 4:0] ex_mem_cp0_write_addr_mem;
    wire [31:0] ex_mem_alu_data_mem;
    wire [31:0] ex_mem_ram_write_data_mem;
    wire [31:0] ex_mem_hi_write_data_mem;
    wire [31:0] ex_mem_lo_write_data_mem;
    wire [31:0] ex_mem_cp0_write_data_mem;
    wire        ex_mem_mem_to_reg_mem;
    wire [31:0] ex_mem_ram_read_addr_mem;

    wire        mem_stall_request;
    wire [31:0] mem_store_pc;
    wire [31:0] mem_access_mem_addr;
    wire        mem_now_in_delayslot;
    wire [31:0] mem_exception_type;
    wire        mem_regfile_write_enable_mem_wb;
    wire [ 4:0] mem_regfile_write_addr_mem_wb;
    wire        mem_hi_write_enable_mem_wb;
    wire        mem_lo_write_enable_mem_wb;
    wire [31:0] mem_hi_write_data_mem_wb;
    wire [31:0] mem_lo_write_data_mem_wb;
    wire        mem_cp0_write_enable;
    wire [ 4:0] mem_cp0_write_addr;
    wire [31:0] mem_cp0_write_data;
    wire [31:0] mem_regfile_write_data_mem_wb;
    wire [ 3:0] mem_ram_write_select;
    wire        mem_ram_write_enable;
    wire        mem_ram_read_enable;
    wire [31:0] mem_ram_write_addr;
    wire [31:0] mem_ram_write_data;
    wire [31:0] mem_ram_read_addr;

    wire [31:0] ram_read_data;

    wire        mem_wb_regfile_write_enable;
    wire [ 4:0] mem_wb_regfile_write_addr;
    wire [31:0] mem_wb_regfile_write_data;
    wire mem_wb_hi_write_enable, mem_wb_lo_write_enable;
    wire [31:0] mem_wb_hi_write_data, mem_wb_lo_write_data;

    wire        is_exception;
    wire [31:0] cp0_return_pc;

    // inst read
    assign inst_sram_addr_o  = if_pc_if_postif;
    // data access
    assign data_sram_ren_o   = mem_ram_read_enable;
    assign data_sram_wen_o   = mem_ram_write_enable ? mem_ram_write_select : 4'b0000;
    assign data_sram_addr_o  = mem_ram_write_enable ? mem_ram_write_addr : mem_ram_read_addr;
    assign data_sram_wdata_o = mem_ram_write_data;
    assign ram_read_data     = data_sram_rdata_o;
    // stall
    // 4 types of stall: data_stall, inst_stall(outside); exe_stall_request, id_stall_request(inside)
    // new 4 types of stall: data_stall(outside); postif_stall_request, exe_stall_request, id_stall_request(inside)
    // final new 4 types of stall: postif_stall_request, exe_stall_request, id_stall_request, mem_stall_request(inside)
    wire stall_all;
    assign stall_all       = mem_stall_request || exe_stall_request || postif_stall_request;
    // flush
    assign flush_o         = (reset_i == `RST_ENABLE) ? 1'b0 : is_exception;
    // debug
    assign debug_wb_wen_o  = ((reset_i == `RST_ENABLE || stall_all == 1'b1) && flush_o == 1'b0) ? 4'b0000 : {4{mem_wb_regfile_write_enable}};
    assign debug_wb_num_o  = (reset_i == `RST_ENABLE) ? 5'b00000 : mem_wb_regfile_write_addr;
    assign debug_wb_data_o = (reset_i == `RST_ENABLE) ? 32'h00000000 : mem_wb_regfile_write_data;


    pc mips_pc (
        .reset_i        (reset_i),
        .clock_i        (clock_i),
        .stall_i        ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),
        .exception_i    (is_exception),
        .exception_pc_i (cp0_return_pc),
        .branch_enable_i(id_branch_enable),
        .branch_addr_i  (id_branch_addr),

        .exception_type_o(if_exception_type_if_postif),
        .pc_o            (if_pc_if_postif),
        .inst_ren_o(inst_sram_ren_o),
        .inst_cache_ena_o(inst_sram_cache_ena_o)
    );

    if_postif mips_if_postif(
        .clock_i            (clock_i),
        .reset_i            (reset_i),

        .if_pc_i            (if_pc_if_postif),
        .if_exception_type_i(if_exception_type_postif),
        .if_inst_ren_i(inst_sram_ren_o),

        .branch_enable_i(id_branch_enable),
        .exception_i        (is_exception),
        .stall_i            ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),

        .postif_pc_o            (if_postif_pc_postif),
        .postif_exception_type_o(if_postif_exception_type_postif),
        .postif_inst_ren_o(if_postif_inst_ren_postif),
        .postif_inst_valid_o(if_postif_inst_valid_postif)
    );

    postif mips_postif (
        .pc_i            (if_postif_pc_postif),
        .inst_i          (inst_sram_rdata_i),
        .exception_type_i(if_postif_exception_type_postif),
        .inst_ren_i(if_postif_inst_ren_postif),
        .inst_ok_i   (inst_sram_ok_i),
        .inst_valid_i (if_postif_inst_valid_postif),

        .pc_o            (postif_pc_postif_id),
        .inst_o          (postif_inst_postif_id),
        .exception_type_o(postif_exception_type_postif_id),
        .postif_stall_o  (postif_stall_request),
        .inst_ren_o(postif_inst_ren_postif_id),
        .inst_valid_o(postif_inst_valid_postif_id)
    );

    postif_id mips_postif_id (
        .reset_i(reset_i),
        .clock_i(clock_i),

        .postif_pc_i            (postif_pc_postif_id),
        .postif_inst_i          (postif_inst_postif_id),
        .postif_exception_type_i(postif_exception_type_postif_id),
        .postif_inst_ren_i(postif_inst_ren_postif_id),
        .postif_inst_ok_i(postif_inst_ok_postif_id),
        .postif_inst_valid_i(postif_inst_valid_postif_id),

        .branch_enable_i(id_branch_enable),
        .exception_i(is_exception),
        .stall_i    ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),

        .id_pc_o            (postif_id_pc_id),
        .id_inst_o          (postif_id_inst_id),
        .id_exception_type_o(postif_id_exception_type_id)
    );

    // if_id mips_if_id (
    //     .reset_i            (reset_i),
    //     .clock_i            (clock_i),
    //     .if_pc_i            (if_pc_if_id),
    //     .if_inst_i          (rom_inst_postif),
    //     .exception_i        (is_exception),
    //     .stall_i            ({mem_stall_request, exe_stall_request, id_stall_request, inst_stall_i}),
    //     .if_exception_type_i(if_exception_type_postif),

    //     .id_inst_o          (postif_id_inst_id),
    //     .id_pc_o            (postif_id_pc_id),
    //     .id_exception_type_o(postif_id_exception_type_id)
    // );

    id mips_id (
        .reset_i                           (reset_i),
        .inst_i                            (postif_id_inst_id),
        .pc_i                              (postif_id_pc_id),
        .rs_data_i                         (regfile_rs_data_id),
        .rt_data_i                         (regfile_rt_data_id),
        .exe_regfile_write_addr_i          (ex_regfile_write_addr_ex_mem),
        .now_in_delayslot_i                (exe_id_now_in_delayslot),
        .exe_mem_to_reg_i                  (ex_mem_to_reg_ex_mem),
        .forward_ex_regfile_write_enable_i (ex_regfile_write_enable_ex_mem),
        .forward_ex_regfile_write_addr_i   (ex_regfile_write_addr_ex_mem),
        .forward_ex_regfile_write_data_i   (ex_alu_data_ex_mem),
        .forward_mem_regfile_write_enable_i(mem_regfile_write_enable_mem_wb),
        .forward_mem_regfile_write_addr_i  (mem_regfile_write_addr_mem_wb),
        .forward_mem_regfile_write_data_i  (mem_regfile_write_data_mem_wb),
        .exception_type_i                  (postif_id_exception_type_id),

        .pc_o                  (id_pc_id_ex),
        .inst_o                (id_inst_id_ex),
        .rs_data_o             (id_rs_data_id_ex),
        .rt_data_o             (id_rt_data_id_ex),
        .aluop_o               (id_aluop_id_ex),
        .regfile_write_addr_o  (id_regfile_write_addr_id_ex),
        .now_in_delayslot_o    (id_now_in_delayslot_id_ex),
        .next_in_delayslot_o   (id_next_in_delayslot_id_ex),
        .id_stall_request_o    (id_stall_request),
        .regfile_write_enable_o(id_regfile_write_enable_id_ex),
        .ram_write_enable_o    (id_ram_write_enable_id_ex),
        .hi_write_enable_o     (id_hi_write_enable_id_ex),
        .lo_write_enable_o     (id_lo_write_enable_id_ex),
        .cp0_write_enable_o    (id_cp0_write_enable_id_ex),
        .mem_to_reg_o          (id_mem_to_reg_id_ex),
        .pc_return_addr_o      (id_pc_return_addr_id_ex),
        .cp0_read_addr_o       (id_cp0_read_addr_id_ex),
        .hilo_read_addr_o      (id_hilo_read_addr_id_ex),
        .imm16_o               (id_imm16_id_ex),
        .exception_type_o      (id_exception_type_id_ex),
        .branch_enable_o       (id_branch_enable),
        .branch_addr_o         (id_branch_addr)
    );
    id_ex mips_id_ex (
        .clock_i                  (clock_i),
        .reset_i                  (reset_i),
        .exception_i              (is_exception),
        .stall_i                  ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),
        .id_pc_i                  (id_pc_id_ex),
        .id_rs_data_i             (id_rs_data_id_ex),
        .id_rt_data_i             (id_rt_data_id_ex),
        .id_inst_i                (id_inst_id_ex),
        .id_aluop_i               (id_aluop_id_ex),
        .id_regfile_write_addr_i  (id_regfile_write_addr_id_ex),
        .id_now_in_delayslot_i    (id_now_in_delayslot_id_ex),
        .id_next_in_delayslot_i   (id_next_in_delayslot_id_ex),
        .id_regfile_write_enable_i(id_regfile_write_enable_id_ex),
        .id_ram_write_enable_i    (id_ram_write_enable_id_ex),
        .id_hi_write_enable_i     (id_hi_write_enable_id_ex),
        .id_lo_write_enable_i     (id_lo_write_enable_id_ex),
        .id_cp0_write_enable_i    (id_cp0_write_enable_id_ex),
        .id_mem_to_reg_i          (id_mem_to_reg_id_ex),
        .id_pc_return_addr_i      (id_pc_return_addr_id_ex),
        .id_hilo_data_i           (hilo_data_id_ex),
        .id_cp0_data_i            (cp0_data_id_ex),
        .id_imm16_i               (id_imm16_id_ex),
        .id_exception_type_i      (id_exception_type_id_ex),
        .id_hilo_read_addr_i      (id_hilo_read_addr_id_ex),
        .id_cp0_read_addr_i       (id_cp0_read_addr_id_ex),

        .ex_pc_o                  (id_ex_pc_ex),
        .ex_rs_data_o             (id_ex_rs_data_ex),
        .ex_rt_data_o             (id_ex_rt_data_ex),
        .ex_inst_o                (id_ex_inst_ex),
        .ex_aluop_o               (id_ex_aluop_ex),
        .ex_regfile_write_addr_o  (id_ex_regfile_write_addr_ex),
        .ex_now_in_delayslot_o    (id_ex_now_in_delayslot_ex),
        .ex_regfile_write_enable_o(id_ex_regfile_write_enable_ex),
        .ex_ram_write_enable_o    (id_ex_ram_write_enable_ex),
        .ex_hi_write_enable_o     (id_ex_hi_write_enable_ex),
        .ex_lo_write_enable_o     (id_ex_lo_write_enable_ex),
        .ex_cp0_write_enable_o    (id_ex_cp0_write_enable_ex),
        .ex_hilo_data_o           (id_ex_hilo_data_ex),
        .ex_cp0_data_o            (id_ex_cp0_data_ex),
        .ex_mem_to_reg_o          (id_ex_mem_to_reg_ex),
        .ex_pc_return_addr_o      (id_ex_pc_return_addr_ex),
        .ex_sign_extend_imm16_o   (id_ex_sign_extend_imm16_ex),
        .ex_zero_extend_imm16_o   (id_ex_zero_extend_imm16_ex),
        .ex_load_upper_imm16_o    (id_ex_load_upper_imm16_ex),
        .ex_hilo_read_addr_o      (id_ex_hilo_read_addr_ex),
        .ex_cp0_read_addr_o       (id_ex_cp0_read_addr_ex),
        .ex_id_now_in_delayslot_o (exe_id_now_in_delayslot),
        .ex_exception_type_o      (id_ex_exception_type_ex)
    );

    ex mips_ex (
        .reset_i               (reset_i),
        .clock_i               (clock_i),
        .pc_i                  (id_ex_pc_ex),
        .rs_data_i             (id_ex_rs_data_ex),
        .rt_data_i             (id_ex_rt_data_ex),
        .inst_i                (id_ex_inst_ex),
        .aluop_i               (id_ex_aluop_ex),
        .regfile_write_addr_i  (id_ex_regfile_write_addr_ex),
        .now_in_delayslot_i    (id_ex_now_in_delayslot_ex),
        .exception_type_i      (id_ex_exception_type_ex),
        .regfile_write_enable_i(id_ex_regfile_write_enable_ex),
        .ram_write_enable_i    (id_ex_ram_write_enable_ex),
        .hi_write_enable_i     (id_ex_hi_write_enable_ex),
        .lo_write_enable_i     (id_ex_lo_write_enable_ex),
        .cp0_write_enable_i    (id_ex_cp0_write_enable_ex),
        .hilo_data_i           (id_ex_hilo_data_ex),
        .cp0_data_i            (id_ex_cp0_data_ex),
        .mem_to_reg_i          (id_ex_mem_to_reg_ex),
        .pc_return_addr_i      (id_ex_pc_return_addr_ex),
        .sign_extend_imm16_i   (id_ex_sign_extend_imm16_ex),
        .zero_extend_imm16_i   (id_ex_zero_extend_imm16_ex),
        .load_upper_imm16_i    (id_ex_load_upper_imm16_ex),

        .forward_mem_hi_write_enable_i (mem_hi_write_enable_mem_wb),
        .forward_mem_hi_write_data_i   (mem_hi_write_data_mem_wb),
        .forward_mem_lo_write_enable_i (mem_lo_write_enable_mem_wb),
        .forward_mem_lo_write_data_i   (mem_lo_write_data_mem_wb),
        .forward_mem_cp0_write_enable_i(mem_cp0_write_enable),
        .forward_mem_cp0_write_addr_i  (mem_cp0_write_addr),
        .forward_mem_cp0_write_data_i  (mem_cp0_write_data),
        .forward_wb_hi_write_enable_i  (mem_wb_hi_write_enable),
        .forward_wb_hi_write_data_i    (mem_wb_hi_write_data),
        .forward_wb_lo_write_enable_i  (mem_wb_lo_write_enable),
        .forward_wb_lo_write_data_i    (mem_wb_lo_write_data),

        .hilo_read_addr_i(id_ex_hilo_read_addr_ex),
        .cp0_read_addr_i (id_ex_cp0_read_addr_ex),

        .pc_o                  (ex_pc_ex_mem),
        .aluop_o               (ex_aluop_ex_mem),
        .now_in_delayslot_o    (ex_now_in_delayslot_ex_mem),
        .exception_type_o      (ex_exception_type_ex_mem),
        .regfile_write_enable_o(ex_regfile_write_enable_ex_mem),
        .ram_write_enable_o    (ex_ram_write_enable_ex_mem),
        .hi_write_enable_o     (ex_hi_write_enable_ex_mem),
        .lo_write_enable_o     (ex_lo_write_enable_ex_mem),
        .cp0_write_enable_o    (ex_cp0_write_enable_ex_mem),
        .regfile_write_addr_o  (ex_regfile_write_addr_ex_mem),
        .cp0_write_addr_o      (ex_cp0_write_addr_ex_mem),
        .alu_data_o            (ex_alu_data_ex_mem),
        .ram_write_data_o      (ex_ram_write_data_ex_mem),
        .hi_write_data_o       (ex_hi_write_data_ex_mem),
        .lo_write_data_o       (ex_lo_write_data_ex_mem),
        .cp0_write_data_o      (ex_cp0_write_data_ex_mem),
        .mem_to_reg_o          (ex_mem_to_reg_ex_mem),
        .exe_stall_request_o   (exe_stall_request)
    );

    ex_mem mips_ex_mem (
        .reset_i                   (reset_i),
        .clock_i                   (clock_i),
        .exe_pc_i                  (ex_pc_ex_mem),
        .exe_aluop_i               (ex_aluop_ex_mem),
        .exe_now_in_delayslot_i    (ex_now_in_delayslot_ex_mem),
        .exe_exception_type_i      (ex_exception_type_ex_mem),
        .exe_regfile_write_enable_i(ex_regfile_write_enable_ex_mem),
        .exe_ram_write_enable_i    (ex_ram_write_enable_ex_mem),
        .exe_hi_write_enable_i     (ex_hi_write_enable_ex_mem),
        .exe_lo_write_enable_i     (ex_lo_write_enable_ex_mem),
        .exe_cp0_write_enable_i    (ex_cp0_write_enable_ex_mem),
        .exe_regfile_write_addr_i  (ex_regfile_write_addr_ex_mem),
        .exe_cp0_write_addr_i      (ex_cp0_write_addr_ex_mem),
        .exe_alu_data_i            (ex_alu_data_ex_mem),
        .exe_ram_write_data_i      (ex_ram_write_data_ex_mem),
        .exe_hi_write_data_i       (ex_hi_write_data_ex_mem),
        .exe_lo_write_data_i       (ex_lo_write_data_ex_mem),
        .exe_cp0_write_data_i      (ex_cp0_write_data_ex_mem),
        .exe_mem_to_reg_i          (ex_mem_to_reg_ex_mem),
        .exception_i               (is_exception),
        .stall_i                   ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),

        .mem_pc_o                  (ex_mem_pc_mem),
        .mem_aluop_o               (ex_mem_aluop_mem),
        .mem_now_in_delayslot_o    (ex_mem_now_in_delayslot_mem),
        .mem_exception_type_o      (ex_mem_exception_type_mem),
        .mem_regfile_write_enable_o(ex_mem_regfile_write_enable_mem),
        .mem_ram_write_enable_o    (ex_mem_ram_write_enable_mem),
        .mem_hi_write_enable_o     (ex_mem_hi_write_enable_mem),
        .mem_lo_write_enable_o     (ex_mem_lo_write_enable_mem),
        .mem_cp0_write_enable_o    (ex_mem_cp0_write_enable_mem),
        .mem_regfile_write_addr_o  (ex_mem_regfile_write_addr_mem),
        .mem_ram_write_addr_o      (ex_mem_ram_write_addr_mem),
        .mem_cp0_write_addr_o      (ex_mem_cp0_write_addr_mem),
        .mem_alu_data_o            (ex_mem_alu_data_mem),
        .mem_ram_write_data_o      (ex_mem_ram_write_data_mem),
        .mem_hi_write_data_o       (ex_mem_hi_write_data_mem),
        .mem_lo_write_data_o       (ex_mem_lo_write_data_mem),
        .mem_cp0_write_data_o      (ex_mem_cp0_write_data_mem),
        .mem_mem_to_reg_o          (ex_mem_mem_to_reg_mem),
        .mem_ram_read_addr_o       (ex_mem_ram_read_addr_mem)
    );

    mem mips_mem (
        .pc_i                  (ex_mem_pc_mem),
        .aluop_i               (ex_mem_aluop_mem),
        .data_stall_i          (data_stall_i),
        .now_in_delayslot_i    (ex_mem_now_in_delayslot_mem),
        .exception_type_i      (ex_mem_exception_type_mem),
        .regfile_write_enable_i(ex_mem_regfile_write_enable_mem),
        .ram_write_enable_i    (ex_mem_ram_write_enable_mem),
        .hi_write_enable_i     (ex_mem_hi_write_enable_mem),
        .lo_write_enable_i     (ex_mem_lo_write_enable_mem),
        .cp0_write_enable_i    (ex_mem_cp0_write_enable_mem),
        .regfile_write_addr_i  (ex_mem_regfile_write_addr_mem),
        .ram_write_addr_i      (ex_mem_ram_write_addr_mem),
        .cp0_write_addr_i      (ex_mem_cp0_write_addr_mem),
        .alu_data_i            (ex_mem_alu_data_mem),
        .ram_write_data_i      (ex_mem_ram_write_data_mem),
        .hi_write_data_i       (ex_mem_hi_write_data_mem),
        .lo_write_data_i       (ex_mem_lo_write_data_mem),
        .cp0_write_data_i      (ex_mem_cp0_write_data_mem),
        .mem_to_reg_i          (ex_mem_mem_to_reg_mem),
        .ram_read_addr_i       (ex_mem_ram_read_addr_mem),
        .ram_read_data_i       (ram_read_data),
        .reset_i               (reset_i),

        .mem_stall_request_o   (mem_stall_request),
        .store_pc_o            (mem_store_pc),
        .access_mem_addr_o     (mem_access_mem_addr),
        .now_in_delayslot_o    (mem_now_in_delayslot),
        .exception_type_o      (mem_exception_type),
        .regfile_write_enable_o(mem_regfile_write_enable_mem_wb),
        .regfile_write_addr_o  (mem_regfile_write_addr_mem_wb),
        .hi_write_enable_o     (mem_hi_write_enable_mem_wb),
        .lo_write_enable_o     (mem_lo_write_enable_mem_wb),
        .hi_write_data_o       (mem_hi_write_data_mem_wb),
        .lo_write_data_o       (mem_lo_write_data_mem_wb),
        .cp0_write_enable_o    (mem_cp0_write_enable),
        .cp0_write_addr_o      (mem_cp0_write_addr),
        .cp0_write_data_o      (mem_cp0_write_data),
        .regfile_write_data_o  (mem_regfile_write_data_mem_wb),

        .ram_write_select_o(mem_ram_write_select),
        .ram_write_enable_o(mem_ram_write_enable),
        .ram_write_addr_o  (mem_ram_write_addr),
        .ram_write_data_o  (mem_ram_write_data),
        .ram_read_addr_o   (mem_ram_read_addr),
        .ram_read_enable_o (mem_ram_read_enable)
    );

    mem_wb mips_mem_wb (
        .reset_i                   (reset_i),
        .clock_i                   (clock_i),
        .mem_regfile_write_enable_i(mem_regfile_write_enable_mem_wb),
        .mem_regfile_write_addr_i  (mem_regfile_write_addr_mem_wb),
        .mem_hi_write_enable_i     (mem_hi_write_enable_mem_wb),
        .mem_lo_write_enable_i     (mem_lo_write_enable_mem_wb),
        .mem_hi_write_data_i       (mem_hi_write_data_mem_wb),
        .mem_lo_write_data_i       (mem_lo_write_data_mem_wb),
        .mem_cp0_write_enable_i    (mem_cp0_write_enable),
        .mem_cp0_write_addr_i      (mem_cp0_write_addr),
        .mem_cp0_write_data_i      (mem_cp0_write_data),
        .mem_regfile_write_data_i  (mem_regfile_write_data_mem_wb),
        .stall_i                   ({mem_stall_request, exe_stall_request, id_stall_request, postif_stall_request}),
        .exception_i               (is_exception),


        .wb_regfile_write_enable_o(mem_wb_regfile_write_enable),
        .wb_regfile_write_addr_o  (mem_wb_regfile_write_addr),
        .wb_regfile_write_data_o  (mem_wb_regfile_write_data),
        .wb_hi_write_enable_o     (mem_wb_hi_write_enable),
        .wb_lo_write_enable_o     (mem_wb_lo_write_enable),
        .wb_hi_write_data_o       (mem_wb_hi_write_data),
        .wb_lo_write_data_o       (mem_wb_lo_write_data),

        .in_wb_pc_i(mem_store_pc),
        .wb_pc_o   (debug_wb_pc_o)
    );

    regfile mips_regfile (
        .clock_i               (clock_i),
        .reset_i               (reset_i),
        .regfile_write_enable_i(mem_wb_regfile_write_enable),
        .regfile_write_addr_i  (mem_wb_regfile_write_addr),
        .regfile_write_data_i  (mem_wb_regfile_write_data),
        .rs_read_addr_i        (postif_id_inst_id[25:21]),
        .rt_read_addr_i        (postif_id_inst_id[20:16]),

        .rs_data_o(regfile_rs_data_id),
        .rt_data_o(regfile_rt_data_id)
    );

    hilo mips_hilo (
        .clock_i          (clock_i),
        .reset_i          (reset_i),
        .hilo_read_addr_i (id_hilo_read_addr_id_ex),
        .hi_write_enable_i(mem_wb_hi_write_enable),
        .hi_write_data_i  (mem_wb_hi_write_data),
        .lo_write_enable_i(mem_wb_lo_write_enable),
        .lo_write_data_i  (mem_wb_lo_write_data),

        .hilo_read_data_o(hilo_data_id_ex)
    );

    cp0 mips_cp0 (
        .clock_i           (clock_i),
        .reset_i           (reset_i),
        .cp0_read_addr_i   (id_cp0_read_addr_id_ex),
        .cp0_write_enable_i(mem_cp0_write_enable),
        .cp0_write_addr_i  (mem_cp0_write_addr),
        .cp0_write_data_i  (mem_cp0_write_data),
        .exception_type_i  (mem_exception_type),
        .pc_i              (mem_store_pc),
        .exception_addr_i  (mem_access_mem_addr),
        .int_i             (interrupt_i),
        .now_in_delayslot_i(mem_now_in_delayslot),

        .cp0_read_data_o(cp0_data_id_ex),
        .cp0_return_pc_o(cp0_return_pc),
        .timer_int_o    (time_int_out_o),
        .flush_o        (is_exception)
    );
endmodule
