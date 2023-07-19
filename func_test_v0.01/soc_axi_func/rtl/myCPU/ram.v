`include "defines.vh"
// ram module just 4KB
module ram(
    input[3:0]   ram_write_select_i,
    input        ram_write_enable_i,
    input[31:0]  ram_write_addr_i,
    input[31:0]  ram_write_data_i,
    input[31:0]  ram_read_addr_i,
    
    output[31:0] ram_read_data 
);

reg[7:0] ramcol3[1023:0], ramcol2[1023:0], ramcol1[1023:0], ramcol0[1023:0];

wire[7:0] data_o0, data_o1, data_o2, data_o3;

assign data_o0 = ramcol0[ram_read_addr_i[11:2]];
assign data_o1 = ramcol1[ram_read_addr_i[11:2]];
assign data_o2 = ramcol2[ram_read_addr_i[11:2]];
assign data_o3 = ramcol3[ram_read_addr_i[11:2]];

assign ram_read_data = {data_o3, data_o2, data_o1, data_o0};

always @ (*) begin
    if (ram_write_enable_i == 1) begin
        if (ram_write_select_i[0] == 1'b1)
            ramcol0[ram_write_addr_i[11:2]] = ram_write_data_i[7:0];
        if (ram_write_select_i[1] == 1'b1)
            ramcol1[ram_write_addr_i[11:2]] = ram_write_data_i[15:8];
        if (ram_write_select_i[2] == 1'b1)
            ramcol2[ram_write_addr_i[11:2]] = ram_write_data_i[23:16];
        if (ram_write_select_i[3] == 1'b1)
            ramcol3[ram_write_addr_i[11:2]] = ram_write_data_i[31:24];
    end
end
endmodule