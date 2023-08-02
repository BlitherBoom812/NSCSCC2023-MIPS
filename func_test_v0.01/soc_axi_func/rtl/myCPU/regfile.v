`include "defines.vh"
module regfile (
    input        clock_i,
    input        reset_i,
    input        regfile_write_enable_i,
    input [ 4:0] regfile_write_addr_i,
    input [31:0] regfile_write_data_i,
    input [ 4:0] rs_read_addr_i,
    input [ 4:0] rt_read_addr_i,

    output wire [31:0] rs_data_o,
    output wire [31:0] rt_data_o
);

    reg [31:0] regfile[31:0];

    // write
    always @(posedge clock_i) begin
        if (reset_i == `RST_DISABLE) if (regfile_write_enable_i == 1'b1 && regfile_write_addr_i != 5'h0) regfile[regfile_write_addr_i] <= regfile_write_data_i;
    end
    // read(write first, then read support)
    function [31:0] get_rx_data(input [4:0] rx_read_addr, input [4:0] regfile_write_addr, input reg regfile_write_enable, input [31:0] regfile_write_data);
        if (rx_read_addr == 5'h0) get_rx_data = 32'h0;
        else if (regfile_write_enable == 1'b1 && rx_read_addr == regfile_write_addr) get_rx_data = regfile_write_data;
        else get_rx_data = regfile[rx_read_addr];
    endfunction

    assign rs_data_o = get_rx_data(rs_read_addr_i, regfile_write_addr_i, regfile_write_enable_i, regfile_write_data_i);
    assign rt_data_o = get_rx_data(rt_read_addr_i, regfile_write_addr_i, regfile_write_enable_i, regfile_write_data_i);

endmodule
