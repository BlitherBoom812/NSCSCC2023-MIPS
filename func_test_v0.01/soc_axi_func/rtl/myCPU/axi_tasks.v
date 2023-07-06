/*
axi_state 有9种状态，可以被外部直接访问，用于判断是否完成。

read 的最终状态为 read_data_finish，write 的最终状态为 write_data_response。

端口必须以s/m_[port_name]的形式命名

读和写都是burst模式，每次读写16个字，每个字4个字节，总共64个字节。后续会添加修改参数功能。

example：
    // main
    parameter write_prepare = 0;
    parameter write = 1;
    parameter read_prepare = 2;
    parameter read = 3;
    parameter main_end = 4;

    `include "axi_tasks.v"

    reg [7:0] main_state = write_prepare;
    reg [31:0] main_read_data = 32'h0000_0000;

    begin
        always @(posedge aclk) begin
            case (main_state)
                write_prepare: begin
                    axi_state <= write_data_prepare;
                    my_awaddr <= 32'h0000_0000;
                    my_wdata <= 32'h1234_5678;  // set your first data
                    main_state <= write;
                end
                write: begin
                    if (axi_state == write_data_wait) begin
                        my_wdata <= my_wdata + 1;   //set your other data here
                    end
                    axi_write_data();
                    if (axi_state == write_data_response) begin
                  
                        main_state <= read_prepare;
                    end
                end
                read_prepare: begin
                    axi_state <= read_data_prepare;  
                    my_araddr <= 32'h0000_0000;
                    main_state <= read;
                end
                read: begin
                    axi_read_data();
                    if (axi_state == read_data_wait) begin
                        if (rvalid == 1'b1) begin
                            $display("main_read_data: %h", rdata);
                        end
                    end else if (axi_state == read_data_finish) begin
                        main_state <= main_end;
                    end 
                end
                main_end:
                    ;
                default: 
                    ;
            endcase
        end
    end
*/

`define _DEBUG

`define LOG(a)  \
    `ifdef DEBUG \
        $display(a); \
    `endif

parameter read_data_prepare = 0;
parameter read_data_addr = 1;
parameter read_data_wait = 2;
parameter read_data_finish = 3;
parameter write_data_prepare = 4;
parameter write_data_addr = 5;
parameter write_data_wait = 6;
parameter write_data_finish = 7; 
parameter write_data_response = 8;

reg [7: 0] axi_state = write_data_prepare;

// reg 赋值规则： state转移时将当前状态的变量重置，将下一状态的变量初始化

// write data by axi burst
reg my_awvalid = 1'b0;
reg my_wlast = 1'b0;
reg my_wvalid = 1'b0;
reg [31:0] my_wdata = 32'h1234_5678;
reg [31:0] my_awaddr = 32'h0000_0001;
reg [7:0] my_wdata_count = 8'h00;
// aw

assign awid = 4'b0000;
assign awaddr = my_awaddr;
assign awlen = 4'hf;   // 16 words in total
assign awsize = 3'b010; // 4 Bytes = 32 bits
assign awburst = 2'b10; 
assign awlock = 2'b00;
assign awcache = 4'b0000;
assign awprot = 3'b000;
assign awvalid = my_awvalid;
// w
assign wid = 4'b0000;
assign wdata = my_wdata;
assign wstrb = 4'b1111;
assign wlast = my_wlast;
assign wvalid = my_wvalid;
// b
assign bready = 1'b1;

// read data by axi burst
reg [31:0] my_araddr = 32'h0000_0001;
reg my_arvalid = 1'b0;
reg [7:0] my_rdata_count = 8'h00;
reg my_rready = 1'b0;
// ar
assign arid = 4'b0000;
assign araddr = my_araddr;
assign arlen = 4'hf;   // 16 words in total
assign arsize = 3'b010; // 4 Bytes = 32 bits
assign arburst = 2'b10; 
assign arlock = 2'b00;
assign arcache = 4'b0000;
assign arprot = 3'b000;
assign arvalid = my_arvalid;
// r
assign rready = 1'b1;

task automatic axi_read_data();
    begin
        case (axi_state)
            read_data_prepare: begin
                my_arvalid <= 1'b1;
                axi_state <= read_data_addr;
                `LOG("read_data_addr");
            end
            read_data_addr: begin
                if(arready == 1'b1) begin
                    my_arvalid <= 1'b0;
                    axi_state <= read_data_wait;
                    `LOG("read_data_wait");
                end else begin
                    my_arvalid <= 1'b1;
                end
            end
            read_data_wait: begin
                if(rvalid == 1'b1) begin
                    my_rdata_count <= my_rdata_count + 1;
                    `ifdef DEBUG
                        $display("read_data[%h]: %h", my_rdata_count, rdata);
                    `endif
                end
                if(rlast == 1'b1) begin
                    axi_state <= read_data_finish;
                    `LOG("read_data_finish");
                end
            end
            read_data_finish:
                ;
            default :
                ;
        endcase
    end
endtask

task axi_write_data();
    begin
        case (axi_state)
            write_data_prepare: begin
                my_awvalid <= 1'b1;
                axi_state <= write_data_addr;
                `LOG("write_data_addr");
            end 
            write_data_addr: begin
                if(awready == 1'b1) begin
                    my_awvalid <= 1'b0;

                    axi_state <= write_data_wait;

                    my_wvalid <= 1'b1;
                    `LOG("write_data_wait");
                end else begin
                    my_awvalid <= 1'b1;
                end
            end
            write_data_wait:
                begin
                    if(my_wdata_count == 8'h0f) begin
                        my_wvalid <= 1'b0;
                        my_wlast <= 1'b0;
                        my_wdata_count <= 8'h00;

                        `LOG("write_last_data");
                        if(wready == 1'b1) begin
                            `ifdef DEBUG
                                $display("write_data[%h]: %h", my_wdata_count, my_wdata);
                            `endif
                        end
                        
                        axi_state <= write_data_finish;
                        `LOG("write_data_finish");
                    end else if(my_wdata_count == 8'h0e) begin
                        my_wvalid <= 1'b1;
                        my_wlast <= 1'b1;
                        if(wready == 1'b1) begin
                            `ifdef DEBUG
                                $display("write_data[%h]: %h", my_wdata_count, my_wdata);
                            `endif
                            my_wdata_count <= my_wdata_count + 1;
                        end
                    end
                    else begin
                        my_wvalid <= 1'b1;
                        my_wlast <= 1'b0;
                        if(wready == 1'b1) begin
                            `ifdef DEBUG
                                $display("write_data[%h]: %h", my_wdata_count, my_wdata);
                            `endif
                            my_wdata_count <= my_wdata_count + 1;
                        end
                    end
                end
            write_data_finish: begin
                if(bvalid == 1'b1) begin
                    if (bresp == 1'b0) begin
                        axi_state <= write_data_response;
                    end
                end
            end
            write_data_response: 
                ;
            default:
                ;
        endcase
    end
endtask
