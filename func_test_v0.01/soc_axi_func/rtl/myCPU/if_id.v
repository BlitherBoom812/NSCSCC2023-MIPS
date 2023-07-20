`include "defines.vh"
module if_id(
    input                    rst,
    input                    clk,
    input  [31:0]            if_pc,
    input  [31:0]            if_instr,
    input                    exception,
    input  [3:0]             stall,
	input  [31:0]            if_exception_type,
		
	output reg [31:0]        id_exception_type,
    output reg [31:0]        id_pc,
    output reg [31:0]        id_instr
);

always @ (posedge clk) begin
    if (rst == 1'b0 || exception == 1'b1) begin
        id_pc <= 32'b0;
        id_instr <= 32'b0;
        id_exception_type <= 6'h0;
    end 
    else if (stall == 4'b0000)begin
        id_pc <= if_pc;
        id_instr <= if_instr;
        id_exception_type <= if_exception_type;
    end
end
endmodule