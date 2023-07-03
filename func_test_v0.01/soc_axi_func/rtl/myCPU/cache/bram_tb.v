`timescale 1ns / 1ps
`define PERIOD 10   // 100MHz
module bram_tb_top ();

reg clk;

reg wea;

reg [6:0] addra;

reg [31:0] data_i;

wire [31:0] data_o;

bram bram(
    .clka     (clk),
    .ena      (1),
    .wea      (wea),
    .addra    (addra),
    .dina     (data_i),
    .douta    (data_o)
);

initial begin
    forever #(`PERIOD / 2) clk = ~clk;
end

initial begin
    clk = 0;
    wea = 0;
    addra = 7'h00;
    data_i = 32'h00000000;
    #(`PERIOD)
    addra = 7'h00;
    data_i = 32'h12345678;
    wea = 1;
    $display("set addr %h to %h", addra, data_i);

    #(`PERIOD) 
    addra = 7'h01;
    data_i = 32'h98765432;
    wea = 1;
    $display("set addr %h to %h", addra, data_i);

    #(`PERIOD)
    $display("data_o: %h", data_o); // 98765432

    #(`PERIOD)
    addra = 7'h01;
    data_i = 32'h89abcdef;
    wea = 1;
    $display("set addr %h to %h", addra, data_i);
    $display("data_o: %h", data_o); // 98765432

    #(`PERIOD)
    wea = 0;
    addra = 7'h00;
    data_i = 32'h00000000;
    $display("data_o: %h", data_o); // 89abcdef

    #(`PERIOD * 100)
    $finish();
end
endmodule