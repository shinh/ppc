`include "const.v"

module sram(input [`RAM_ADDR_BITS-1:0]  addr,
            input [3:0]       byteen,
            input             clk,
            input [31:0]      data,
            input             rden,
            input             wren,
            output reg [31:0] q);
   reg [31:0]                 mem [`RAM_ADDR_MAX:0];

   always @(posedge clk) begin
      if (wren) begin
         if (byteen[3]) begin
            mem[addr][3*8+7:3*8] <= data[3*8+7:3*8];
         end
         if (byteen[2]) begin
            mem[addr][2*8+7:2*8] <= data[2*8+7:2*8];
         end
         if (byteen[1]) begin
            mem[addr][1*8+7:1*8] <= data[1*8+7:1*8];
         end
         if (byteen[0]) begin
            mem[addr][0*8+7:0*8] <= data[0*8+7:0*8];
         end
      end
      if (rden) begin
         q <= { byteen[3] ? mem[addr][31:24] : 8'h00,
                byteen[2] ? mem[addr][23:16] : 8'h00,
                byteen[1] ? mem[addr][15:8] : 8'h00,
                byteen[0] ? mem[addr][7:0] : 8'h00 };
      end
   end
endmodule // sram
