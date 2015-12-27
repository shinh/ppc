module rs232_sim(input clk,
                 input tx_req,
                 output tx_ready,
                 input [7:0] tx_data,
                 output rx_ready,
                 output [7:0] rx_data);
   reg [7:0]                  tx_wait = 0;

   assign tx_ready = tx_wait == 0;

   reg [31:0]                 rx_buf[65535:0];
   reg [31:0]                 rx_ptr;
   reg [15:0]                  rx_wait = 500;
   assign rx_data = (rx_buf[rx_ptr >> 2] >> (3 - (rx_ptr & 3)) * 8) & 255;
   assign rx_ready = rx_wait == 0;

   initial begin
      $readmemh(`STDIN, rx_buf);
      rx_wait <= 4000;
      rx_ptr <= -1;
   end

   always @(posedge clk) begin
      if (tx_wait) begin
         tx_wait <= tx_wait - 1;
      end else if (tx_req) begin
         tx_wait <= 50;
`ifdef TRACE
         $write("%c", tx_data);
`else
         $display("OUT: %c", tx_data);
`endif
      end

      if (rx_wait == 1) begin
         rx_ptr <= rx_ptr + 1;
         rx_wait <= rx_wait - 1;
      end else if (rx_wait == 0) begin
         rx_wait <= 4000;
      end else begin
         rx_wait <= rx_wait - 1;
      end
   end

endmodule // rs232_sim
