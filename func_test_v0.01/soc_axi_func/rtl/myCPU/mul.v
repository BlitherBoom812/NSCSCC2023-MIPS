// module mul (
//     input [31:0] operand1,
//     input [31:0] operand2,
//     input        clock,
//     input        reset,
//     input        start,
//     input        flag_unsigned,

//     output reg [63:0] result = 0,
//     output reg        done = 0
// );

//     wire [31:0] re_operand1;
//     reg  [63:0] sum          [15:0];
//     reg  [ 2:0] state = 3'b0;

//     parameter A = 3'b000;
//     parameter B = 3'b001;
//     parameter C = 3'b010;
//     parameter D = 3'b011;

//     always @(posedge clock) begin
//         if (reset == `RST_ENABLE) begin
//             result <= 0;
//             state  <= A;
//         end else begin
//             case (state)
//                 A: begin
//                     if (start == 1'b1) begin
//                         case ({
//                             operand2[1:0], 1'b0
//                         })
//                             3'b011:  sum[0] <= {{31{1'b0}}, operand1, {1{1'b0}}};
//                             3'b001:  sum[0] <= {{32{1'b0}}, operand1, {0{1'b0}}};
//                             3'b010:  sum[0] <= {{32{1'b0}}, operand1, {0{1'b0}}};
//                             3'b100:  sum[0] <= {{31{1'b0}}, re_operand1, {1{1'b0}}};
//                             3'b101:  sum[0] <= {{32{1'b0}}, re_operand1, {0{1'b0}}};
//                             3'b110:  sum[0] <= {{32{1'b0}}, re_operand1, {0{1'b0}}};
//                             default: sum[0] <= 64'b0;
//                         endcase

//                         case (operand2[3:1])
//                             3'b011:  sum[1] <= {{29{1'b0}}, operand1, {3{1'b0}}};
//                             3'b001:  sum[1] <= {{30{1'b0}}, operand1, {2{1'b0}}};
//                             3'b010:  sum[1] <= {{30{1'b0}}, operand1, {2{1'b0}}};
//                             3'b100:  sum[1] <= {{31{1'b0}}, re_operand1, {3{1'b0}}};
//                             3'b101:  sum[1] <= {{30{1'b0}}, re_operand1, {2{1'b0}}};
//                             3'b110:  sum[1] <= {{30{1'b0}}, re_operand1, {2{1'b0}}};
//                             default: sum[1] <= 64'b0;
//                         endcase

//                         case (operand2[5:3])
//                             3'b011:  sum[2] <= {{27{1'b0}}, operand1, {5{1'b0}}};
//                             3'b001:  sum[2] <= {{28{1'b0}}, operand1, {4{1'b0}}};
//                             3'b010:  sum[2] <= {{28{1'b0}}, operand1, {4{1'b0}}};
//                             3'b100:  sum[2] <= {{27{1'b0}}, re_operand1, {5{1'b0}}};
//                             3'b101:  sum[2] <= {{28{1'b0}}, re_operand1, {4{1'b0}}};
//                             3'b110:  sum[2] <= {{28{1'b0}}, re_operand1, {4{1'b0}}};
//                             default: sum[2] <= 64'b0;
//                         endcase

//                         case (operand2[7:5])
//                             3'b011:  sum[3] <= {{25{1'b0}}, operand1, {7{1'b0}}};
//                             3'b001:  sum[3] <= {{26{1'b0}}, operand1, {6{1'b0}}};
//                             3'b010:  sum[3] <= {{26{1'b0}}, operand1, {6{1'b0}}};
//                             3'b100:  sum[3] <= {{25{1'b0}}, re_operand1, {7{1'b0}}};
//                             3'b101:  sum[3] <= {{26{1'b0}}, re_operand1, {6{1'b0}}};
//                             3'b110:  sum[3] <= {{26{1'b0}}, re_operand1, {6{1'b0}}};
//                             default: sum[3] <= 64'b0;
//                         endcase

//                         case (operand2[9:7])
//                             3'b011:  sum[4] <= {{23{1'b0}}, operand1, {9{1'b0}}};
//                             3'b001:  sum[4] <= {{24{1'b0}}, operand1, {8{1'b0}}};
//                             3'b010:  sum[4] <= {{24{1'b0}}, operand1, {8{1'b0}}};
//                             3'b100:  sum[4] <= {{23{1'b0}}, re_operand1, {9{1'b0}}};
//                             3'b101:  sum[4] <= {{24{1'b0}}, re_operand1, {8{1'b0}}};
//                             3'b110:  sum[4] <= {{24{1'b0}}, re_operand1, {8{1'b0}}};
//                             default: sum[4] <= 64'b0;
//                         endcase

