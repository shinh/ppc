module decode(input [31:0]  op,
              output [5:0]         opcode,
              output [9:0]         sub_opcode,
              output [4:0]         d,
              output [4:0]         a,
              output [4:0]         b,
              output [2:0]         crfd,
              output [15:0]        imm,
              output signed [31:0] simm);
   assign opcode = op[31:26];
   assign sub_opcode = op[10:1];
   assign d = op[25:21];
   assign a = op[20:16];
   assign b = op[15:11];
   assign crfd = op[25:23];
   assign imm = op[15:0];
   assign simm = {{16{op[15]}}, op[15:0]};
endmodule // decode
