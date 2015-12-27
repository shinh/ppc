`default_nettype none

module rs232c_rx(clk, rst, din, rd, dout);
   parameter sys_clk = 50000000;
   parameter rate = 19200;

   input wire clk;
   input wire rst;
   input wire din;
   output wire rd;
   output reg [7:0] dout;
   reg [7:0]        parallel;
   reg              serial;
   reg              start;
   reg              rdi;
   reg [7:0]        cbit;

   wire             rx_en;
   wire [15:0]      rx_div;

   assign rx_div = (((sys_clk / rate) / 16) - 1);
   clk_div div(.clk(clk), .rst(rst), .div(rx_div), .clk_out(rx_en));

   assign rd = rdi & rx_en;

   always @(posedge rx_en or posedge rst) begin
      if (rst) begin
         start <= 0;
         cbit <= 0;
         parallel <= 0;
         dout <= 0;
      end else begin
         rdi <= 0;
         if (start == 0) begin
            if (din == 0) begin
               start <= 1;
            end
         end else begin
            serial <= din;
            case (cbit)
              6: begin
                 if (serial == 1) begin
                    start <= 0;
                    cbit <= 0;
                 end else begin
                    cbit <= cbit + 1;
                 end
              end
              22, 38, 54, 70, 86, 102, 118, 134: begin
                 cbit <= cbit + 1;
                 parallel <= {serial, parallel[7:1]};
              end
              150: begin
                 cbit <= 0;
                 dout <= parallel;
                 start <= 0;
                 rdi <= 1;
              end
              default: begin
                 cbit <= cbit + 1;
              end
            endcase // case (cbit)
         end // else: !if(start == 0)
      end
   end

endmodule // rs232c_rx
