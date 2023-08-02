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
    input        inst_stall_i,

    output [31:0] pc_o,
    output [31:0] inst_o,
    output [31:0] exception_type_o,
    output        postif_stall_o
);

    assign pc_o             = pc_i;
    assign inst_o           = inst_i;
    assign exception_type_o = exception_type_i;
    assign postif_stall_o   = inst_stall_i;

endmodule
