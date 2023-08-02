// 将inst_cache和data_cache的读端口合并为一个axi接口
`include "cache_config.vh"

module axi_cache_merge (
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
    output        rready_o
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

endmodule
