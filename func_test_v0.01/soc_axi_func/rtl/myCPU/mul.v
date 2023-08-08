module mul(
input [31:0] operand1,
input [31:0] operand2,
input clock,
input reset,
input start,
input flag_unsigned,

output reg [63:0] result = 0,
output reg done = 0
);

wire [63:0] ex_op1; 
wire [63:0] ex_op1_signed;
wire [63:0] ex_op1_unsigned;
wire [63:0] re_op1;
wire [63:0] result_0;
wire [63:0] result_1;
wire [63:0] result_2;
wire [63:0] result_3;
reg [63:0] sum [15:0];
reg state = 0;

parameter A = 1'b0;
parameter B = 1'b1;

always@(posedge clock) begin
    if (~reset) begin
        result <= 0;
        state <= A;
    end
    else begin
        case(state)
        A:begin
            if(start == 1'b1) begin
                case ({operand2[1:0],1'b0})
                    3'b011: sum[0] <= ex_op1 << 1   ;
                    3'b001: sum[0] <= ex_op1;
                    3'b010: sum[0] <= ex_op1;
                    3'b100: sum[0] <= re_op1 << 1;
                    3'b101: sum[0] <= re_op1;
                    3'b110: sum[0] <= re_op1;
                    default: sum[0] <= 64'b0;
                endcase
                
                case (operand2[3:1])
                    3'b011: sum[1] <= ex_op1 << 3   ;
                    3'b001: sum[1] <= ex_op1 << 2   ;
                    3'b010: sum[1] <= ex_op1 << 2   ;
                    3'b100: sum[1] <= re_op1 << 3   ;
                    3'b101: sum[1] <= re_op1 << 2   ;
                    3'b110: sum[1] <= re_op1 << 2   ;
                    default: sum[1] <= 64'b0;
                endcase

                case (operand2[5:3])
                    3'b011: sum[2] <= ex_op1 << 5   ;
                    3'b001: sum[2] <= ex_op1 << 4   ;
                    3'b010: sum[2] <= ex_op1 << 4   ;
                    3'b100: sum[2] <= re_op1 << 5   ;
                    3'b101: sum[2] <= re_op1 << 4   ;
                    3'b110: sum[2] <= re_op1 << 4   ;
                    default: sum[2] <= 64'b0;
                endcase

                case (operand2[7:5])
                    3'b011: sum[3] <= ex_op1 << 7   ;
                    3'b001: sum[3] <= ex_op1 << 6   ;
                    3'b010: sum[3] <= ex_op1 << 6   ;
                    3'b100: sum[3] <= re_op1 << 7   ;
                    3'b101: sum[3] <= re_op1 << 6   ;
                    3'b110: sum[3] <= re_op1 << 6   ;
                    default: sum[3] <= 64'b0;
                endcase

                case (operand2[9:7])
                    3'b011: sum[4] <= ex_op1 << 9   ;
                    3'b001: sum[4] <= ex_op1 << 8   ;
                    3'b010: sum[4] <= ex_op1 << 8   ;
                    3'b100: sum[4] <= re_op1 << 9   ;
                    3'b101: sum[4] <= re_op1 << 8   ;
                    3'b110: sum[4] <= re_op1 << 8   ;
                    default: sum[4] <= 64'b0;
                endcase

                case (operand2[11:9])
                    3'b011: sum[5] <= ex_op1 << 11   ;
                    3'b001: sum[5] <= ex_op1 << 10   ;
                    3'b010: sum[5] <= ex_op1 << 10   ;
                    3'b100: sum[5] <= re_op1 << 11   ;
                    3'b101: sum[5] <= re_op1 << 10   ;
                    3'b110: sum[5] <= re_op1 << 10   ;
                    default: sum[5] <= 64'b0;
                endcase

                case (operand2[13:11])
                    3'b011: sum[6] <= ex_op1 << 13   ;
                    3'b001: sum[6] <= ex_op1 << 12   ;
                    3'b010: sum[6] <= ex_op1 << 12   ;
                    3'b100: sum[6] <= re_op1 << 13   ;
                    3'b101: sum[6] <= re_op1 << 12   ;
                    3'b110: sum[6] <= re_op1 << 12   ;
                    default: sum[6] <= 64'b0;
                endcase

                case (operand2[15:13])
                    3'b011: sum[7] <= ex_op1 << 15  ;
                    3'b001: sum[7] <= ex_op1 << 14  ;
                    3'b010: sum[7] <= ex_op1 << 14  ;
                    3'b100: sum[7] <= re_op1 << 15  ;
                    3'b101: sum[7] <= re_op1 << 14  ;
                    3'b110: sum[7] <= re_op1 << 14  ;
                    default: sum[7] <= 64'b0;
                endcase

                case (operand2[17:15])
                    3'b011: sum[8] <= ex_op1 << 17  ;
                    3'b001: sum[8] <= ex_op1 << 16  ;
                    3'b010: sum[8] <= ex_op1 << 16  ;
                    3'b100: sum[8] <= re_op1 << 17  ;
                    3'b101: sum[8] <= re_op1 << 16  ;
                    3'b110: sum[8] <= re_op1 << 16  ;
                    default: sum[8] <= 64'b0;
                endcase

                case (operand2[19:17])
                    3'b011: sum[9] <= ex_op1 << 19  ;
                    3'b001: sum[9] <= ex_op1 << 18  ;
                    3'b010: sum[9] <= ex_op1 << 18  ;
                    3'b100: sum[9] <= re_op1 << 19  ;
                    3'b101: sum[9] <= re_op1 << 18  ;
                    3'b110: sum[9] <= re_op1 << 18  ;
                    default: sum[9] <= 64'b0;
                endcase

                case (operand2[21:19])
                    3'b011: sum[10] <= ex_op1 << 21 ;
                    3'b001: sum[10] <= ex_op1 << 20 ;
                    3'b010: sum[10] <= ex_op1 << 20 ;
                    3'b100: sum[10] <= re_op1 << 21 ;
                    3'b101: sum[10] <= re_op1 << 20 ;
                    3'b110: sum[10] <= re_op1 << 20 ;
                    default: sum[10] <= 64'b0;
                endcase

                case (operand2[23:21])
                    3'b011: sum[11] <= ex_op1 << 23 ;
                    3'b001: sum[11] <= ex_op1 << 22 ;
                    3'b010: sum[11] <= ex_op1 << 22 ;
                    3'b100: sum[11] <= re_op1 << 23 ;
                    3'b101: sum[11] <= re_op1 << 22 ;
                    3'b110: sum[11] <= re_op1 << 22 ;
                    default: sum[11] <= 64'b0;
                endcase

                case (operand2[25:23])
                    3'b011: sum[12] <= ex_op1 << 25 ;
                    3'b001: sum[12] <= ex_op1 << 24 ;
                    3'b010: sum[12] <= ex_op1 << 24 ;
                    3'b100: sum[12] <= re_op1 << 25 ;
                    3'b101: sum[12] <= re_op1 << 24 ;
                    3'b110: sum[12] <= re_op1 << 24 ;
                    default: sum[12] <= 64'b0;
                endcase

                case (operand2[27:25])
                    3'b011: sum[13] <= ex_op1 << 27 ;
                    3'b001: sum[13] <= ex_op1 << 26 ;
                    3'b010: sum[13] <= ex_op1 << 26 ;
                    3'b100: sum[13] <= re_op1 << 27 ;
                    3'b101: sum[13] <= re_op1 << 26 ;
                    3'b110: sum[13] <= re_op1 << 26 ;
                    default: sum[13] <= 64'b0;
                endcase

                case (operand2[29:27])
                    3'b011: sum[14] <= ex_op1 << 29 ;
                    3'b001: sum[14] <= ex_op1 << 28 ;
                    3'b010: sum[14] <= ex_op1 << 28 ;
                    3'b100: sum[14] <= re_op1 << 29 ;
                    3'b101: sum[14] <= re_op1 << 28 ;
                    3'b110: sum[14] <= re_op1 << 28 ;
                    default: sum[14] <= 64'b0;
                endcase

                case (operand2[31:29])
                    3'b011: sum[15] <= ex_op1 << 31 ;
                    3'b001: sum[15] <= ex_op1 << 30 ;
                    3'b010: sum[15] <= ex_op1 << 30 ;
                    3'b100: sum[15] <= re_op1 << 31 ;
                    3'b101: sum[15] <= re_op1 << 30 ;
                    3'b110: sum[15] <= re_op1 << 30 ;
                    default: sum[15] <= 64'b0;
                endcase


                state <= B;
            end
            done <= 0;

        end

        B:begin
            if(flag_unsigned && operand2[31] == 1'b1) result <= result_0 + result_1 + result_2 + result_3 + (ex_op1 << 32);
            else result <= result_0 + result_1 + result_2 + result_3;
            done <= 1;
            state <= A;

        end


        endcase
    end
end

assign ex_op1_unsigned  = { operand1, {32{1'b0}} } >> 32;
assign ex_op1_signed    = $signed({ operand1, {32{1'b0}} }) >>> 32;
assign ex_op1 = flag_unsigned ? ex_op1_unsigned: ex_op1_signed; 
assign re_op1 = -ex_op1;
assign result_0 = sum[0]+sum[1]+sum[2]+sum[3];
assign result_1 = sum[4]+sum[5]+sum[6]+sum[7];
assign result_2 = sum[8]+sum[9]+sum[10]+sum[11];
assign result_3 = sum[12]+sum[13]+sum[14]+sum[15];

endmodule