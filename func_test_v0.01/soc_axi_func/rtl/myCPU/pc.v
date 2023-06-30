`include "defines.v"
module pc(
input wire                    rst,
input wire                    clk,
input wire[3:0]               stall,
input wire                    exception,
input wire  [`INST_ADDR_BUS]  exception_pc_i,
input wire                    branch_enable_i,
input wire  [`INST_ADDR_BUS]  branch_addr_i,

output wire [`EXCEP_TYPE_BUS] exception_type_o,
output reg  [`INST_ADDR_BUS]  pc_o
);

always @ (posedge clk) begin
    if (rst == `RST_ENABLE) pc_o <= 32'hbfc0_0000;
    else if (exception == 1) pc_o <= exception_pc_i;
    else if(stall==4'b0000) pc_o = (branch_enable_i == 1 ? branch_addr_i : pc_o + 4);
end

assign exception_type_o = pc_o[1:0] == 2'b00 ? {32'b0} :  {1'b1,31'b0};

endmodule