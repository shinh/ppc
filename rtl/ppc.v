`default_nettype none

`include "const.v"

module ppc(
    CLOCK_50,
    LED,
    KEY,
    DRAM_ADDR,
    DRAM_BA,
    DRAM_CAS_N,
    DRAM_CKE,
    DRAM_CLK,
    DRAM_CS_N,
    DRAM_DQ,
    DRAM_DQM,
    DRAM_RAS_N,
    DRAM_WE_N,
    GPIO,
    GPIO_IN 
);
   input                       CLOCK_50;
   output [7:0]                LED;
   input [1:0]                 KEY;

   output [12:0]               DRAM_ADDR;
   output [1:0]                DRAM_BA;
   output                      DRAM_CAS_N;
   output                      DRAM_CKE;
   output                      DRAM_CLK;
   output                      DRAM_CS_N;
   inout [15:0]                DRAM_DQ;
   output [1:0]                DRAM_DQM;
   output                      DRAM_RAS_N;
   output                      DRAM_WE_N;

   inout [33:0]                GPIO;
   input [1:0]                 GPIO_IN;

   //wire                        clk = CLOCK_50;
   wire                        clk;
   parameter sys_clk = 10000000;
   pll pll(.inclk0(CLOCK_50), .c0(clk));

   wire                        rst;
   wire                        rx, tx;
   assign rst = !KEY[0];
   assign rx = GPIO[32];
   assign GPIO[33] = tx;

   reg [1:0]                   state;
   assign LED[1:0] = state;
   reg [5:0]                   leds;
   assign LED[7:2] = leds;

   reg                         tx_req = 0;
   wire                        tx_ready;
   reg [7:0]                   tx_data;
   wire                        rx_ready;
   wire [7:0]                  rx_data;
   rs232c_tx #(sys_clk) rs232c_tx(.clk(clk), .rst(rst), .wr(tx_req),
                                  .din(tx_data), .dout(tx), .ready(tx_ready));
   rs232c_rx #(sys_clk) rs232c_rx(.clk(clk), .rst(rst), .din(rx),
                                  .rd(rx_ready), .dout(rx_data));

   reg [`RAM_ADDR_BITS-1:0]    ram_addr;
   reg [3:0]                   ram_byteen;
   reg [31:0]                  ram_wrdata;
   reg                         ram_rden;
   reg                         ram_wren;
   wire [31:0]                 ram_rddata;
   ram ram(.address(ram_addr),
           .byteena(ram_byteen),
           .clock(clk),
           .data(ram_wrdata),
           .rden(ram_rden),
           .wren(ram_wren),
           .q(ram_rddata));

   wire [1:0]                  init_next_state;
   wire [5:0]                  init_leds;
   wire [`RAM_ADDR_BITS-1:0]   init_ram_addr;
   wire [3:0]                  init_ram_byteen;
   wire [31:0]                 init_ram_wrdata;
   wire                        init_ram_rden;
   wire                        init_ram_wren;
   init init(.clk(clk && state == `PPC_INIT),
             .rst(rst),
             .next_state(init_next_state),
             .leds(init_leds),
             .ram_addr(init_ram_addr),
             .ram_byteen(init_ram_byteen),
             .ram_wrdata(init_ram_wrdata),
             .ram_rden(init_ram_rden),
             .ram_wren(init_ram_wren),
             .ram_rddata(ram_rddata));

   wire [1:0]                  load_next_state;
   wire [5:0]                  load_leds;
   wire [`RAM_ADDR_BITS-1:0]   load_ram_addr;
   wire [3:0]                  load_ram_byteen;
   wire [31:0]                 load_ram_wrdata;
   wire                        load_ram_rden;
   wire                        load_ram_wren;
   load load(.clk(clk && state == `PPC_LOAD),
             .rst(rst),
             .next_state(load_next_state),
             .leds(load_leds),
             .ram_addr(load_ram_addr),
             .ram_byteen(load_ram_byteen),
             .ram_rden(load_ram_rden),
             .ram_wrdata(load_ram_wrdata),
             .ram_wren(load_ram_wren),
             .ram_rddata(ram_rddata),
             .rx_ready(rx_ready),
             .rx_data(rx_data));

   wire [1:0]                  cpu_next_state;
   wire [5:0]                  cpu_leds;
   wire [`RAM_ADDR_BITS-1:0]   cpu_ram_addr;
   wire [3:0]                  cpu_ram_byteen;
   wire [31:0]                 cpu_ram_wrdata;
   wire                        cpu_ram_rden;
   wire                        cpu_ram_wren;
   wire                        cpu_tx_req;
   wire [7:0]                  cpu_tx_data;
   wire [32*36-1:0]            cpu_debug_out;
   cpu cpu(.clk(clk && state == `PPC_EXEC),
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

   reg [`RAM_ADDR_BITS+5-3:0]  ptr = 0;
   reg [6:0]                   wait_counter = 0;
   reg [11:0]                  dump_steps = 0;
   reg [7:0]                   dump_data;
   reg                         dump_ready = 0;

   always @(posedge clk) begin
      if (rst) begin
         state <= `PPC_INIT;
         leds <= 0;
         tx_req <= 0;
         dump_steps <= 0;
      end else if (!KEY[1]) begin
         state <= `PPC_FAIL;
         dump_steps <= 36 * 32 / 8 - 1;
      end else if (state == `PPC_INIT) begin
         state <= init_next_state;
         leds <= init_leds;
         ram_addr <= init_ram_addr;
         ram_byteen <= init_ram_byteen;
         ram_wrdata <= init_ram_wrdata;
         ram_rden <= init_ram_rden;
         ram_wren <= init_ram_wren;
         tx_req <= 0;
         dump_steps <= 0;
      end else if (state == `PPC_LOAD) begin
         state <= load_next_state;
         leds <= load_leds;
         ram_addr <= load_ram_addr;
         ram_byteen <= load_ram_byteen;
         ram_wrdata <= load_ram_wrdata;
         ram_rden <= load_ram_rden;
         ram_wren <= load_ram_wren;
      end else if (state == `PPC_EXEC) begin
         dump_steps <= 36 * 32 / 8 - 1;
         state <= cpu_next_state;
         leds <= cpu_leds;
         ram_addr <= cpu_ram_addr;
         ram_byteen <= cpu_ram_byteen;
         ram_wrdata <= cpu_ram_wrdata;
         ram_rden <= cpu_ram_rden;
         ram_wren <= cpu_ram_wren;
         tx_req <= cpu_tx_req;
         tx_data <= cpu_tx_data;
      end else if (state == `PPC_FAIL) begin
         if (wait_counter) begin
            wait_counter <= wait_counter - 1;
         end else if (dump_steps <= 36 * 32 / 8) begin
            if (tx_ready) begin
               tx_req <= 1;
               //tx_data <= cpu_debug_out[dump_steps] + 48;
               tx_data <= { cpu_debug_out[dump_steps*8+7],
                            cpu_debug_out[dump_steps*8+6],
                            cpu_debug_out[dump_steps*8+5],
                            cpu_debug_out[dump_steps*8+4],
                            cpu_debug_out[dump_steps*8+3],
                            cpu_debug_out[dump_steps*8+2],
                            cpu_debug_out[dump_steps*8+1],
                            cpu_debug_out[dump_steps*8+0]
                            };
               ptr <= 0;
            end else if (!tx_ready && ptr == 0) begin
               tx_req <= 0;
               ptr <= 1;
               wait_counter <= 20;
               dump_steps <= dump_steps - 1;
               ram_addr <= ptr[`RAM_ADDR_BITS+5-3:2];
               //ram_byteen <= 4'd8 >> ptr[1:0];
               ram_byteen <= 4'd15;
               ram_rden <= 1;
               //dump_ready <= 0;
            end
         end else if (ptr == 4096*5) begin // if (dump_steps < 36 * 32 / 8)
            /*
         end if (wait_counter) begin
            wait_counter <= wait_counter - 1;
             */
            /*
         end else if (!dump_ready) begin
            dump_ready <= 1;
            if (ptr[1:0] == 3)
              dump_data <= ram_rddata[31:24];
            else if (ptr[1:0] == 2)
              dump_data <= ram_rddata[23:16];
            else if (ptr[1:0] == 1)
              dump_data <= ram_rddata[15:8];
            else if (ptr[1:0] == 0)
              dump_data <= ram_rddata[7:0];
             */
         //end else if (dump_ready && tx_ready) begin
         end else if (tx_ready && !tx_req) begin
            tx_req <= 1;
            //tx_data <= dump_data;
            if (ptr[1:0] == 0)
              tx_data <= ram_rddata[7:0];
            else if (ptr[1:0] == 3)
              tx_data <= ram_rddata[15:8];
            else if (ptr[1:0] == 2)
              tx_data <= ram_rddata[23:16];
            else if (ptr[1:0] == 1)
              tx_data <= ram_rddata[31:24];
            /*
            if (ptr[1:0] == 3)
              tx_data <= ram_rddata[31:24];
            else if (ptr[1:0] == 2)
              tx_data <= ram_rddata[23:16];
            else if (ptr[1:0] == 1)
              tx_data <= ram_rddata[15:8];
            else if (ptr[1:0] == 0)
              tx_data <= ram_rddata[7:0];
            if (ptr == 0)
              tx_data <= 8'h61;
             */
            /*
            if (ptr == 1)
              tx_data <= 8'h62;
            if (ptr == 2)
              tx_data <= 8'h63;
            if (ptr == 3)
              tx_data <= 8'h64;
             */

            ptr <= ptr + 1;
            wait_counter <= 20;
            ram_addr <= ptr[`RAM_ADDR_BITS+5-3:2];
            //ram_byteen <= 4'd8 >> ptr[1:0];
            ram_rden <= 1;
            dump_ready <= 1;
         end
         if (!tx_ready) begin
            tx_req <= 0;
         end
      end // if (state == `PPC_FAIL)
   end

endmodule
