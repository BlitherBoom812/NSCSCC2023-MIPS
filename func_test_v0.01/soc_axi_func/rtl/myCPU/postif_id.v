module postif_id (
    input        reset_i,
    input        clock_i,

    input [31:0] postif_pc_i,
    input [31:0] postif_inst_i,
    input [31:0] postif_exception_type_i,
    input postif_inst_ren_i,
    input postif_inst_ok_i,
    input postif_inst_valid_i,

    input branch_enable_i,
    input        exception_i,
    input [ 3:0] stall_i,

    output reg [31:0] id_pc_o,
    output reg [31:0] id_inst_o,
    output reg [31:0] id_exception_type_o
);
    wire inst_stall, id_stall, exe_stall, data_stall;
    assign inst_stall = stall_i[0];
    assign id_stall = stall_i[1];
    assign exe_stall = stall_i[2];
    assign data_stall = stall_i[3];
    
    reg [31:0] pc_buf;  // store temporarily
    reg [31:0] inst_buf;
    reg buffered;

    always @(posedge clock_i) begin
        if (reset_i == 1'b0 || exception_i == 1'b1) begin
            id_pc_o             <= 32'b0;
            id_inst_o           <= 32'b0;
            id_exception_type_o <= 6'h0;
            pc_buf <= 32'h0000_0000;
            inst_buf <= 32'h0000_0000;
            buffered <= 1'b0;
        end else if (inst_stall == 1'b1) begin
            id_pc_o             <= id_pc_o;
            id_inst_o           <= 32'b0;
            id_exception_type_o <= 6'h0;
        end
        else if ((id_stall | exe_stall | data_stall) == 1'b1) begin // inst stall = 0, but stall behind
            pc_buf <= postif_pc_i;
            inst_buf <= postif_inst_i;
            buffered <= 1'b1;
        end else begin // no stall
            id_pc_o             <= 
                (buffered === 1'b1) ? pc_buf : 
                ((~branch_enable_i) & postif_inst_valid_i) ? postif_pc_i : 32'h0000_0000;
            id_inst_o           <= 
                (buffered === 1'b1) ? inst_buf : 
                ((~branch_enable_i) & postif_inst_valid_i) ? postif_inst_i : 32'h0000_0000;
            id_exception_type_o <= postif_exception_type_i;
            pc_buf <= 32'h0000_0000;
            inst_buf <= 32'h0000_0000;
            buffered <= 1'b0;
        end
    end
endmodule
