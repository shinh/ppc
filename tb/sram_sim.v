`include "const.v"

module sram(input [`RAM_ADDR_BITS-1:0] addr,
            input [`RAM_ADDR_BITS-1:0] addr2,
            input [3:0]                byteen,
            input                      clk,
            input [31:0]               data,
            input [31:0]               data2,
            input                      wren,
            input                      wren2,
            output [31:0]              q,
            output [31:0]              q2);
   reg [31:0]                 mem [`RAM_ADDR_MAX:0];
   reg [`RAM_ADDR_BITS-1:0]   addr_buf;
   reg [`RAM_ADDR_BITS-1:0]   addr2_buf;
   reg [31:0]                 data_buf;
   reg [3:0]                  byteen_buf;
   reg                        wren_buf;

   assign q = { byteen_buf[3] ? mem[addr_buf][31:24] : 8'h00,
                byteen_buf[2] ? mem[addr_buf][23:16] : 8'h00,
                byteen_buf[1] ? mem[addr_buf][15:8] : 8'h00,
                byteen_buf[0] ? mem[addr_buf][7:0] : 8'h00 };
   assign q2 = mem[addr2_buf];

   always @(posedge clk) begin
      addr_buf <= addr;
      addr2_buf <= addr2;
      data_buf <= data;
      byteen_buf <= byteen;
      wren_buf <= wren;

      if (wren_buf) begin
         if (byteen_buf[3]) begin
            mem[addr_buf][3*8+7:3*8] <= data_buf[3*8+7:3*8];
         end
         if (byteen_buf[2]) begin
            mem[addr_buf][2*8+7:2*8] <= data_buf[2*8+7:2*8];
         end
         if (byteen_buf[1]) begin
            mem[addr_buf][1*8+7:1*8] <= data_buf[1*8+7:1*8];
         end
         if (byteen_buf[0]) begin
            mem[addr_buf][0*8+7:0*8] <= data_buf[0*8+7:0*8];
         end
      end
   end
endmodule // sram
