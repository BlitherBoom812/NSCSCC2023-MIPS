`include "defines.v"
module if_id(
    input wire                   rst,
    input wire                   clk,
    input wire [`INST_ADDR_BUS]  if_pc,
    input wire [`INST_BUS]       if_instr,
    input wire                   exception,
    input wire [3:0]             stall,
	input wire [`EXCEP_TYPE_BUS] if_exception_type,
		
	output reg [`EXCEP_TYPE_BUS] id_exception_type,
    output reg [`INST_ADDR_BUS]  id_pc,
    output reg [`INST_BUS]       id_instr
    );

    always @ (posedge clk) begin
        if (rst == `RST_ENABLE || exception == 1) begin
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
