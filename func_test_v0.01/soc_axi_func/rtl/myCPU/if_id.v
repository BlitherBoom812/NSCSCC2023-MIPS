`include "defines.vh"

module if_id (
    input        reset_i,
    input        clock_i,
    input [31:0] if_pc_i,
    input [31:0] if_inst_i,
    input        exception_i,
    input [ 3:0] stall_i,
    input [31:0] if_exception_type_i,

    output reg [31:0] id_exception_type_o,
    output reg [31:0] id_pc_o,
    output reg [31:0] id_inst_o
);

    always @(posedge clock_i) begin
        if (reset_i == 1'b0 || exception_i == 1'b1) begin
            id_pc_o             <= 32'b0;
            id_inst_o          <= 32'b0;
            id_exception_type_o <= 6'h0;
        end else if (stall_i == 4'b0000) begin
            id_pc_o             <= if_pc_i;
            id_inst_o          <= if_inst_i;
            id_exception_type_o <= if_exception_type_i;
        end
    end

endmodule
