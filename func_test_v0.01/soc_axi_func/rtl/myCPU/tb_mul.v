`timescale 1ns / 1ns
`include "defines.vh"
module tb_mul ();

    parameter PERIOD = 10;
    // mul Inputs
    reg  [31:0] mul1 = 0;
    reg  [31:0] mul2 = 0;
    reg         clk = 0;
    reg         rst = 0;
    reg         reset = `RST_ENABLE;
    reg         valid = 0;
    reg         mul_signed = 0;

    // mul Outputs
    wire [65:0] result;
    wire        done;

    initial begin
        forever #(PERIOD / 2) clk = ~clk;
    end

    initial begin
        #(PERIOD * 2) rst = `RST_DISABLE;
    end

    mul u_mul (
        .mul1  (mul1[31:0]),
        .mul2  (mul2[31:0]),
        .clk   (clk),
        .reset (rst),
        .valid (valid),
        .result(result[65:0]),
        .done(done),
        .flag_unsigned(~mul_signed)
    );

    reg [7:0] test_cnt;
    reg       send_flag;

    // initial begin
    //     mul1      = -100;
    //     mul2      = $signed(-20);
    //     test_cnt  = 0;
    //     send_flag = 0;
    // end

    // initial begin
    //     #(PERIOD * 2) $display("test count %d: mul1 = %d, mul2 = %d, result = %d", test_cnt, $signed(mul1), mul2, result);
    // end

    always @(posedge clk) begin
        if (done) begin
            if (mul_signed) begin
                $display("test count %d: mul1 = %d, mul2 = %d, result = %d", test_cnt, $signed(mul1), $signed(mul2), result);
            end else begin
                $display("test count %d: mul1 = %d, mul2 = %d, result = %d", test_cnt, $unsigned(mul1), $unsigned(mul2), result);
            end
            test_cnt  = test_cnt + 1;
            send_flag = 0;
        end else begin
            if (send_flag == 1'b1) begin
                valid = 0;
            end else begin
                valid     = 1;
                send_flag = 1'b1;
            end
            case (test_cnt)
                0: begin
                    mul1       = 10;
                    mul2       = 20;
                    mul_signed = 0;
                    // -200
                end
                1: begin
                    mul1       = -888;
                    mul2       = 666;
                    mul_signed = 1;
                    valid      = 1;
                    // -519408 
                end
                2: begin
                    mul1       = -777700;
                    mul2       = -666600;
                    mul_signed = 1;
                    valid      = 1;
                    // 518414820000
                end
                3: begin
                    mul1       = 78900;
                    mul2       = -1234500;
                    mul_signed = 0;
                    valid      = 1;
                    // -9,740,2050000
                end
                default: begin
                    mul1       = 0;
                    mul2       = 0;
                    mul_signed = 0;
                    valid      = 0;
                end
            endcase
        end
    end

endmodule
