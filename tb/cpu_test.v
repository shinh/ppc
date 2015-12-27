`timescale 1ns/100ps

`include "const.v"

module cpu_test;
   reg rst;
   reg clk;

   reg [`RAM_ADDR_BITS-1:0] ram_addr;
   reg [3:0]  ram_byteen;
   reg [31:0] ram_wrdata;
   reg        ram_rden;
   reg        ram_wren;
   wire [31:0] ram_rddata;

   sram sram(.addr(ram_addr),
             .byteen(ram_byteen),
             .clk(clk),
             .data(ram_wrdata),
             .rden(ram_rden),
             .wren(ram_wren),
             .q(ram_rddata));

   reg                         tx_req = 0;
   wire                        tx_ready;
   reg [7:0]                   tx_data;
   wire                        rx_ready;
   wire [7:0]                  rx_data;
   rs232_sim rs232(.clk(clk),
                   .tx_req(tx_req),
                   .tx_ready(tx_ready),
                   .tx_data(tx_data),
                   .rx_ready(rx_ready),
                   .rx_data(rx_data));

   wire [1:0]  cpu_next_state;
   wire [5:0]  cpu_leds;
   wire [`RAM_ADDR_BITS-1:0] cpu_ram_addr;
   wire [3:0]                cpu_ram_byteen;
   wire [31:0]               cpu_ram_wrdata;
   wire                      cpu_ram_rden;
   wire                      cpu_ram_wren;
   wire                      cpu_tx_req;
   wire [7:0]                cpu_tx_data;
   wire [32*36-1:0]          cpu_debug_out;

   cpu cpu(.clk(clk),
           .rst(rst),
           .next_state(cpu_next_state),
           .leds(cpu_leds),
           .ram_addr(cpu_ram_addr),
           .ram_byteen(cpu_ram_byteen),
           .ram_wrdata(cpu_ram_wrdata),
           .ram_rden(cpu_ram_rden),
           .ram_wren(cpu_ram_wren),
           .ram_rddata(ram_rddata),

           .tx_req(cpu_tx_req),
           .tx_ready(tx_ready),
           .tx_data(cpu_tx_data),
           .rx_ready(rx_ready),
           .rx_data(rx_data),

           .debug_out(cpu_debug_out));

   always #1 clk = !clk;

   integer                   i;

   always @(posedge clk) begin
      ram_addr <= cpu_ram_addr;
      ram_byteen <= cpu_ram_byteen;
      ram_wrdata <= cpu_ram_wrdata;
      ram_rden <= cpu_ram_rden;
      ram_wren <= cpu_ram_wren;
      tx_req <= cpu_tx_req;
      tx_data <= cpu_tx_data;

      if (sram.mem[4'hffe8 / 4]) begin
         $display("hmmm??? pc=%x", cpu.pc*4);
      end
   end

   initial begin
      $readmemh(`RAM, sram.mem, 4096 / 4);

      clk <= 1'b0;
      rst <= 1'b1;
      #2;

      rst <= 1'b0;
      #2;

      for (i = 0; i < 1000 && cpu.state != 7; i = i + 1) begin
         #1000;
      end

`ifndef TRACE
      $display("CPU State: %01d", cpu.state);
      $display("PC: %x", cpu.pc * 4);
      for (i = 0; i < 32; i = i + 1) begin
         $display("R%02d: %x", i, cpu.gprs[i]);
      end
      $display("XER: %x", cpu.sprs[0]);
      $display("LR: %x", cpu.sprs[1]);
      $display("CTR: %x", cpu.sprs[2]);
      $display("RAM: %x %x %x %x",
               sram.mem[0], sram.mem[1], sram.mem[2], sram.mem[3]);
`endif

      $finish;
   end

endmodule // cpu_test
