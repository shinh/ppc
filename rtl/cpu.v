`default_nettype none

`include "const.v"

module cpu(input                       clk,
           input                       rst,
           output [1:0]                next_state,
           output [5:0]                leds,
           output [`RAM_ADDR_BITS-1:0] ram_addr,
           output [3:0]                ram_byteen,
           output [31:0]               ram_wrdata,
           output                      ram_rden,
           output                      ram_wren,
           input [31:0]                ram_rddata,

           output                      tx_req,
           input                       tx_ready,
           output [7:0]                tx_data,
           input                       rx_ready,
           input [7:0]                 rx_data,

           output [32*36-1:0]          debug_out);

   localparam CPU_INIT = 3'd0;
   localparam CPU_FETCH_INST = 3'd1;
   localparam CPU_EXEC_INST = 3'd2;
   localparam CPU_FETCH_DATA = 3'd3;
   localparam CPU_FETCH_OUT_DATA = 3'd4;
   localparam CPU_IO_WAIT = 3'd6;
   localparam CPU_DONE = 3'd7;
   reg [2:0]                           state = CPU_INIT;

   reg [`RAM_ADDR_BITS-1:0]            addr;
   assign ram_addr = addr;
   reg [3:0]                           byteen;
   assign ram_byteen = byteen;
   reg [31:0]                          wrdata;
   assign ram_wrdata = wrdata;
   reg                                 rden = 0;
   assign ram_rden = rden;
   reg                                 wren = 0;
   assign ram_wren = wren;

   // CPU states.
   reg [31:0]                          gprs [31:0];
   reg [31:0]                          sprs [2:0];  // xer, lr, ctr
   reg [`RAM_ADDR_BITS-1:0]            pc;
   reg [3:0]                           crs [7:0];  // lt, gt, eq, so
`ifdef TRACE
   reg [`RAM_ADDR_BITS-1:0]            prev_pc = 0;
`endif

   // Control.
   reg [24:0]                          wait_counter = 0;
   reg                                 failed;
   assign next_state = (failed ? `PPC_FAIL :
                        state == CPU_DONE ? `PPC_INIT : `PPC_EXEC);

   assign leds[2:0] = state;
   reg [2:0]                           dbg = 0;
   assign leds[5:3] = dbg;

   assign debug_out = { pc, sprs[0], sprs[1], sprs[2],
                        gprs[0], gprs[1], gprs[2], gprs[3],
                        gprs[4], gprs[5], gprs[6], gprs[7],
                        gprs[8], gprs[9], gprs[10], gprs[11],
                        gprs[12], gprs[13], gprs[14], gprs[15],
                        gprs[16], gprs[17], gprs[18], gprs[19],
                        gprs[20], gprs[21], gprs[22], gprs[23],
                        gprs[24], gprs[25], gprs[26], gprs[27],
                        gprs[28], gprs[29], gprs[30], gprs[31] };

   wire [5:0]                          opcode;
   wire [9:0]                          sub_opcode;
   wire [4:0]                          rd;
   wire [4:0]                          ra;
   wire [4:0]                          rb;
   wire [2:0]                          crfd;
   wire [15:0]                         imm;
   wire signed [31:0]                  simm;
   wire [31:0]                         op;
   assign op = ram_rddata;
   decode dec(.op(op),
              .opcode(opcode),
              .sub_opcode(sub_opcode),
              .d(rd),
              .a(ra),
              .b(rb),
              .crfd(crfd),
              .imm(imm),
              .simm(simm));

   wire [31:0]                         ra0;
   assign ra0 = (ra == 0 ? 0 : gprs[ra]);
   wire [31:0]                         rd0;
   assign rd0 = (rd == 0 ? 0 : gprs[rd]);

   wire [63:0]                         mul_result;
   assign mul_result = $signed(gprs[ra]) * $signed(gprs[rb]);

   wire [4:0]                          rlwi_mb;
   assign rlwi_mb = op[10:6];
   wire [4:0]                          rlwi_me;
   assign rlwi_me = op[5:1];

   wire [31:0]                         rlwi_mask;
   assign rlwi_mask = (rlwi_me < rlwi_mb ?
                       ~(32'hffffffff >> (rlwi_me + 33 - rlwi_mb)
                         << (32 - rlwi_mb)) :
                       (32'hffffffff >> (rlwi_mb + 31 - rlwi_me)
                        << (31 - rlwi_me)));

   wire [31:0]                         rlwinm_result;
   assign rlwinm_result = ((gprs[rd] << op[15:11]) |
                           (gprs[rd] >> (32 - op[15:11]))) & rlwi_mask;

   wire [31:0]                         rlwimi_result;
   assign rlwimi_result = rlwinm_result | (gprs[ra] & ~rlwi_mask);

   wire                                bc_ctr_ok;
   assign bc_ctr_ok = rd[2] | ((sprs[2] != 1) ^ rd[1]);
   wire                                bc_cond_ok;
   assign bc_cond_ok = (rd[4] |
                        rd[3] == (crs[ra/4][ra&3]));

   reg [31:0]                          fetch_reg;

   reg                                 cpu_tx_req = 0;
   reg [7:0]                           cpu_tx_data;
   assign tx_req = cpu_tx_req;
   assign tx_data = cpu_tx_data;

`ifdef TEST
   reg [31:0]                          rx_buf[65535:0];
   reg [31:0]                          rx_ptr;
   wire [7:0]                          test_rx_data;
   assign test_rx_data = (rx_buf[rx_ptr >> 2] >> (3 - (rx_ptr & 3)) * 8) & 255;

   initial begin
      $readmemh(`STDIN, rx_buf);
      rx_ptr <= 0;
   end
`endif

   task load_data(input [31:0] a,
                  input [3:0] b);
      begin
         addr <= a / 4;
         byteen <= b;
         rden <= 1;
         wren <= 0;
         fetch_reg <= rd;
         wait_counter <= 2;
         state <= CPU_FETCH_DATA;
      end
   endtask // load_data

   task store_data(input [31:0] a,
                   input [3:0]  b,
                   input [31:0] d);
      begin
         addr <= a / 4;
         byteen <= b;
         wrdata <= d;
         rden <= 0;
         wren <= 1;
      end
   endtask // store_data

   integer                             i;
   always @(posedge clk or posedge rst) begin
      if (rst) begin
         state <= CPU_INIT;
         cpu_tx_req <= 0;
         failed <= 0;
      end else if (wait_counter) begin
         wait_counter <= wait_counter - 1;
      end else if (state == CPU_INIT) begin
         failed <= 0;
         wait_counter <= 0;
         wren <= 0;
         dbg <= 0;
         for (i = 0; i < 32; i = i + 1) begin
            gprs[i] <= 0;
         end
         gprs[1] <= 65536;
         // argc, argv, ... from GDB sim.
         gprs[3] <= 1;
         gprs[4] <= 65536+8;
         gprs[5] <= 65536+16;
         gprs[6] <= 65536+312;
         for (i = 0; i < 3; i = i + 1) begin
            sprs[i] <= 0;
         end
         for (i = 0; i < 8; i = i + 1) begin
            crs[i] <= 0;
         end
         pc <= 4096 / 4;
         state <= CPU_FETCH_INST;
      end else if (state == CPU_FETCH_INST) begin
         addr <= pc;
         byteen <= 4'd15;
         rden <= 1;
         wren <= 0;
         wait_counter <= 2;
         state <= CPU_EXEC_INST;
      end else if (state == CPU_EXEC_INST) begin
         if (rden) begin
`ifdef TRACE
            // Not sure why, but it seems GDB sim resets CR just
            // before sc is fetched.
            if (opcode == 6'd17) begin
               for (i = 0; i < 8; i = i + 1) begin
                  crs[0] <= 0;
               end
            end

            if (pc != prev_pc) begin
               $display("");
               $display("PC: %x", cpu.pc * 4);
               for (i = 0; i < 32; i = i + 1) begin
                  $display("R%02d: %x", i, cpu.gprs[i]);
               end
               $write("CR:");
               for (i = 0; i < 8; i = i + 1) begin
                  $write(" %b%b%b%b",
                         cpu.crs[i][0], cpu.crs[i][1],
                         cpu.crs[i][2], cpu.crs[i][3]);
               end
               $display("");
               $display("XER: %x", cpu.sprs[0]);
               $display("LR: %x", cpu.sprs[1]);
               $display("CTR: %x", cpu.sprs[2]);
            end
            prev_pc <= pc;
`endif

            //$display("pc=%x inst=%x", pc*4, ram_rddata);
            rden <= 0;
            state <= CPU_FETCH_INST;
            pc <= pc + 1;
            case (opcode)
              6'd7: begin  // mulli
                 gprs[rd] <= gprs[ra] * simm;
              end

              6'd14: begin  // addi
                 gprs[rd] <= ra0 + simm;
              end

              6'd15: begin  // addis
                 gprs[rd] <= ra0 + (imm << 16);
              end

              6'd28: begin  // andi.
                 gprs[ra] <= rd0 & imm;
                 crs[0] <= {
                            sprs[0][0],
                            (rd0 & imm) == 0,
                            $signed(rd0 & imm) > 0,
                            $signed(rd0 & imm) < 0
                            };
              end

              6'd24: begin  // ori
                 gprs[ra] <= rd0 | imm;
              end

              6'd27: begin  // xoris
                 gprs[ra] <= rd0 ^ (imm << 16);
              end

              6'd10: begin  // cmpli
                 /*
                 $display("cmpli: cr%d <= %x vs %x pc=%x",
                          crfd, gprs[ra], imm, pc*4);
                  */
                 crs[crfd] <= {
                               sprs[0][0],
                               gprs[ra] == imm,
                               gprs[ra] > imm,
                               gprs[ra] < imm
                               };
              end

              6'd11: begin  // cmpi
                 /*
                 $display("cmpi: cr%d <= %x vs %x",
                          crfd, gprs[ra], imm);
                  */
                 crs[crfd] <= {
                               sprs[0][0],
                               $signed(gprs[ra]) == simm,
                               $signed(gprs[ra]) > simm,
                               $signed(gprs[ra]) < simm
                               };
              end

              6'd16: begin  // bc
                 /*
                 $display("bc: cond=%01b ra=%d rd=%d pc=%x",
                          ra < 4 ? crs[0][ra] :
                          ra < 8 ? crs[1][ra-4] : crs[ra/4],
                          ra, rd, pc*4);
                  */
                 if (op[0])  // lk
                   sprs[1] <= (pc + 1) * 4;
                 if (!rd[2])
                   sprs[2] <= sprs[2] - 1;
                 if (bc_ctr_ok && bc_cond_ok) begin
                    if (op[1])
                      pc <= op[25:2];
                    else
                      pc <= pc + op[25:2];
                 end
              end

              6'd18: begin  // b
                 if (op[0])  // lk
                   sprs[1] <= (pc + 1) * 4;
                 if (op[1])
                   pc <= op[25:2];
                 else
                   pc <= pc + op[25:2];
              end

              6'd19: begin
                 case (sub_opcode)
                   10'd16: begin  // bclr
                      /*
                      $display("bclr: cond=%01b ra=%d pc=%x",
                               ra < 4 ? crs[0][ra] :
                               ra < 8 ? crs[1][ra-4] : crs[ra/4],
                               ra, pc*4);
                      if (op[0])  // lk
                        sprs[1] <= (pc + 1) * 4;
                     if (!rd[2])
                       sprs[2] <= sprs[2] - 1;
                       if ((rd[4] ||
                       rd[3] == (ra < 4 ? crs[0][ra] :
                       ra < 8 ? crs[1][ra-4] :
                       crs[ra/4]))) begin
                      end
                       */
                      // TODO: Condition
                      if (op[0])  // lk
                        sprs[1] <= (pc + 1) * 4;
                      pc <= sprs[1] / 4;
                   end // case: 10'd16

                   10'd528: begin  // bcctr
                      // TODO: Condition
                      if (op[0])  // lk
                        sprs[1] <= (pc + 1) * 4;
                      pc <= sprs[2] / 4;
                   end

                   10'd449: begin  // cror
                      crs[rd>>2][rd&3] <= crs[ra>>2][ra&3] | crs[rb>>2][rb&3];
                   end

                   10'd417: begin  // crorc
                      crs[rd>>2][rd&3] <= crs[ra>>2][ra&3] | !crs[rb>>2][rb&3];
                   end

                   10'd33: begin  // crnor
                      crs[rd>>2][rd&3] <= !(crs[ra>>2][ra&3] | crs[rb>>2][rb&3]);
                   end

                   10'd193: begin  // crxor
                      crs[rd>>2][rd&3] <= crs[ra>>2][ra&3] ^ crs[rb>>2][rb&3];
                   end

                   default: begin
                      $display("unknown branch? pc=%x %d", pc*4, sub_opcode);
                      failed <= 1;
                      state <= CPU_DONE;
                   end
                 endcase
              end // case: 6'd19

              6'd20: begin  // rlwimi
                 gprs[ra] <= rlwimi_result;
                 if (op[0]) begin  // rc
                    crs[0] <= {
                               sprs[0][0],
                               rlwimi_result == 0,
                               $signed(rlwimi_result) > 0,
                               $signed(rlwimi_result) < 0
                               };
                 end
              end

              6'd21: begin  // rlwinm
                 gprs[ra] <= rlwinm_result;
                 if (op[0]) begin  // rc
                    crs[0] <= {
                               sprs[0][0],
                               rlwinm_result == 0,
                               $signed(rlwinm_result) > 0,
                               $signed(rlwinm_result) < 0
                               };
                 end
              end

              6'd32: begin  // lwz
                 load_data(ra0 + simm, 4'd15);
              end

              6'd33: begin  // lwzu
                 load_data(ra0 + simm, 4'd15);
                 gprs[ra] <= ra0 + simm;
              end

              6'd34: begin  // lbz
                 load_data(ra0 + simm,
                           4'd8 >> ((ra0 + simm) & 3));
              end

              6'd35: begin  // lbzu
                 load_data(ra0 + simm,
                           4'd8 >> ((ra0 + simm) & 3));
                 gprs[ra] <= ra0 + simm;
              end

              6'd31: begin  // mfspr, mtspr, etc..
                 case (sub_opcode)
                   10'd000: begin  // cmp
                      if (op[21]) begin
                         $display("L should be zero?");
                         $finish();
                      end
                      crs[crfd] <= {
                                    sprs[0][0],
                                    $signed(gprs[ra]) == $signed(gprs[rb]),
                                    $signed(gprs[ra]) > $signed(gprs[rb]),
                                    $signed(gprs[ra]) < $signed(gprs[rb])
                                    };
                   end // case: 10'd000

                   10'd032: begin  // cmpl
                      if (op[21]) begin
                         $display("L should be zero?");
                         $finish();
                      end

                      crs[crfd] <= {
                                    sprs[0][0],
                                    gprs[ra] == gprs[rb],
                                    gprs[ra] > gprs[rb],
                                    gprs[ra] < gprs[rb]
                                    };
                   end

                   10'd339: begin  // mfspr
                      case (ra)
                        5'b00001:
                          gprs[rd] <= sprs[0];
                        5'b01000:
                          gprs[rd] <= sprs[1];
                        5'b01001:
                          gprs[rd] <= sprs[2];
                        default: begin
                           $display("bad spr %x", ra);
                        end
                      endcase
                   end

                   10'd467: begin  // mtspr
                      case (ra)
                        5'b00001:
                          sprs[0] <= gprs[rd];
                        5'b01000:
                          sprs[1] <= gprs[rd];
                        5'b01001:
                          sprs[2] <= gprs[rd];
                        default: begin
                           $display("bad spr %x", ra);
                        end
                      endcase
                   end // case: 10'd467

                   10'd19: begin  // mfcr
                      gprs[rd] <= {crs[0][0], crs[0][1], crs[0][2], crs[0][3],
                                   crs[1][0], crs[1][1], crs[1][2], crs[1][3],
                                   crs[2][0], crs[2][1], crs[2][2], crs[2][3],
                                   crs[3][0], crs[3][1], crs[3][2], crs[3][3],
                                   crs[4][0], crs[4][1], crs[4][2], crs[4][3],
                                   crs[5][0], crs[5][1], crs[5][2], crs[5][3],
                                   crs[6][0], crs[6][1], crs[6][2], crs[6][3],
                                   crs[7][0], crs[7][1], crs[7][2], crs[7][3]
                                   };
                   end

                   10'd144: begin  // mtcrf
                      crs[0] <= (op[19] ?
                                 {gprs[rd][28], gprs[rd][29],
                                  gprs[rd][30], gprs[rd][31]} : crs[0]);
                      crs[1] <= (op[18] ?
                                 {gprs[rd][24], gprs[rd][25],
                                  gprs[rd][26], gprs[rd][27]} : crs[1]);
                      crs[2] <= (op[17] ?
                                 {gprs[rd][20], gprs[rd][21],
                                  gprs[rd][22], gprs[rd][23]} : crs[2]);
                      crs[3] <= (op[16] ?
                                 {gprs[rd][16], gprs[rd][17],
                                  gprs[rd][18], gprs[rd][19]} : crs[3]);
                      crs[4] <= (op[15] ?
                                 {gprs[rd][12], gprs[rd][13],
                                  gprs[rd][14], gprs[rd][15]} : crs[4]);
                      crs[5] <= (op[14] ?
                                 {gprs[rd][8], gprs[rd][9],
                                  gprs[rd][10], gprs[rd][11]} : crs[5]);
                      crs[6] <= (op[13] ?
                                 {gprs[rd][4], gprs[rd][5],
                                  gprs[rd][6], gprs[rd][7]} : crs[6]);
                      crs[7] <= (op[12] ?
                                 {gprs[rd][0], gprs[rd][1],
                                  gprs[rd][2], gprs[rd][3]} : crs[7]);
                   end

                   10'd28: begin  // and
                      gprs[ra] <= gprs[rd] & gprs[rb];
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    (gprs[rd] & gprs[rb]) == 0,
                                    $signed(gprs[rd] & gprs[rb]) > 0,
                                    $signed(gprs[rd] & gprs[rb]) < 0
                                    };
                      end
                   end

                   10'd444: begin  // or
                      gprs[ra] <= gprs[rd] | gprs[rb];
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    (gprs[rd] | gprs[rb]) == 0,
                                    $signed(gprs[rd] | gprs[rb]) > 0,
                                    $signed(gprs[rd] | gprs[rb]) < 0
                                    };
                      end
                   end

                   10'd124: begin  // nor
                      gprs[ra] <= ~(gprs[rd] | gprs[rb]);
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    ~(gprs[rd] | gprs[rb]) == 0,
                                    $signed(~(gprs[rd] | gprs[rb])) > 0,
                                    $signed(~(gprs[rd] | gprs[rb])) < 0
                                    };
                      end
                   end

                   10'd24: begin  // slw
                      if (gprs[rb][5]) begin
                         gprs[ra] <= 0;
                         if (op[0]) begin  // rc
                            crs[0] <= {
                                       sprs[0][0],
                                       1'd1,
                                       1'd0,
                                       1'd0
                                       };
                         end
                      end else begin
                         gprs[ra] <= gprs[rd] << gprs[rb][4:0];
                         if (op[0]) begin  // rc
                            crs[0] <= {
                                       sprs[0][0],
                                       (gprs[rd] << gprs[rb][4:0]) == 0,
                                       $signed(gprs[rd] << gprs[rb][4:0]) > 0,
                                       $signed(gprs[rd] << gprs[rb][4:0]) < 0
                                       };
                         end
                      end
                   end

                   10'd4: begin  // trap
                      failed <= 1;
                      state <= CPU_DONE;
                      dbg[2] <= 1;
                   end

                   10'd75: begin  // mulhw
                      /*
                      $display("mulhw: %x <= %x * %x",
                               mul_result[63:32],
                               gprs[ra], gprs[rb]);
                       */
                      gprs[rd] <= mul_result[63:32];
                   end

                   10'd235: begin  // mullw
                      gprs[rd] <= mul_result[31:0];
                   end

                   10'd266: begin  // add
                      gprs[rd] <= gprs[ra] + gprs[rb];
                      // TODO: condition
                      if (op[0])  // rc
                        $display("TODO(add)!");
                   end

                   10'd202: begin  // addze
                      gprs[rd] <= gprs[ra] + sprs[0];
                   end

                   10'd40: begin  // subf
                      gprs[rd] <= gprs[rb] - gprs[ra];
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    gprs[rb] == gprs[ra],
                                    gprs[rb] > gprs[ra],
                                    gprs[rb] < gprs[ra]
                                    };
                      end
                   end // case: 10'd40

`ifdef TEST
                   10'd491: begin  // divw
                      gprs[rd] <= gprs[ra] / gprs[rb];
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    gprs[ra] / gprs[rb] == 0,
                                    $signed(gprs[ra] / gprs[rb]) > 0,
                                    $signed(gprs[ra] / gprs[rb]) < 0
                                    };
                      end
                   end // case: 10'd40
`endif

                   10'd104: begin  // neg
                      gprs[rd] = -gprs[ra];
                      if (op[0]) begin  // rc
                         crs[0] <= {
                                    sprs[0][0],
                                    -gprs[ra] == 0,
                                    -gprs[ra] > 0,
                                    -gprs[ra] < 0
                                    };
                      end
                      if (rb[0]) begin  // xer
                         $display("TODO(xer)");
                      end
                   end

                   10'd824: begin  // srawi
                      gprs[ra] <= ((gprs[rd][30:0] >> rb) |
                                   ({32{gprs[rd][31]}} << (31 - rb)));
                      sprs[0][29] <= gprs[rd][31] && rb > 0;
                      // TODO: condition
                      if (op[0])  // rc
                        $display("TODO(srawi)!");
                   end

                   10'd23: begin  // lwzx
                      load_data(ra0 + gprs[rb], 4'd15);
                   end

                   10'd87: begin  // lbzx
                      load_data(ra0 + gprs[rb],
                                4'd8 >> ((ra0 + gprs[rb]) & 3));
                   end

                   10'd215: begin  // stbx
                      store_data(ra0 + gprs[rb],
                                 4'd8 >> ((ra0 + gprs[rb]) & 3),
                                 {4{gprs[rd][7:0]}});
                   end

                   10'd151: begin  // stwx
                      store_data(ra0 + gprs[rb], 4'd15, gprs[rd]);
                   end

                   default: begin
                      failed <= 1;
                      state <= CPU_DONE;
                      $display("TODO! subop=%d pc=%x", sub_opcode, pc*4);
                   end
                 endcase // case (sub_opcode)
              end

              6'd17: begin  // sc
                 dbg[1] <= 1;
                 // OS emulation
                 case (gprs[0])
                   1: begin  // exit
                      state <= CPU_DONE;
                   end

                   3: begin  // read
`ifdef TEST
                      addr <= gprs[4] / 4;
                      rden <= 0;
                      wren <= 1;
                      byteen <= 4'd8 >> (gprs[4] & 3);
                      wrdata <= {4{test_rx_data}};
                      rx_ptr <= rx_ptr + 1;
                      // Emulating a bug of the GDB sim?
                      gprs[0] <= 0;
                      //gprs[3] <= rx_data != 0;
                      gprs[3] <= 1;
`else
                      if (rx_ready) begin
                         addr <= gprs[4] / 4;
                         rden <= 0;
                         wren <= 1;
                         byteen <= 4'd8 >> (gprs[4] & 3);
                         wrdata <= {4{rx_data}};
                         // Emulating a bug of the GDB sim?
                         gprs[0] <= 0;
                         //gprs[3] <= rx_data != 0;
                         gprs[3] <= 1;
                         pc <= pc + 1;
                      end else begin
                         addr <= pc;
                         byteen <= 4'd15;
                         rden <= 1;
                         wren <= 0;
                         state <= CPU_EXEC_INST;
                         pc <= pc;
                      end // else: !if(rx_ready)
`endif
                   end

                   4: begin  // write
                      addr <= gprs[4] / 4;
                      rden <= 1;
                      wren <= 0;
                      byteen <= 4'd8 >> (gprs[4] & 3);
                      wait_counter <= 2;
                      state <= CPU_FETCH_OUT_DATA;
                      // Emulating a bug of the GDB sim?
                      gprs[0] <= 0;
                      gprs[3] <= 1;
                   end
                 endcase // case (gprs[0])
              end

              6'd36: begin  // stw
                 store_data(ra0 + simm, 4'd15, gprs[rd]);
              end

              6'd37: begin  // stwu
                 if (ra == 0) begin
                    $display("invalid stwu (r0)");
                    failed <= 1;
                    state <= CPU_DONE;
                 end
                 store_data(ra0 + simm, 4'd15, gprs[rd]);
                 gprs[ra] <= gprs[ra] + simm;
              end // case: 6'd37

              6'd38: begin  // stb
                 store_data(ra0 + simm,
                            4'd8 >> ((ra0 + simm) & 3),
                            {4{gprs[rd][7:0]}});
              end

              6'd39: begin  // stbu
                 if (ra == 0) begin
                    $display("invalid stbu (r0)");
                    failed <= 1;
                    state <= CPU_DONE;
                 end
                 store_data(ra0 + simm,
                            4'd8 >> ((ra0 + simm) & 3),
                            {4{gprs[rd][7:0]}});
                 gprs[ra] <= gprs[ra] + simm;
              end

              6'd44: begin  // sth
                 store_data(ra0 + simm,
                            4'd12 >> ((ra0 + simm) & 2),
                            {2{gprs[rd][15:0]}});
              end

              6'd47: begin  // stmw
                 $display("stmw is tough");
                 $finish();
              end

              6'd50: begin  // lfd
                 // TODO: Do nothing for now.
              end

              6'd54: begin  // stfd
                 // TODO: Do nothing for now.
              end

              default: begin
                 $display("unknown op (%01d) %x pc=%x",
                          opcode, op, pc * 4);
                 failed <= 1;
                 state <= CPU_DONE;
                 gprs[20] <= op;
              end

            endcase // case (opcode)
         end
      end else if (state == CPU_FETCH_DATA) begin // if (state == CPU_EXEC_INST)
         rden <= 0;
         /*
         $display("fetched: %x addr=%x byteen=%04b pc=%x",
                  ram_rddata, addr * 4, byteen, pc*4);
          */
         case (byteen)
           1: begin
              gprs[fetch_reg] <= ram_rddata[7:0];
           end
           2: begin
              gprs[fetch_reg] <= ram_rddata[15:8];
           end
           4: begin
              gprs[fetch_reg] <= ram_rddata[23:16];
           end
           8: begin
              gprs[fetch_reg] <= ram_rddata[31:24];
           end
           15: begin
              gprs[fetch_reg] <= ram_rddata;
              /*
              gprs[fetch_reg] <= { ram_rddata[7:0],
                                   ram_rddata[15:8],
                                   ram_rddata[23:16],
                                   ram_rddata[31:24]
                                   };
               */
           end
           default: begin
              $display("wrong byteen: %d", byteen);
              failed <= 1;
              state <= CPU_DONE;
           end
         endcase
         state <= CPU_FETCH_INST;
      end else if (state == CPU_FETCH_OUT_DATA) begin
         if (cpu_tx_req && !tx_ready) begin
            cpu_tx_req <= 0;
            state <= CPU_IO_WAIT;
         end else begin
            cpu_tx_req <= 1;
            case (byteen)
              1: begin
                 cpu_tx_data <= ram_rddata[7:0];
              end
              2: begin
                 cpu_tx_data <= ram_rddata[15:8];
              end
              4: begin
                 cpu_tx_data <= ram_rddata[23:16];
              end
              8: begin
                 cpu_tx_data <= ram_rddata[31:24];
              end
            endcase
            rden <= 0;
         end
      end else if (state == CPU_IO_WAIT) begin // if (state == CPU_FETCH_OUT_DATA)
         if (tx_ready) begin
            state <= CPU_FETCH_INST;
         end
      end
   end

endmodule // cpu
