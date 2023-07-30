`include "defines.vh"
module mul (
    input      [31:0] mul1,
    input      [31:0] mul2,
    output reg [65:0] result = 0,
    input             clk,
    input             reset,
    input             valid
);

    reg  [ 4:0] i = 0;
    wire [31:0] re_mul1;
    reg  [65:0] sum          [15:0];
    reg  [ 1:0] state = 2'b0;

    parameter a = 2'b00;
    parameter b = 2'b01;
    parameter c = 2'b10;

    always @(posedge clk) begin
        if (reset == `RST_ENABLE) begin
            result <= 0;
            state  <= a;
        end else if (valid == 1'b1) begin

            case (state)
                a: begin

                    for (i = 0; i < 16; i = i + 1) begin
                        sum[i] = {65{1'b0}};
                    end

                    case ({
                        mul2[1:0], 1'b0
                    })
                        3'b011: sum[0][64:33] <= (mul1);
                        3'b001: sum[0][64:33] <= (mul1);
                        3'b010: sum[0][65:34] <= (mul1);
                        3'b100: sum[0][65:34] <= (re_mul1);
                        3'b101: sum[0][65:34] <= (re_mul1);
                        3'b110: sum[0][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[3:1])
                        3'b011: sum[1][65:34] <= (mul1);
                        3'b001: sum[1][65:34] <= (mul1);
                        3'b010: sum[1][65:34] <= (mul1);
                        3'b100: sum[1][65:34] <= (re_mul1);
                        3'b101: sum[1][65:34] <= (re_mul1);
                        3'b110: sum[1][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[5:3])
                        3'b011: sum[2][65:34] <= (mul1);
                        3'b001: sum[2][65:34] <= (mul1);
                        3'b010: sum[2][65:34] <= (mul1);
                        3'b100: sum[2][65:34] <= (re_mul1);
                        3'b101: sum[2][65:34] <= (re_mul1);
                        3'b110: sum[2][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[7:5])
                        3'b011: sum[3][65:34] <= (mul1);
                        3'b001: sum[3][65:34] <= (mul1);
                        3'b010: sum[3][65:34] <= (mul1);
                        3'b100: sum[3][65:34] <= (re_mul1);
                        3'b101: sum[3][65:34] <= (re_mul1);
                        3'b110: sum[3][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[9:7])
                        3'b011: sum[4][65:34] <= (mul1);
                        3'b001: sum[4][65:34] <= (mul1);
                        3'b010: sum[4][65:34] <= (mul1);
                        3'b100: sum[4][65:34] <= (re_mul1);
                        3'b101: sum[4][65:34] <= (re_mul1);
                        3'b110: sum[4][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[11:9])
                        3'b011: sum[5][65:34] <= (mul1);
                        3'b001: sum[5][65:34] <= (mul1);
                        3'b010: sum[5][65:34] <= (mul1);
                        3'b100: sum[5][65:34] <= (re_mul1);
                        3'b101: sum[5][65:34] <= (re_mul1);
                        3'b110: sum[5][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[13:11])
                        3'b011: sum[6][65:34] <= (mul1);
                        3'b001: sum[6][65:34] <= (mul1);
                        3'b010: sum[6][65:34] <= (mul1);
                        3'b100: sum[6][65:34] <= (re_mul1);
                        3'b101: sum[6][65:34] <= (re_mul1);
                        3'b110: sum[6][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[15:13])
                        3'b011: sum[7][65:34] <= (mul1);
                        3'b001: sum[7][65:34] <= (mul1);
                        3'b010: sum[7][65:34] <= (mul1);
                        3'b100: sum[7][65:34] <= (re_mul1);
                        3'b101: sum[7][65:34] <= (re_mul1);
                        3'b110: sum[7][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[17:15])
                        3'b011: sum[8][65:34] <= (mul1);
                        3'b001: sum[8][65:34] <= (mul1);
                        3'b010: sum[8][65:34] <= (mul1);
                        3'b100: sum[8][65:34] <= (re_mul1);
                        3'b101: sum[8][65:34] <= (re_mul1);
                        3'b110: sum[8][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[19:17])
                        3'b011: sum[9][65:34] <= (mul1);
                        3'b001: sum[9][65:34] <= (mul1);
                        3'b010: sum[9][65:34] <= (mul1);
                        3'b100: sum[9][65:34] <= (re_mul1);
                        3'b101: sum[9][65:34] <= (re_mul1);
                        3'b110: sum[9][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[21:19])
                        3'b011: sum[10][65:34] <= (mul1);
                        3'b001: sum[10][65:34] <= (mul1);
                        3'b010: sum[10][65:34] <= (mul1);
                        3'b100: sum[10][65:34] <= (re_mul1);
                        3'b101: sum[10][65:34] <= (re_mul1);
                        3'b110: sum[10][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[23:21])
                        3'b011: sum[11][65:34] <= (mul1);
                        3'b001: sum[11][65:34] <= (mul1);
                        3'b010: sum[11][65:34] <= (mul1);
                        3'b100: sum[11][65:34] <= (re_mul1);
                        3'b101: sum[11][65:34] <= (re_mul1);
                        3'b110: sum[11][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[25:23])
                        3'b011: sum[12][65:34] <= (mul1);
                        3'b001: sum[12][65:34] <= (mul1);
                        3'b010: sum[12][65:34] <= (mul1);
                        3'b100: sum[12][65:34] <= (re_mul1);
                        3'b101: sum[12][65:34] <= (re_mul1);
                        3'b110: sum[12][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[27:25])
                        3'b011: sum[13][65:34] <= (mul1);
                        3'b001: sum[13][65:34] <= (mul1);
                        3'b010: sum[13][65:34] <= (mul1);
                        3'b100: sum[13][65:34] <= (re_mul1);
                        3'b101: sum[13][65:34] <= (re_mul1);
                        3'b110: sum[13][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[29:27])
                        3'b011: sum[14][65:34] <= (mul1);
                        3'b001: sum[14][65:34] <= (mul1);
                        3'b010: sum[14][65:34] <= (mul1);
                        3'b100: sum[14][65:34] <= (re_mul1);
                        3'b101: sum[14][65:34] <= (re_mul1);
                        3'b110: sum[14][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase


                    case (mul2[31:29])
                        3'b011: sum[15][65:34] <= (mul1);
                        3'b001: sum[15][65:34] <= (mul1);
                        3'b010: sum[15][65:34] <= (mul1);
                        3'b100: sum[15][65:34] <= (re_mul1);
                        3'b101: sum[15][65:34] <= (re_mul1);
                        3'b110: sum[15][65:34] <= (re_mul1);
                        3'b000: ;
                        3'b111: ;
                    endcase

                    state <= b;

                end

                b: begin
                    if ({mul2[1:0], 1'b0} == 3'b011 || {mul2[1:0], 1'b0} == 3'b100) begin
                        sum[0] = $signed(sum[0]) >>> 33;
                        sum[0][65] <= 1'b0;
                    end else begin
                        sum[0] = $signed(sum[0]) >>> 34;
                        sum[0][65] <= 1'b0;
                    end

                    if (mul2[3:1] == 3'b011 || mul2[3:1] == 3'b100) begin
                        sum[1] = $signed(sum[1]) >>> 31;
                        sum[1][65] <= 1'b0;
                    end else begin
                        sum[1] = $signed(sum[1]) >>> 32;
                        sum[1][65] <= 1'b0;
                    end

                    if (mul2[5:3] == 3'b011 || mul2[5:3] == 3'b100) begin
                        sum[2] = $signed(sum[2]) >>> 29;
                        sum[2][65] <= 1'b0;
                    end else begin
                        sum[2] = $signed(sum[2]) >>> 30;
                        sum[2][65] <= 1'b0;
                    end

                    // Code Block 1
                    if (mul2[7:5] == 3'b011 || mul2[7:5] == 3'b100) begin
                        sum[3] = $signed(sum[3]) >>> 27;
                        sum[3][65] <= 1'b0;
                    end else begin
                        sum[3] = $signed(sum[3]) >>> 28;
                        sum[3][65] <= 1'b0;
                    end

                    // Code Block 2
                    if (mul2[9:7] == 3'b011 || mul2[9:7] == 3'b100) begin
                        sum[4] = $signed(sum[4]) >>> 25;
                        sum[4][65] <= 1'b0;
                    end else begin
                        sum[4] = $signed(sum[4]) >>> 26;
                        sum[4][65] <= 1'b0;
                    end

                    // Code Block 3
                    if (mul2[11:9] == 3'b011 || mul2[11:9] == 3'b100) begin
                        sum[5] = $signed(sum[5]) >>> 23;
                        sum[5][65] <= 1'b0;
                    end else begin
                        sum[5] = $signed(sum[5]) >>> 24;
                        sum[5][65] <= 1'b0;
                    end

                    // Code Block 4
                    if (mul2[13:11] == 3'b011 || mul2[13:11] == 3'b100) begin
                        sum[6] = $signed(sum[6]) >>> 21;
                        sum[6][65] <= 1'b0;
                    end else begin
                        sum[6] = $signed(sum[6]) >>> 22;
                        sum[6][65] <= 1'b0;
                    end

                    // Code Block 5
                    if (mul2[15:13] == 3'b011 || mul2[15:13] == 3'b100) begin
                        sum[7] = $signed(sum[7]) >>> 19;
                        sum[7][65] <= 1'b0;
                    end else begin
                        sum[7] = $signed(sum[7]) >>> 20;
                        sum[7][65] <= 1'b0;
                    end

                    // Code Block 6
                    if (mul2[17:15] == 3'b011 || mul2[17:15] == 3'b100) begin
                        sum[8] = $signed(sum[8]) >>> 17;
                        sum[8][65] <= 1'b0;
                    end else begin
                        sum[8] = $signed(sum[8]) >>> 18;
                        sum[8][65] <= 1'b0;
                    end

                    // Code Block 7
                    if (mul2[19:17] == 3'b011 || mul2[19:17] == 3'b100) begin
                        sum[9] = $signed(sum[9]) >>> 15;
                        sum[9][65] <= 1'b0;
                    end else begin
                        sum[9] = $signed(sum[9]) >>> 16;
                        sum[9][65] <= 1'b0;
                    end

                    // Code Block 8
                    if (mul2[21:19] == 3'b011 || mul2[21:19] == 3'b100) begin
                        sum[10] = $signed(sum[10]) >>> 13;
                        sum[10][65] <= 1'b0;
                    end else begin
                        sum[10] = $signed(sum[10]) >>> 14;
                        sum[10][65] <= 1'b0;
                    end

                    // Code Block 9
                    if (mul2[23:21] == 3'b011 || mul2[23:21] == 3'b100) begin
                        sum[11] = $signed(sum[11]) >>> 11;
                        sum[11][65] <= 1'b0;
                    end else begin
                        sum[11] = $signed(sum[11]) >>> 12;
                        sum[11][65] <= 1'b0;
                    end

                    // Code Block 10
                    if (mul2[25:23] == 3'b011 || mul2[25:23] == 3'b100) begin
                        sum[12] = $signed(sum[12]) >>> 9;
                        sum[12][65] <= 1'b0;
                    end else begin
                        sum[12] = $signed(sum[12]) >>> 10;
                        sum[12][65] <= 1'b0;
                    end

                    // Code Block 11
                    if (mul2[27:25] == 3'b011 || mul2[27:25] == 3'b100) begin
                        sum[13] = $signed(sum[13]) >>> 7;
                        sum[13][65] <= 1'b0;
                    end else begin
                        sum[13] = $signed(sum[13]) >>> 8;
                        sum[13][65] <= 1'b0;
                    end

                    // Code Block 12
                    if (mul2[29:27] == 3'b011 || mul2[29:27] == 3'b100) begin
                        sum[14] = $signed(sum[14]) >>> 5;
                        sum[14][65] <= 1'b0;
                    end else begin
                        sum[14] = $signed(sum[14]) >>> 6;
                        sum[14][65] <= 1'b0;
                    end

                    // Code Block 13
                    if (mul2[31:29] == 3'b011 || mul2[31:29] == 3'b100) begin
                        sum[15] = $signed(sum[15]) >>> 3;
                        sum[15][65] <= 1'b0;
                    end else begin
                        sum[15] = $signed(sum[15]) >>> 4;
                        sum[15][65] <= 1'b0;
                    end

                    state <= c;
                end

                c: begin
                    result = 0;
                    for (i = 0; i < 16; i = i + 1) begin
                        result = result + sum[i];
                    end
                    // if (result[65] == 1'b1) out = result;
                    // $finish();
                    state <= a;
                end
            endcase
        end
    end

    assign re_mul1 = -mul1;

endmodule
