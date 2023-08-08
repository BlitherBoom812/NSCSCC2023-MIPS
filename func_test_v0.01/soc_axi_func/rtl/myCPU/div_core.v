/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Non-restoring unsigned divider                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: div_uu.v,v 1.3 2003-09-17 13:08:53 rherveille Exp $
//
//  $Date: 2003-09-17 13:08:53 $
//  $Revision: 1.3 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.2  2002/10/31 13:54:58  rherveille
//               Fixed a bug in the remainder output of div_su.v
//
//               Revision 1.1.1.1  2002/10/29 20:29:10  rherveille

module div_core(
	input 				  		clk, // system clock
	input 				  		ena, // clock enable

	input  [63:0] 				z, // divident
	input  [31:0] 				d, // divisor
	output reg[31:0] 			q, // quotient
	output reg[31:0] 			s, // remainder
	output reg				  	div0,
	output reg               	ovf
);

	reg [31:0] q_pipe  [31:0];
	reg [64:0] s_pipe  [32:0];
	reg [64:0] d_pipe  [32:0];

	reg [32:0] div0_pipe, ovf_pipe;

	reg [64:0] tmp;
	
	// perform parameter checks

	integer n0, n1, n2, n3;

	// generate divisor (d) pipe
	always @(d)
	  d_pipe[0] <= {1'b0, d, {32{1'b0}} };

	always @(posedge clk)
	  if(ena)
	    for(n0=1; n0 <= 32; n0=n0+1)
	       d_pipe[n0] <= d_pipe[n0-1];

	// generate internal remainder pipe
	always @(z)
	  s_pipe[0] <= z;

	always @(posedge clk)
	  if(ena)
	    for(n1=1; n1 <= 32; n1=n1+1) begin
			if(s_pipe[n1-1][64])
				s_pipe[n1] <= {s_pipe[n1-1][63:0], 1'b0} + d_pipe[n1-1];
			else
				s_pipe[n1] <= {s_pipe[n1-1][63:0], 1'b0} - d_pipe[n1-1];
		end

	// generate quotient pipe
	always @(posedge clk)
	  q_pipe[0] <= 0;

	always @(posedge clk)
	  if(ena)
	    for(n2=1; n2 < 32; n2=n2+1) begin
			q_pipe[n2] <= {q_pipe[n2-1][30:0], ~s_pipe[n2][64]};
		end

	// flags (divide_by_zero, overflow)
	always @(z or d)
	begin
	  ovf_pipe[0]  <= !(z[63:32] < d);
	  div0_pipe[0] <= ~|d;
	end

	always @(posedge clk)
	  if(ena)
	    for(n3=1; n3 <= 32; n3=n3+1)
	    begin
	        ovf_pipe[n3] <= ovf_pipe[n3-1];
	        div0_pipe[n3] <= div0_pipe[n3-1];
	    end

	// assign outputs
	always @(posedge clk)
	  if(ena)
	    ovf <= ovf_pipe[32];

	always @(posedge clk)
	  if(ena)
	    div0 <= div0_pipe[32];

	always @(posedge clk)
	  if(ena) begin
		q <= {q_pipe[31][30:0], ~s_pipe[32][64]};
	  end

	always @(posedge clk)
	  if(ena) begin
		if(s_pipe[32][64])
			tmp = s_pipe[32] + d_pipe[32];
		else
			tmp = s_pipe[32];
		s <= tmp[63:32];
	  end
endmodule