//                         case (operand2[11:9])
//                             3'b011:  sum[5] <= {{21{1'b0}}, operand1, {11{1'b0}}};
//                             3'b001:  sum[5] <= {{22{1'b0}}, operand1, {10{1'b0}}};
//                             3'b010:  sum[5] <= {{22{1'b0}}, operand1, {10{1'b0}}};
//                             3'b100:  sum[5] <= {{21{1'b0}}, re_operand1, {11{1'b0}}};
//                             3'b101:  sum[5] <= {{22{1'b0}}, re_operand1, {10{1'b0}}};
//                             3'b110:  sum[5] <= {{22{1'b0}}, re_operand1, {10{1'b0}}};
//                             default: sum[5] <= 64'b0;
//                         endcase

//                         case (operand2[13:11])
//                             3'b011:  sum[6] <= {{19{1'b0}}, operand1, {13{1'b0}}};
//                             3'b001:  sum[6] <= {{20{1'b0}}, operand1, {12{1'b0}}};
//                             3'b010:  sum[6] <= {{20{1'b0}}, operand1, {12{1'b0}}};
//                             3'b100:  sum[6] <= {{19{1'b0}}, re_operand1, {13{1'b0}}};
//                             3'b101:  sum[6] <= {{20{1'b0}}, re_operand1, {12{1'b0}}};
//                             3'b110:  sum[6] <= {{20{1'b0}}, re_operand1, {12{1'b0}}};
//                             default: sum[6] <= 64'b0;
//                         endcase

//                         case (operand2[15:13])
//                             3'b011:  sum[7] <= {{17{1'b0}}, operand1, {15{1'b0}}};
//                             3'b001:  sum[7] <= {{18{1'b0}}, operand1, {14{1'b0}}};
//                             3'b010:  sum[7] <= {{18{1'b0}}, operand1, {14{1'b0}}};
//                             3'b100:  sum[7] <= {{17{1'b0}}, re_operand1, {15{1'b0}}};
//                             3'b101:  sum[7] <= {{18{1'b0}}, re_operand1, {14{1'b0}}};
//                             3'b110:  sum[7] <= {{18{1'b0}}, re_operand1, {14{1'b0}}};
//                             default: sum[7] <= 64'b0;
//                         endcase

//                         case (operand2[17:15])
//                             3'b011:  sum[8] <= {{15{1'b0}}, operand1, {17{1'b0}}};
//                             3'b001:  sum[8] <= {{16{1'b0}}, operand1, {16{1'b0}}};
//                             3'b010:  sum[8] <= {{16{1'b0}}, operand1, {16{1'b0}}};
//                             3'b100:  sum[8] <= {{15{1'b0}}, re_operand1, {17{1'b0}}};
//                             3'b101:  sum[8] <= {{16{1'b0}}, re_operand1, {16{1'b0}}};
//                             3'b110:  sum[8] <= {{16{1'b0}}, re_operand1, {16{1'b0}}};
//                             default: sum[8] <= 64'b0;
//                         endcase

//                         case (operand2[19:17])
//                             3'b011:  sum[9] <= {{13{1'b0}}, operand1, {19{1'b0}}};
//                             3'b001:  sum[9] <= {{14{1'b0}}, operand1, {18{1'b0}}};
//                             3'b010:  sum[9] <= {{14{1'b0}}, operand1, {18{1'b0}}};
//                             3'b100:  sum[9] <= {{13{1'b0}}, re_operand1, {19{1'b0}}};
//                             3'b101:  sum[9] <= {{14{1'b0}}, re_operand1, {18{1'b0}}};
//                             3'b110:  sum[9] <= {{14{1'b0}}, re_operand1, {18{1'b0}}};
//                             default: sum[9] <= 64'b0;
//                         endcase

//                         case (operand2[21:19])
//                             3'b011:  sum[10] <= {{11{1'b0}}, operand1, {21{1'b0}}};
//                             3'b001:  sum[10] <= {{12{1'b0}}, operand1, {20{1'b0}}};
//                             3'b010:  sum[10] <= {{12{1'b0}}, operand1, {20{1'b0}}};
//                             3'b100:  sum[10] <= {{11{1'b0}}, re_operand1, {21{1'b0}}};
//                             3'b101:  sum[10] <= {{12{1'b0}}, re_operand1, {20{1'b0}}};
//                             3'b110:  sum[10] <= {{12{1'b0}}, re_operand1, {20{1'b0}}};
//                             default: sum[10] <= 64'b0;
//                         endcase

