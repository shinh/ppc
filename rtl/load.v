`default_nettype none

`include "const.v"

module load(input                       clk,
            input                       rst,
            output [1:0]                next_state,
            output [5:0]                leds,
            output [`RAM_ADDR_BITS-1:0] ram_addr,
            output [3:0]                ram_byteen,
            output [31:0]               ram_wrdata,
            output                      ram_rden,
            output                      ram_wren,
            input [31:0]                ram_rddata,
            input                       rx_ready,
            input [7:0]                 rx_data);

   localparam LOAD_READ_SIZE = 3'd0;
   localparam LOAD_LOAD_PROG = 3'd1;
   localparam LOAD_READ_CHECKSUM = 3'd2;
   localparam LOAD_VERIFY_PROG = 3'd3;
   localparam LOAD_DONE = 3'd4;

   localparam LOAD_OFFSET = 32'h1000;

   localparam PTR_BITS = `RAM_ADDR_BITS + 5 - 3;

   reg [2:0]                            state = LOAD_READ_SIZE;
   reg [PTR_BITS-1:0]                   ptr = 0;
   reg                                  failed = 0;

   assign next_state = (failed ? `PPC_FAIL :
                        state == LOAD_DONE ? `PPC_EXEC : `PPC_LOAD);
   assign leds[2:0] = state;
   assign leds[5:3] = ram_checksum[2:0];

   reg [31:0]                 wrdata;
   //assign ram_addr = ptr[PTR_BITS-1:2] + 4096 / 4;
   assign ram_addr = ptr[PTR_BITS-1:2];
   assign ram_byteen = 4'd8 >> ptr[1:0];
   assign ram_wrdata = wrdata;
   reg                        rden = 0;
   assign ram_rden = rden;
   reg                        wren = 0;
   assign ram_wren = wren;

   reg [23:0]                 code_size;
   reg [7:0]                  rx_checksum;
   reg [7:0]                  ram_checksum;

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         state <= LOAD_READ_SIZE;
         ptr <= 0;
         failed <= 0;
         rden <= 0;
         wren <= 0;
         rx_checksum <= 0;
         ram_checksum <= 0;
      end else if (state == LOAD_READ_SIZE) begin
         if (rx_ready) begin
            if (ptr == 0) begin
               code_size[23:16] <= rx_data;
               ptr <= ptr + 1;
            end else if (ptr == 1) begin
               code_size[15:8] <= rx_data;
               ptr <= ptr + 1;
            end else if (ptr == 2) begin
               code_size[7:0] <= rx_data;
               ptr <= LOAD_OFFSET;
               state <= LOAD_LOAD_PROG;
            end
         end
      end else if (state == LOAD_LOAD_PROG) begin
         if (wren) begin
            if (ptr + 1 == code_size + LOAD_OFFSET) begin
               state <= LOAD_READ_CHECKSUM;
               ptr <= 0;
            end else begin
               ptr <= ptr + 1;
            end
            wren <= 0;
         end
         if (rx_ready) begin
            wrdata <= 0;
            if (ptr[1:0] == 3)
              wrdata[7:0] <= rx_data;
            else if (ptr[1:0] == 2)
              wrdata[15:8] <= rx_data;
            else if (ptr[1:0] == 1)
              wrdata[23:16] <= rx_data;
            else if (ptr[1:0] == 0)
              wrdata[31:24] <= rx_data;
            rx_checksum <= rx_checksum ^ rx_data;
            wren <= 1;
         end
      end else if (state == LOAD_READ_CHECKSUM) begin
         if (rx_ready) begin
            if (rx_data != rx_checksum) begin
               failed <= 1;
            end else begin
               ptr <= LOAD_OFFSET;
               state <= LOAD_VERIFY_PROG;
            end
         end
      end else if (state == LOAD_VERIFY_PROG) begin
         if (rden) begin
            if (ptr[1:0] == 3)
              ram_checksum <= ram_checksum ^ ram_rddata[7:0];
            else if (ptr[1:0] == 2)
              ram_checksum <= ram_checksum ^ ram_rddata[15:8];
            else if (ptr[1:0] == 1)
              ram_checksum <= ram_checksum ^ ram_rddata[23:16];
            else if (ptr[1:0] == 0)
              ram_checksum <= ram_checksum ^ ram_rddata[31:24];

            if (ptr == code_size + LOAD_OFFSET) begin
               if (ram_checksum != rx_checksum) begin
                  failed <= 1;
               end else begin
                  state <= LOAD_DONE;
               end
               ptr <= 0;
            end else begin
               ptr <= ptr + 1;
            end
            rden <= 0;
         end else begin
            rden <= 1;
         end
      end
   end

endmodule // load
