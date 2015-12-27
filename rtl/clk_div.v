`default_nettype none

module clk_div(clk, rst, div, clk_out);
   input wire clk;
   input wire rst;
   input wire [15:0] div;
   output wire       clk_out;

   reg [15:0]        counter;
   reg               clk_out_reg;

   assign clk_out = clk_out_reg;

   always @(posedge clk) begin
      if (rst == 1'b1) begin
         counter <= 0;
         clk_out_reg <= 1;
      end else begin
         if (counter == div) begin
            counter <= 0;
            clk_out_reg <= 1;
         end else begin
            counter <= counter + 1;
            clk_out_reg <= 0;
         end
      end
   end

endmodule // clk_div