//                         case (operand2[23:21])
//                             3'b011:  sum[11] <= {{9{1'b0}}, operand1, {23{1'b0}}};
//                             3'b001:  sum[11] <= {{10{1'b0}}, operand1, {22{1'b0}}};
//                             3'b010:  sum[11] <= {{10{1'b0}}, operand1, {22{1'b0}}};
//                             3'b100:  sum[11] <= {{9{1'b0}}, re_operand1, {23{1'b0}}};
//                             3'b101:  sum[11] <= {{10{1'b0}}, re_operand1, {22{1'b0}}};
//                             3'b110:  sum[11] <= {{10{1'b0}}, re_operand1, {22{1'b0}}};
//                             default: sum[11] <= 64'b0;
//                         endcase

//                         case (operand2[25:23])
//                             3'b011:  sum[12] <= {{7{1'b0}}, operand1, {25{1'b0}}};
//                             3'b001:  sum[12] <= {{8{1'b0}}, operand1, {24{1'b0}}};
//                             3'b010:  sum[12] <= {{8{1'b0}}, operand1, {24{1'b0}}};
//                             3'b100:  sum[12] <= {{7{1'b0}}, re_operand1, {25{1'b0}}};
//                             3'b101:  sum[12] <= {{8{1'b0}}, re_operand1, {24{1'b0}}};
//                             3'b110:  sum[12] <= {{8{1'b0}}, re_operand1, {24{1'b0}}};
//                             default: sum[12] <= 64'b0;
//                         endcase

//                         case (operand2[27:25])
//                             3'b011:  sum[13] <= {{5{1'b0}}, operand1, {27{1'b0}}};
//                             3'b001:  sum[13] <= {{6{1'b0}}, operand1, {26{1'b0}}};
//                             3'b010:  sum[13] <= {{6{1'b0}}, operand1, {26{1'b0}}};
//                             3'b100:  sum[13] <= {{5{1'b0}}, re_operand1, {27{1'b0}}};
//                             3'b101:  sum[13] <= {{6{1'b0}}, re_operand1, {26{1'b0}}};
//                             3'b110:  sum[13] <= {{6{1'b0}}, re_operand1, {26{1'b0}}};
//                             default: sum[13] <= 64'b0;
//                         endcase

//                         case (operand2[29:27])
//                             3'b011:  sum[14] <= {{3{1'b0}}, operand1, {29{1'b0}}};
//                             3'b001:  sum[14] <= {{4{1'b0}}, operand1, {28{1'b0}}};
//                             3'b010:  sum[14] <= {{4{1'b0}}, operand1, {28{1'b0}}};
//                             3'b100:  sum[14] <= {{3{1'b0}}, re_operand1, {29{1'b0}}};
//                             3'b101:  sum[14] <= {{4{1'b0}}, re_operand1, {28{1'b0}}};
//                             3'b110:  sum[14] <= {{4{1'b0}}, re_operand1, {28{1'b0}}};
//                             default: sum[14] <= 64'b0;
//                         endcase

//                         case (operand2[31:29])
//                             3'b011:  sum[15] <= {{1{1'b0}}, operand1, {31{1'b0}}};
//                             3'b001:  sum[15] <= {{2{1'b0}}, operand1, {30{1'b0}}};
//                             3'b010:  sum[15] <= {{2{1'b0}}, operand1, {30{1'b0}}};
//                             3'b100:  sum[15] <= {{1{1'b0}}, re_operand1, {31{1'b0}}};
//                             3'b101:  sum[15] <= {{2{1'b0}}, re_operand1, {30{1'b0}}};
//                             3'b110:  sum[15] <= {{2{1'b0}}, re_operand1, {30{1'b0}}};
//                             default: sum[15] <= 64'b0;
//                         endcase

//                         if (flag_unsigned) state <= C;
//                         else state <= B;

//                     end
//                     done <= 0;
//                 end

//                 B: begin
//                     if ({operand2[1:0], 1'b0} == 3'b011 || {operand2[1:0], 1'b0} == 3'b100)
//                         if (sum[0][32] == 1'b1) sum[0][63:33] <= {31{1'b1}};
//                         else;
//                     else if (sum[0][31] == 1'b1) sum[0][63:32] <= {32{1'b1}};

//                     if (operand2[3:1] == 3'b011 || operand2[3:1] == 3'b100)
//                         if (sum[1][34] == 1'b1) sum[1][63:35] <= {29{1'b1}};
//                         else;
//                     else if (sum[1][33] == 1'b1) sum[1][63:34] <= {30{1'b1}};

//                     if (operand2[5:3] == 3'b011 || operand2[5:3] == 3'b100)
//                         if (sum[2][36] == 1'b1) sum[2][63:37] <= {27{1'b1}};
//                         else;
//                     else if (sum[2][35] == 1'b1) sum[2][63:36] <= {28{1'b1}};

