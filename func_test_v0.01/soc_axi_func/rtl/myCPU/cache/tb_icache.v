//~ `New testbench
`timescale  1ns / 1ps        
`include "../defines.v"

`define LINE_OFFSET_WIDTH 6 // For inst_cache_fifo is 6 (2^6 Bytes = 64 Bytes = 16 words per line); For my_ICache, is 5 (2^5 Bytes = 32 Bytes = 8 words per line)

module tb_inst_cache_fifo();   

// top parameters
parameter [6:0] SEND_NUM = 15;

// inst_cache_fifo Parameters
parameter PERIOD      = 10  ;

// inst_cache_fifo Inputs
reg   rst                                  = `RST_DISABLE ;
reg   clk                                  = 0 ;
reg   cache_ena                            = 0 ;
reg   m_arready                            = 0 ;
reg   [31:0]  m_rdata                      = 0 ;
reg   m_rlast                              = 0 ;
reg   m_rvalid                             = 0 ;
reg   [31:0]  s_araddr                     = 0 ;    // request addr from cpu
reg   s_arvalid                            = 0 ;
reg   flush                                = 0 ;

// inst_cache_fifo Outputs
wire  [31:0]  m_araddr                     ;    // request addr to ram
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
    #(PERIOD*2) rst  =  `RST_ENABLE;
    #(PERIOD*2) rst  =  `RST_DISABLE;
end

inst_cache_fifo u_inst_cache_fifo (
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
    s_arvalid = 0;
    flush = 0;
    cpu_state = state_idle;
end

task set_s_araddr();
    begin
        case(inst_req_count)
            0: s_araddr <= 32'h00000000;
            1: s_araddr <= 32'h00000004;
            2: s_araddr <= 32'h00000008;
            3: s_araddr <= 32'h0000004C;
            4: s_araddr <= 32'h00000080;
            5: s_araddr <= 32'h00000044;
            6: s_araddr <= 32'h00000084;
            7: s_araddr <= 32'h00000014;
            8: s_araddr <= 32'h00000018;
            default: s_araddr <= 32'h00000000;
        endcase
    end
endtask

always @(posedge clk) begin
    if (rst == `RST_ENABLE) begin
        cache_ena <= 1;    
        inst_req_count <= 0;
        s_arvalid <= 0;
        flush <= 0;
        m_arready <= 0;
        cpu_state <= state_idle;
        $display("start fetch inst");
    end else begin
        case(cpu_state)
            state_idle: begin
                s_arvalid <= 1'b0;
                if (inst_req_count == 9) begin
                    $display("fetch inst done");
                    $finish;
                end else begin
                    cpu_state <= state_req;
                end
            end
            state_req: begin
                s_arvalid <= 1'b1;
                set_s_araddr();
                cpu_state <= state_wait_inst_read;
            end
            state_wait_inst_read: begin
                s_arvalid <= 1'b0;
                if (s_rvalid == 1'b1) begin
                    $display("fetch inst[%h]: %h", s_araddr, s_rdata);
                    inst_req_count <= inst_req_count + 1;
                    cpu_state <= state_idle;
                end
            end
        endcase
    end
end

// ram simulation
reg [7:0] ram_state;
reg [`LINE_OFFSET_WIDTH-1:0] send_count; 
reg [31:0] m_araddr_reg;    // store the address of the current read request
parameter [7:0] RAM_IDLE = 1;
parameter [7:0] RAM_READ = 2;
parameter [7:0] RAM_WRITE = 3;

initial begin
    ram_state = RAM_IDLE;
    m_arready = 0;
    m_rlast = 0;
    m_rvalid = 0;
    send_count = 0;
end

always @(posedge clk) begin
    if (rst == `RST_ENABLE) begin
        ram_state <= RAM_IDLE;
        m_arready <= 0;
        m_rlast <= 0;
        m_rvalid <= 0;
        send_count <= 0;
        $display("start ram");
    end else begin
        case(ram_state)
            RAM_IDLE: begin
                if (m_arvalid == 1'b1) begin
                    m_arready <= 1'b1;
                    send_count <= 0;
                    ram_state <= RAM_READ;
                    m_araddr_reg <= m_araddr;
                end
            end
            RAM_READ: begin
                if (m_arvalid == 1'b0) begin
                    m_arready <= 1'b0;
                    m_rdata <= {m_araddr_reg[31:`LINE_OFFSET_WIDTH], send_count << 2};
                    if (send_count == SEND_NUM) begin
                        m_rlast <= 1'b1;
                        m_rvalid <= 1'b1;
                        send_count <= send_count + 1;
                    end else if (send_count == SEND_NUM + 1) begin
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
end

endmodule