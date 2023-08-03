// pc -> postif -> postif_id -> id
// pc: set inst request
// postif: pass signals and data
// postif_id: wait inst read, handshake with cache
// id: inst decode

// no inst buffer now. If contains inst buffer, this module will be used to choose inst between inst buffer and inst cache.
module postif (
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] exception_type_i,
    input        inst_ren_i,
    input        inst_ok_i,
    input        inst_valid_i,

    output [31:0] pc_o,
    output [31:0] inst_o,
    output [31:0] exception_type_o,
    output        postif_stall_o,
    output        inst_ren_o,
    output        inst_ok_o,
    output        inst_valid_o
);

    assign pc_o             = pc_i;
    assign inst_o           = inst_i;
    assign exception_type_o = exception_type_i;
    assign postif_stall_o   = ~inst_ren_i | inst_ok_i;  // if exist request and no reply, then stall
    assign inst_ren_o       = inst_ren_i;
    assign inst_ok_o        = inst_ok_i;
    assign inst_valid_o     = inst_valid_i;

endmodule
