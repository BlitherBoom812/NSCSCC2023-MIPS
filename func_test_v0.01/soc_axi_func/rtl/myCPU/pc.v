`include "defines.vh"
module pc(
    input                     rst,
    input                     clk,
    input [3:0]               stall,
    input                     exception,
    input [31:0]              exception_pc_i,
    input                     branch_enable_i,
    input [31:0]              branch_addr_i,

    output [31:0]             exception_type_o,
    output reg[31:0]          pc_o
);

always @ (posedge clk) begin
    if (rst == 1'b0) pc_o <= 32'hbfc0_0000;
    else if (exception == 1) pc_o <= exception_pc_i;
    else if(stall==4'b0000) pc_o <= (branch_enable_i == 1) ? branch_addr_i : pc_o + 4;
end
assign exception_type_o = (pc_o[1:0] == 2'b00) ? {32'b0} :  {1'b1,31'b0};
endmodule