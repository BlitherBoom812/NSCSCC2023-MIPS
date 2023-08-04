`include "defines.vh"

module if_postif(
    input clock_i,
    input reset_i,

    input [31:0] if_pc_i,
    input [31:0] if_exception_type_i,
    input [31:0] if_inst_ren_i,

    input branch_enable_i,
    input exception_i,
    input [3:0] stall_i,

    output reg [31:0] postif_pc_o,
    output reg [31:0] postif_exception_type_o,
    output reg postif_inst_ren_o,
    output reg postif_inst_valid_o
);

    always @(posedge clock_i) begin
        if (reset_i === `RST_ENABLE || exception_i == 1'b1) begin
            postif_pc_o <= 32'b0;
            postif_exception_type_o <= 32'b0;
            postif_inst_ren_o <= 1'b0;
            postif_inst_valid_o <= 1'b0;
        end else if(stall_i == 4'b0000) begin
            postif_pc_o <= if_pc_i;
            postif_exception_type_o <= if_exception_type_i;
            postif_inst_ren_o <= if_inst_ren_i;
            postif_inst_valid_o <= ~branch_enable_i;
        end else begin
            if (branch_enable_i) begin
                postif_inst_valid_o <= 1'b0;
            end
        end
    end

endmodule