//                     if (operand2[7:5] == 3'b011 || operand2[7:5] == 3'b100)
//                         if (sum[3][38] == 1'b1) sum[3][63:39] <= {25{1'b1}};
//                         else;
//                     else if (sum[3][37] == 1'b1) sum[3][63:38] <= {26{1'b1}};

//                     if (operand2[9:7] == 3'b011 || operand2[9:7] == 3'b100)
//                         if (sum[4][40] == 1'b1) sum[4][63:41] <= {23{1'b1}};
//                         else;
//                     else if (sum[4][39] == 1'b1) sum[4][63:40] <= {24{1'b1}};

//                     if (operand2[11:9] == 3'b011 || operand2[11:9] == 3'b100)
//                         if (sum[5][42] == 1'b1) sum[5][63:43] <= {21{1'b1}};
//                         else;
//                     else if (sum[5][41] == 1'b1) sum[5][63:42] <= {22{1'b1}};

//                     if (operand2[13:11] == 3'b011 || operand2[13:11] == 3'b100)
//                         if (sum[6][44] == 1'b1) sum[6][63:45] <= {19{1'b1}};
//                         else;
//                     else if (sum[6][43] == 1'b1) sum[6][63:44] <= {20{1'b1}};

//                     if (operand2[15:13] == 3'b011 || operand2[15:13] == 3'b100)
//                         if (sum[7][46] == 1'b1) sum[7][63:47] <= {17{1'b1}};
//                         else;
//                     else if (sum[7][45] == 1'b1) sum[7][63:46] <= {18{1'b1}};

//                     if (operand2[17:15] == 3'b011 || operand2[17:15] == 3'b100)
//                         if (sum[8][48] == 1'b1) sum[8][63:49] <= {15{1'b1}};
//                         else;
//                     else if (sum[8][47] == 1'b1) sum[8][63:48] <= {16{1'b1}};

//                     if (operand2[19:17] == 3'b011 || operand2[19:17] == 3'b100)
//                         if (sum[9][50] == 1'b1) sum[9][63:51] <= {13{1'b1}};
//                         else;
//                     else if (sum[9][49] == 1'b1) sum[9][63:50] <= {14{1'b1}};

//                     if (operand2[21:19] == 3'b011 || operand2[21:19] == 3'b100)
//                         if (sum[10][52] == 1'b1) sum[10][63:53] <= {11{1'b1}};
//                         else;
//                     else if (sum[10][51] == 1'b1) sum[10][63:52] <= {12{1'b1}};

//                     if (operand2[23:21] == 3'b011 || operand2[23:21] == 3'b100)
//                         if (sum[11][54] == 1'b1) sum[11][63:55] <= {9{1'b1}};
//                         else;
//                     else if (sum[11][53] == 1'b1) sum[11][63:54] <= {10{1'b1}};

//                     if (operand2[25:23] == 3'b011 || operand2[25:23] == 3'b100)
//                         if (sum[12][56] == 1'b1) sum[12][63:57] <= {7{1'b1}};
//                         else;
//                     else if (sum[12][55] == 1'b1) sum[12][63:56] <= {8{1'b1}};

//                     if (operand2[27:25] == 3'b011 || operand2[27:25] == 3'b100)
//                         if (sum[13][58] == 1'b1) sum[13][63:59] <= {5{1'b1}};
//                         else;
//                     else if (sum[13][57] == 1'b1) sum[13][63:58] <= {6{1'b1}};

//                     if (operand2[29:27] == 3'b011 || operand2[29:27] == 3'b100)
//                         if (sum[14][60] == 1'b1) sum[14][63:61] <= {3{1'b1}};
//                         else;
//                     else if (sum[14][59] == 1'b1) sum[14][63:60] <= {4{1'b1}};

//                     if (operand2[31:29] == 3'b011 || operand2[31:29] == 3'b100)
//                         if (sum[15][62] == 1'b1) sum[15][63] <= 1'b1;
//                         else;
//                     else if (sum[15][61] == 1'b1) sum[15][63:62] <= {2{1'b1}};

//                     state <= C;
//                 end

//                 C: begin

//                     sum[0] <= sum[0] + sum[1] + sum[2] + sum[3];
//                     sum[1] <= sum[4] + sum[5] + sum[6] + sum[7];
//                     sum[2] <= sum[8] + sum[9] + sum[10] + sum[11];
//                     sum[3] <= sum[12] + sum[13] + sum[14] + sum[15];
//                     state  <= D;

//                 end

//                 D: begin

//                     result <= sum[0] + sum[1] + sum[2] + sum[3];
//                     done   <= 1;
//                     state  <= A;

//                 end


//             endcase
//         end
//     end

//     assign re_operand1 = -operand1;

// endmodule
