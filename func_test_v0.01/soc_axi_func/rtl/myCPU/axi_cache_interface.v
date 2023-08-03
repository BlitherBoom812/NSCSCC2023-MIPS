// 将inst_cache和data_cache的读端口合并为一个axi接口
`include "cache_config.vh"

module axi_cache_interface (
    input         inst_cache_ena_i,
    input         data_cache_ena_i,
    input         inst_ren_i,
    input  [31:0] inst_araddr_i,
    input         inst_arvalid_i,
    output        inst_arready_o,
    output [31:0] inst_rdata_o,
    output        inst_rlast_o,
    output        inst_rvalid_o,
    input         inst_rready_i,

    input         data_ren_i,
    input  [31:0] data_araddr_i,
    input         data_arvalid_i,
    output        data_arready_o,
    output [31:0] data_rdata_o,
    output        data_rlast_o,
    output        data_rvalid_o,
    input         data_rready_i,

    //ar
    output [ 3:0] arid_o,
    output [31:0] araddr_o,
    output [ 4:0] arlen_o,
    output [ 2:0] arsize_o,
    output [ 1:0] arburst_o,
    output [ 1:0] arlock_o,
    output [ 3:0] arcache_o,
    output [ 2:0] arprot_o,
    output        arvalid_o,
    input         arready_i,
    //r           
    input  [ 3:0] rid_i,
    input  [31:0] rdata_i,
    input  [ 1:0] rresp_i,
    input         rlast_i,
    input         rvalid_i,
    output        rready_o,

    // aw
    input  [ 3:0] data_awid_i,
    input  [ 7:0] data_awlen_i,
    input  [ 2:0] data_awsize_i,
    input  [ 1:0] data_awburst_i,
    input  [ 1:0] data_awlock_i,
    input  [ 3:0] data_awcache_i,
    input  [ 2:0] data_awprot_i,
    input  [31:0] data_awaddr_i,
    input         data_awvalid_i,
    output        data_awready_o,

    output [ 3:0] awid_o,
    output [ 7:0] awlen_o,
    output [ 2:0] awsize_o,
    output [ 1:0] awburst_o,
    output [ 1:0] awlock_o,
    output [ 3:0] awcache_o,
    output [ 2:0] awprot_o,
    output [31:0] awaddr_o,
    output        awvalid_o,
    input         awready_i,

    // w
    input  [ 3:0] data_wid_i,
    input  [31:0] data_wdata_i,
    input         data_wlast_i,
    input  [ 3:0] data_wstrb_i,
    input         data_wvalid_i,
    output        data_wready_o,

    output [ 3:0] wid_o,
    output [31:0] wdata_o,
    output        wlast_o,
    output [ 3:0] wstrb_o,
    output        wvalid_o,
    input         wready_i,

    // b
    output  data_bvalid_o,
    input data_bready_i,

    input  bvalid_i,
    output bready_o
);

    assign arvalid_o      = data_arvalid_i | inst_arvalid_i;

    assign arlen_o        = inst_ren_i ? (inst_cache_ena_i ? `INST_BURST_NUM : 8'h00) : (data_ren_i ? (data_cache_ena_i ? `DATA_BURST_NUM : 8'h00) : 8'h00);
    assign arid_o         = 4'b0000;
    assign arsize_o       = 3'b010;
    assign arburst_o      = inst_ren_i ? (inst_cache_ena_i ? 2'b01 : 2'b00) : (data_ren_i ? (data_cache_ena_i ? 2'b01 : 2'b00) : 2'b00);
    assign arlock_o       = 2'b00;
    assign arcache_o      = 4'b0000;
    assign arprot_o       = 3'b000;
    assign rready_o       = 1'b1;

    assign araddr_o       = inst_ren_i ? inst_araddr_i : data_araddr_i;

    assign inst_arready_o = inst_ren_i ? arready_i : 1'b0;
    assign data_arready_o = data_ren_i ? arready_i : 1'b0;

    assign inst_rlast_o   = inst_ren_i ? rlast_i : 1'b0;
    assign data_rlast_o   = data_ren_i ? rlast_i : 1'b0;

    assign inst_rdata_o   = inst_ren_i ? rdata_i : 32'b0;
    assign data_rdata_o   = data_ren_i ? rdata_i : 32'b0;

    assign inst_rvalid_o  = inst_ren_i ? rvalid_i : 1'b0;
    assign data_rvalid_o  = data_ren_i ? rvalid_i : 1'b0;

    assign awid_o = data_awid_i;
    assign awlen_o = data_awlen_i;
    assign awsize_o = data_awsize_i;
    assign awburst_o = data_awburst_i;
    assign awlock_o = data_awlock_i;
    assign awcache_o = data_awcache_i;
    assign awprot_o = data_awprot_i;
    assign awaddr_o = data_awaddr_i;
    assign awvalid_o = data_awvalid_i;
    assign data_awready_o = awready_i;

    assign wdata_o = data_wdata_i;
    assign wstrb_o = data_wstrb_i;
    assign wlast_o = data_wlast_i;
    assign wvalid_o = data_wvalid_i;
    assign data_wready_o = awready_i;

    assign data_bvalid_o = bvalid_i;
    assign bready_o = data_bready_i;
    
endmodule
