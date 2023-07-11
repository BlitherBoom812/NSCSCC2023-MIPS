//~ `New testbench
`timescale  1ns / 1ps        

module tb_inst_cache_fifo();   

// inst_cache_fifo Parameters
parameter PERIOD      = 10  ;
parameter IDLE        = 4'd0;
parameter COMP_TAG    = 4'd1;
parameter READ_MEM    = 4'h2;
parameter WRITE_BACK  = 4'h3;

// inst_cache_fifo Inputs
reg   rst                                  = 0 ;
reg   clk                                  = 0 ;
reg   cache_ena                            = 0 ;
reg   m_arready                            = 0 ;
reg   [31:0]  m_rdata                      = 0 ;
reg   m_rlast                              = 0 ;
reg   m_rvalid                             = 0 ;
reg   [31:0]  s_araddr                     = 0 ;
reg   s_arvalid                            = 0 ;
reg   flush                                = 0 ;

// inst_cache_fifo Outputs
wire  [31:0]  m_araddr                     ;
wire  m_arvalid                            ;
wire  m_rready                             ;
wire  [31:0]  s_rdata                      ;
wire  s_rvalid                             ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst  =  1;
    #(PERIOD*2) rst  =  0;
end

inst_cache_fifo #(
    .IDLE       ( IDLE       ),
    .COMP_TAG   ( COMP_TAG   ),
    .READ_MEM   ( READ_MEM   ),
    .WRITE_BACK ( WRITE_BACK ))
 u_inst_cache_fifo (
    .rst                     ( rst               ),
    .clk                     ( clk               ),
    .cache_ena               ( cache_ena         ),
    .m_arready               ( m_arready         ),
    .m_rdata                 ( m_rdata           ),
    .m_rlast                 ( m_rlast           ),
    .m_rvalid                ( m_rvalid          ),
    .s_araddr                ( s_araddr          ),
    .s_arvalid               ( s_arvalid         ),
    .flush                   ( flush             ),

    .m_araddr                ( m_araddr          ),
    .m_arvalid               ( m_arvalid         ),
    .m_rready                ( m_rready          ),
    .s_rdata                 ( s_rdata           ),
    .s_rvalid                ( s_rvalid          )
);

// goal: test icache
// 1. verify testbench by connecting testbench to the original inst cache
// 2. test the new inst cache by connecting testbench to the new inst cache

initial
begin

    #(PERIOD * 1000) $finish();
end

// cpu simulation
reg [3:0] inst_req_count;
reg [2:0] cpu_state;

parameter[2:0] state_idle = 3'b00;
parameter[2:0] state_req = 3'b010;
parameter[2:0] state_wait_inst_read = 3'b011;
parameter[2:0] state_wait_data_read = 3'b100;
parameter[2:0] state_wait_data_write = 3'b101;

initial begin
    cache_ena = 1;    
    inst_req_count = 0;
    cpu_state = state_idle;
    $display("start fetch inst");
end

// read sequence: 0x00000000, 0x00000004, 0x00000008, 0x0000000C, 0x00000010, 0x00000014, 0x00000004, 0x00000014, 0x00000018

task set_s_araddr();
    begin
        case(inst_req_count)
            0: s_araddr <= 32'h00000000;
            1: s_araddr <= 32'h00000004;
            2: s_araddr <= 32'h00000008;
            3: s_araddr <= 32'h0000000C;
            4: s_araddr <= 32'h00000010;
            5: s_araddr <= 32'h00000014;
            6: s_araddr <= 32'h00000004;
            7: s_araddr <= 32'h00000014;
            8: s_araddr <= 32'h00000018;
            default: s_araddr <= 32'h00000000;
        endcase
    end
endtask

always @(posedge clk) begin
    case(cpu_state)
        state_idle: begin
            if (cache_ena == 1'b1) begin
                cpu_state <= state_req;
            end
        end
        state_req: begin
            if (cache_ena == 1'b1) begin
                s_arvalid <= 1'b1;
                set_s_araddr();
                if (s_rvalid == 1'b1) begin
                    cpu_state <= state_wait_data_read;
                end
            end
        end
        state_wait_inst_read: begin
            if (s_rvalid == 1'b1) begin
                $display("fetch inst[%d]: %h", inst_req_count, s_rdata);
                inst_req_count <= inst_req_count + 1;
                cpu_state <= state_idle;
            end
        end
        state_wait_data_read: begin
            if (s_rvalid == 1'b1) begin
                cpu_state <= state_wait_data_write;
            end
        end
        state_wait_data_write: begin
            if (m_rready == 1'b1) begin
                cpu_state <= state_idle;
            end
        end
    endcase
end

// ram simulation
reg [7:0] ram_state;
reg [3:0] send_count; // send 8 words by default;

parameter [7:0] RAM_IDLE = 1;
parameter [7:0] RAM_READ = 2;
parameter [7:0] RAM_WRITE = 3;

initial begin
    ram_state = RAM_IDLE;
    $display("start ram");
end

always @(posedge clk) begin
    case(ram_state)
        RAM_IDLE: begin
            m_arready <= 1'b1;
            if (m_arvalid == 1'b1) begin
                send_count <= 0;
                ram_state <= RAM_READ;
            end
        end
        RAM_READ: begin
            if (m_rready == 1'b1) begin
                m_arready <= 1'b0;
                m_rdata <= {28'hFEDCBA9, send_count};
                if (send_count == 4'h6) begin
                    m_rlast <= 1'b1;
                    m_rvalid <= 1'b1;
                    send_count <= send_count + 1;
                end else if (send_count == 4'h7) begin
                    m_rlast <= 1'b0;
                    m_rvalid <= 1'b0;
                    send_count <= 0;
                    ram_state <= RAM_IDLE;
                end else begin
                    m_rlast <= 1'b0;
                    m_rvalid <= 1'b1;
                    send_count <= send_count + 1;
                end
            end
        end
    endcase 
end

endmodule