`timescale 1ns/100ps

module sram_test;
   reg [12:0] addr;
   reg [3:0]  byteen;
   reg        clk;
   reg [31:0] data;
   reg        rden;
   reg        wren;
   wire [31:0] out;

   sram sram(.addr(addr),
             .byteen(byteen),
             .clk(clk),
             .data(data),
             .rden(rden),
             .wren(wren),
             .q(out));

   always #1 clk = !clk;

   task write(input [12:0] a,
              input [3:0]  b,
              input [31:0] d);
      begin
         addr <= a;
         byteen <= b;
         data <= d;
         rden <= 1'b0;
         wren <= 1'b1;
         #2;
      end
   endtask // write

   task read(input [12:0] a,
             input [3:0] b);
      begin
         addr <= a;
         byteen <= b;
         rden <= 1'b1;
         wren <= 1'b0;
         #2;
      end
   endtask // read

   task read_and_display(input [12:0] a,
                         input [3:0] b);
      begin
         read(a, b);
         $display("%x", out);
      end
   endtask // read_and_display

   initial begin
      $dumpfile("sram_test.vcd");
      clk <= 1'b0;
      rden <= 1'b0;
      wren <= 1'b0;

      write(12'h0, 4'b1111, 32'h12345678);
      write(12'h1, 4'b1111, 32'h12345678);
      read_and_display(12'h0, 4'b1111);
      read_and_display(12'h0, 4'b1000);
      read_and_display(12'h0, 4'b0100);
      read_and_display(12'h0, 4'b0010);
      read_and_display(12'h0, 4'b0001);
      read_and_display(12'h0, 4'b1010);

      write(12'h0, 4'b1100, 32'h9876dead);
      read_and_display(12'h0, 4'b1111);
      write(12'h0, 4'b0011, 32'hdead5432);
      read_and_display(12'h0, 4'b1111);

      read_and_display(12'h1, 4'b1111);

      $finish;
   end

endmodule // sram_test
