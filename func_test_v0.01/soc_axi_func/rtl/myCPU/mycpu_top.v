/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/
/*
Arch:
------------------------------------------------------------------------------------------------------------------------
|                                    [soc_axi_func]                                                                    |
---------------------------------------------------------------------------------------------------                    |
|                                      [mycpu_top]                                                |                    |
|[mips_core]-->--{sram}-->--[sram_interface]-->--{axi}-->--------------[data_cache]-->--{axi}-->--|-->--[main memory]  |
|                                                  \->[inst&data_cache]-[axi_cache_merge]-->{axi}-|-->--/              |
---------------------------------------------------------------------------------------------------                    |
|                                                                                                                      |
------------------------------------------------------------------------------------------------------------------------

NOTE: 1. inst only read, data both read and write.
2. for read, through axi_cache_merge; for write (only data, no need to merge), directly.
*/
module mycpu_top
(
    input  [5 :0] ext_int      , 
    input         aclk         ,
    input         aresetn      ,
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [3 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [3 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       ,
    
    output [31:0] debug_wb_pc       , 
    output [3:0]  debug_wb_rf_wen   ,
    output [4:0]  debug_wb_rf_wnum  ,
    output [31:0] debug_wb_rf_wdata 
);

wire [5 :0] int;

assign int = ext_int;

wire        time_int_out;
wire        flush;

wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_rdata;
wire        inst_stall;

wire        data_sram_ren;
wire [3:0]  data_sram_wen;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire [31:0] data_sram_rdata;
wire        data_stall;

mips_top mips_core(
.clk(aclk),
.rst(aresetn),
.flush(flush),
.interrupt({time_int_out || int[5],int[4:0]}),
.time_int_out(time_int_out),

.inst_sram_addr(inst_sram_addr),
.inst_sram_rdata(inst_sram_rdata),

.data_sram_ren(data_sram_ren),
.data_sram_wen(data_sram_wen),
.data_sram_addr(data_sram_addr),
.data_sram_wdata(data_sram_wdata),
.data_sram_rdata(data_sram_rdata),

.debug_wb_pc(debug_wb_pc),
.debug_wb_wen(debug_wb_rf_wen),
.debug_wb_num(debug_wb_rf_wnum),
.debug_wb_data(debug_wb_rf_wdata),

.inst_stall(inst_stall),
.data_stall(data_stall)
);

wire [31:0] inst_addr;
wire        inst_ren;
wire  	    inst_valid;
wire [31:0] inst_rd;
wire [31:0] data_addr;
wire [3:0]  data_wen;
wire        data_ren;
wire [31:0] data_wd;
wire 	    data_valid;
wire [31:0] data_rd;

wire data_valid_r;
wire data_valid_w;
wire inst_cache_ena;
wire data_cache_ena;
wire is_inst_read;
wire is_data_read;

wire is_flush;

// mips_core 通过 sram_interface 以类sram的形式访问内存。sram_interface输出为axi接口，接入cache模块，cache模块的输出为axi接口
sram_interface sram_interface_module
(
.clk(aclk),
.rst(aresetn),
.flush(flush),

.inst_cpu_addr(inst_sram_addr),
.inst_cpu_rdata(inst_sram_rdata),
.inst_cpu_stall(inst_stall),
    
.data_cpu_addr(data_sram_addr),
.data_cpu_ren(data_sram_ren),
.data_cpu_wen(data_sram_wen),
.data_cpu_wdata(data_sram_wdata),
.data_cpu_rdata(data_sram_rdata),
.data_cpu_stall(data_stall),

.inst_cache_ok(inst_valid),
.inst_cache_rdata(inst_rd),
.inst_cache_addr(inst_addr),
.inst_cache_ren(inst_ren),

.data_cache_read_ok(data_valid_r),
.data_cache_write_ok(data_valid_w),
.data_cache_rdata(data_rd),
.data_cache_addr(data_addr),
.data_cache_wen(data_wen),
.data_cache_ren(data_ren),
.data_cache_wdata(data_wd),

.inst_cache_ena(inst_cache_ena),
.data_cache_ena(data_cache_ena),
.is_inst_read(is_inst_read),
.is_data_read(is_data_read),

.is_flush(is_flush)
);

wire [31:0] inst_cache_bridge_araddr;
wire        inst_cache_bridge_arvalid;
wire        inst_cache_bridge_arready;
wire [31:0] inst_cache_bridge_rdata;
wire        inst_cache_bridge_rlast;
wire        inst_cache_bridge_rvalid;
wire        inst_cache_bridge_rready;

wire [31:0] data_cache_bridge_araddr;
wire        data_cache_bridge_arvalid;
wire        data_cache_bridge_arready;
wire [31:0] data_cache_bridge_rdata;
wire        data_cache_bridge_rlast;
wire        data_cache_bridge_rvalid;
wire        data_cache_bridge_rready;

inst_cache  inst_cache_module(
.rst            (aresetn),
.clk            (aclk),
.flush          (is_flush),
.cache_ena      (inst_cache_ena),
.m_araddr       (inst_cache_bridge_araddr),
.m_arvalid      (inst_cache_bridge_arvalid),
.m_arready      (inst_cache_bridge_arready),

.m_rdata        (inst_cache_bridge_rdata),
.m_rlast        (inst_cache_bridge_rlast),
.m_rvalid       (inst_cache_bridge_rvalid),
.m_rready       (inst_cache_bridge_rready),

.s_araddr       (inst_addr),
.s_arvalid      (inst_ren),
.s_rdata        (inst_rd),
.s_rvalid       (inst_valid)
);

data_cache data_cache_module(
.clk            (aclk),
.rst            (aresetn),
.cache_ena      (data_cache_ena),
.flush          (is_flush),

.m_araddr       (data_cache_bridge_araddr),
.m_arvalid      (data_cache_bridge_arvalid),
.m_arready      (data_cache_bridge_arready),
.m_rdata        (data_cache_bridge_rdata),
.m_rlast        (data_cache_bridge_rlast),
.m_rvalid       (data_cache_bridge_rvalid),
.m_rready       (data_cache_bridge_rready),

.m_awid         (awid),
.m_awlen        (awlen),
.m_awsize       (awsize),
.m_awburst      (awburst),
.m_awlock       (awlock),
.m_awcache      (awcache),
.m_awprot       (awprot),         
.m_awaddr       (awaddr),
.m_awvalid      (awvalid),
.m_awready      (awready),
 
.m_wid          (wid),
.m_wdata        (wdata),
.m_wstrb        (wstrb),
.m_wlast        (wlast),
.m_wvalid       (wvalid),
.m_wready       (wready),
              
.m_bvalid       (bvalid),
.m_bready       (bready),
             
.s_addr         (data_addr),
.s_arvalid      (data_ren),
.s_rdata        (data_rd),
.s_rvalid       (data_valid_r),
.s_wdata        (data_wd),
.s_awvalid      (data_wen),
.s_wready       (data_valid_w)
);

axi_cache_merge axi_cache_merge_module(
.inst_cache_ena(inst_cache_ena),
.data_cache_ena(data_cache_ena),
.inst_ren	   (is_inst_read),
.inst_araddr   (inst_cache_bridge_araddr),
.inst_arvalid  (inst_cache_bridge_arvalid),
.inst_arready  (inst_cache_bridge_arready),         
.inst_rdata    (inst_cache_bridge_rdata),
.inst_rlast    (inst_cache_bridge_rlast),
.inst_rready   (inst_cache_bridge_rready),
.inst_rvalid   (inst_cache_bridge_rvalid),

.data_ren	   (is_data_read),
.data_araddr   (data_cache_bridge_araddr),
.data_arvalid  (data_cache_bridge_arvalid),
.data_arready  (data_cache_bridge_arready),         
.data_rdata    (data_cache_bridge_rdata),
.data_rlast    (data_cache_bridge_rlast),
.data_rready   (data_cache_bridge_rready),
.data_rvalid   (data_cache_bridge_rvalid),

.arid          (arid),
.araddr        (araddr),
.arlen         (arlen),
.arsize        (arsize),
.arburst       (arburst),
.arlock        (arlock),
.arcache       (arcache),
.arprot        (arprot),
.arvalid       (arvalid),
.arready       (arready),
               
.rid           (rid),
.rdata         (rdata),
.rresp         (rresp),
.rlast         (rlast),
.rvalid        (rvalid),
.rready        (rready)
);

endmodule