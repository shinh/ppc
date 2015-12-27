`default_nettype none

`include "const.v"

module init(input                       clk,
            input                       rst,
            output [1:0]                next_state,
            output [5:0]                leds,
            output [`RAM_ADDR_BITS-1:0] ram_addr,
            output [3:0]                ram_byteen,
            output [31:0]               ram_wrdata,
            output                      ram_rden,
            output                      ram_wren,
            input [31:0]                ram_rddata);

   localparam INIT_TEST_WRITE = 2'd0;
   localparam INIT_TEST_READ = 2'd1;
   localparam INIT_RAM = 2'd2;
   localparam INIT_DONE = 2'd3;
   reg [2:0]                  state = INIT_TEST_WRITE;
   reg [`RAM_ADDR_BITS-1:0]   ptr;
   reg                        failed = 0;

   assign next_state = (failed ? `PPC_FAIL :
                        state == INIT_DONE ? `PPC_LOAD : `PPC_INIT);
   assign leds[1:0] = state;

   reg [31:0]                 wrdata;
   assign ram_addr = ptr;
   assign ram_byteen = 4'd15;
   assign ram_wrdata = wrdata;
   reg                        rden = 0;
   assign ram_rden = rden;
   reg                        wren = 0;
   assign ram_wren = wren;

   reg [30:0]                 wait_counter = 0;

   assign leds[5:2] = ptr[3:0];

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         state <= INIT_TEST_WRITE;
         ptr <= 0;
         failed <= 0;
         rden <= 0;
         wren <= 0;
      end else if (wait_counter) begin
         wait_counter <= wait_counter - 1;
      end else if (state == INIT_TEST_WRITE) begin
         if (wren) begin
            if (ptr == `RAM_ADDR_MAX) begin
               state <= INIT_TEST_READ;
               ptr <= 0;
            end else begin
               ptr <= ptr + 1;
            end
            wren <= 0;
         end else begin
            wrdata <= 32'hdead0000 + ptr;
            wren <= 1;
         end
      end else if (state == INIT_TEST_READ) begin
         if (rden) begin
            if (ram_rddata != 32'hdead0000 + ptr) begin
               failed <= 1;
            end

            if (ptr == `RAM_ADDR_MAX) begin
               state <= INIT_RAM;
               ptr <= 0;
            end else begin
               ptr <= ptr + 1;
            end
            rden <= 0;
         end else begin
            rden <= 1;
            wait_counter <= 2;
         end
      end else if (state == INIT_RAM) begin
         if (wren) begin
            if (ptr == `RAM_ADDR_MAX) begin
               state <= INIT_DONE;
               ptr <= 0;
            end else begin
               ptr <= ptr + 1;
            end
            wren <= 0;
         end else begin
            wrdata <= 0;
            wren <= 1;
         end // else: !if(wren)
      end
   end

endmodule // init
