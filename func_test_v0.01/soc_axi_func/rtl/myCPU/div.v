`include "defines.vh"
module div(
    input             clock,
    input             reset,
    input             start,
    
    input             flag_unsigned,
    
    input   [31:0]    operand1,
    input   [31:0]    operand2,

    output  [63:0]    result,
    output            done
);
			
parameter DIV_CYCLES = 36;

wire [31:0] abs_opa1;
wire [31:0] abs_opa2;

wire [31:0] tmp_quotient;
wire [31:0] tmp_remain;

wire [31:0] dquotient;
wire [31:0] dremain;

wire div_done;
reg [DIV_CYCLES:0] div_stage;

div_core div_core0(
    .clk (clock),
    .ena (start),
    .z   ({32'h0, abs_opa1}),
    .d   (abs_opa2),
    .q   (tmp_quotient),
    .s   (tmp_remain),
    .div0(),
    .ovf ()
);

assign abs_opa1 = (flag_unsigned || !operand1[31]) ? operand1 : -operand1;
assign abs_opa2 = (flag_unsigned || !operand2[31]) ? operand2 : -operand2;

assign div_done = div_stage[0];
assign dquotient = (flag_unsigned || !(operand1[31]^operand2[31])) ? tmp_quotient : -tmp_quotient;
assign dremain = (flag_unsigned || !(operand1[31]^tmp_remain[31])) ? tmp_remain : -tmp_remain;

assign done = div_done;
assign result = {dremain, dquotient};

always @(posedge clock) begin
    if (reset == 1'b0) 
        div_stage <= 1'b0;
    else if(!start)
        div_stage <= 1'b0;
    else if(div_stage != 1'b0)
        div_stage <= div_stage >> 1; 
	else
        div_stage <= 1'b1 << (DIV_CYCLES-1);
end
endmodule