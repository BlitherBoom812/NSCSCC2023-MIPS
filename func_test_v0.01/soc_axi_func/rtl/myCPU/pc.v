`include "defines.vh"

module pc (
    input        reset_i,
    input        clock_i,
    input [ 3:0] stall_i,
    input        exception_i,
    input [31:0] exception_pc_i,
    input        branch_enable_i,
    input [31:0] branch_addr_i,

    output     [31:0] exception_type_o,
    output reg [31:0] pc_o
);

    wire [31:0] pc_next;

    always @(posedge clock_i) begin
        if (reset_i == 1'b0) pc_o <= 32'hbfc0_0000;
        else pc_o <= pc_next;
    end

    assign pc_next = 
        (exception_i === 1'b1) ?
            exception_pc_i 
        :
            (stall_i === 4'b0000) ? 
                (branch_enable_i === 1'b1) ? 
                    branch_addr_i 
                : 
                    pc_o + 4 
            : 
                pc_o;

    assign exception_type_o = (pc_o[1:0] === 2'b00) ? {32'b0} : {1'b1, 31'b0};

endmodule