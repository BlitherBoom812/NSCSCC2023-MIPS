module mul (
    input [31:0] operand1,
    input [31:0] operand2,
    input        clock,
    input        reset,
    input        start,
    input        flag_unsigned,

    output reg [63:0] result = 0,
    output reg        done = 0
);

    reg [2:0] state = 3'b0;

    parameter A = 3'b000;
    parameter B = 3'b001;
    parameter C = 3'b010;
    parameter D = 3'b011;

    always @(posedge clock) begin
        if (reset == `RST_ENABLE) begin
            result <= 0;
            done <= 0;
            state  <= A;
        end else begin
            case (state)
                A: begin
                    done <= 0;
                    if (start) begin
                        if (flag_unsigned) begin
                            result <= $unsigned(operand1) * $unsigned(operand2);
                            state  <= C;
                        end else begin
                            result <= $signed(operand1) * $signed(operand2);
                            state  <= B;
                        end
                    end
                end

                B: state <= C;
                C: state <= D;
                D: begin
                    done  <= 1;
                    state <= A;
                end
                default: state <= A;
            endcase
        end
    end
endmodule
