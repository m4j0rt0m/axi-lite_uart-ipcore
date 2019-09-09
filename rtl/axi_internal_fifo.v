 /* -----------------------------------------------
 * Project Name   : DRAC
 * File           : axi_internal_fifo.v
 * Organization   : Barcelona Supercomputing Center, CIC-IPN
 * Author(s)      : Abraham J. Ruiz R., Vatistas Kostalabros
 * Email(s)       : abraham.ruiz@bsc.es, vatistas.kostalabros@bsc.es
 * References     :
 * -----------------------------------------------
 * Revision History
 *  Revision   | Author      | Commit | Description
 *  ******     | vkostalamp  | 236c2  | Contribution
 * -----------------------------------------------*/


 `default_nettype none

/*
Title: axi_internal_fifo
This module serves as a FIFO that transfer data from the AXI bus to the UART module. It can serve both as the receiver FIFO (UART -> AXI BUS) and as the transmitter FIFO (AXI BUS -> UART)
*/
module axi_internal_fifo
# (
    parameter FIFO_SIZE           = 16,     // AXI UART specifices a 16-character FIFO
    parameter DATA_SIZE           = 8,      // The data packet size in bits
    parameter INDEX_LENGTH        = 4,      // the length of the register indexing the FIFO slots
    parameter PORT_EN             = 3'b111  // flag port enable [3-bits]: load | full | available_space
  )
(/*AUTOARG*/
   // Outputs
   data_o, status_o,
   // Inputs
   clk_i, arstn_i, rst_i, push_i, pull_i, data_i
   );

  /* local parameters */
  localparam  EN_AVAILABLE  = PORT_EN[0] ? 1 : 0;
  localparam  EN_FULL       = PORT_EN[1] ? 1 : 0;
  localparam  EN_LOAD       = PORT_EN[2] ? 1 : 0;
  localparam  STATUS_WIDTH  = INDEX_LENGTH + EN_AVAILABLE + EN_FULL + EN_LOAD;

  input        wire               clk_i;    // clock  signal
  input        wire               arstn_i;  // active-low asynchronous reset
  input        wire               rst_i;    // active-high synchronous soft reset

  input        wire               push_i;   // push data in the FIFO
  input        wire               pull_i;   // pull data from the FIFO

  input   wire  [DATA_SIZE-1:0]   data_i;   // Gets an 8-bit character and feeds it to the FIFO
  output  wire  [DATA_SIZE-1:0]   data_o;   // Gets the value at the end of the FIFO

  output  reg   [STATUS_WIDTH:0]  status_o; // status flag -> (PORT_EN){load, full, available, space}

  /* some parameters */
  localparam FIFO_THRESHOLD  =  90;     // The amount of empty places that have to remain empty otherwise the FIFO signals full signal
  localparam NN              =  2'b00;  // neither push nor pull
  localparam NP              =  2'b01;  // pull
  localparam PN              =  2'b10;  // push
  localparam PP              =  2'b11;  // push and pull

  /* integers, regs and wires */
  reg [INDEX_LENGTH:0]    space;                      // initialize to 5'b10000 = 16 | [4:0] = 5 bits representing up to 31
  reg [INDEX_LENGTH-1:0]  head_int;                   // head_int pointer [3:0] = 4 bits representing up to 15
  reg [INDEX_LENGTH-1:0]  tail_int;                   // tail_int pointer [3:0] = 4 bits representing up to 15
  reg [FIFO_SIZE-1:0]     valid_int;                  // valid_int reg
  reg [INDEX_LENGTH:0]    available_int;              // available entry residing in FIFO
  reg [DATA_SIZE-1:0]     fifo_int  [FIFO_SIZE-1:0];  // the actual FIFO

  /*
    Always description:
    The next code block interprets the push and pull signals issued by the AXI BUS or the external UART interface (depending if the FIFO is instantiated as receiver or transmitter module)
    and moves the data accordingly. It also outputs a signal indicating the avaialable spaces in the FIFO.
  */
  always @ (posedge clk_i, negedge arstn_i) begin:    fifo_unit
    if(~arstn_i) begin
      head_int      <=  0;
      tail_int      <=  0;
      available_int <=  0;
      space         <=  FIFO_SIZE[INDEX_LENGTH:0];
      valid_int     <=  0;
    end else begin
      if(rst_i) begin
        head_int      <=  0;
        tail_int      <=  0;
        available_int <=  0;
        space         <=  FIFO_SIZE[INDEX_LENGTH:0];
        valid_int     <=  0;
      end
      else begin
        case({push_i, pull_i})
          NN: begin        // neither push nor pull
            head_int      <=  head_int;
            tail_int      <=  tail_int;
            available_int <=  available_int;
            space         <=  space;
          end
          NP: begin        // pull data
            if(valid_int[head_int]) begin
              head_int            <=  head_int + 1;
              available_int       <=  available_int - 1;
              space               <=  space + 1;
              valid_int[head_int] <=  0;
            end
          end
          PN: begin        // push data
            if(valid_int[tail_int]) begin // full fifo -> overwritten data!
              head_int  <=  head_int + 1;
              tail_int  <=  tail_int + 1;
            end
            else begin                    // there is space
              tail_int            <=  tail_int + 1;
              available_int       <=  available_int + 1;
              space               <=  space - 1;
              valid_int[tail_int] <=  1;
              fifo_int[tail_int]  <=  data_i;
            end
          end
          PP: begin        // push and pull data
            case({valid_int[tail_int], valid_int[head_int]})  // push in tail pointer, pull in head pointer
              NN: begin                // available entry to push (increment tail pointer), no valid entry to pull (hold head pointer) -> EMPTY
                tail_int            <=  tail_int + 1;
                available_int       <=  available_int + 1;
                space               <=  space - 1;
                valid_int[tail_int] <=  1;
                fifo_int[tail_int]  <=  data_i;
              end
              NP: begin                // available entry to push (increment tail pointer), valid entry to pull (increment head pointer)
                head_int            <=  head_int + 1;
                tail_int            <=  tail_int + 1;
                valid_int[head_int] <=  0;
                valid_int[tail_int] <=  1;
                fifo_int[tail_int]  <=  data_i;
              end
              PN: begin                // no available entry to push, no valid entry to pull -> MUST NEVER HAPPEN!
                head_int      <=  0;
                tail_int      <=  0;
                available_int <=  0;
                space         <=  FIFO_SIZE[INDEX_LENGTH:0];
              end
              PP: begin                // no available entry to push (overwrite data), valid entry to pull -> FULL
                head_int            <=  head_int + 1;
                tail_int            <=  tail_int + 1;
                fifo_int[tail_int]  <=  data_i;
              end
            endcase
          end
        endcase
      end
    end
  end

  /*
    Always description:
    The data output by the fifo
  */
  assign data_o = fifo_int[head_int];

  /*
    flag status generate (NOTE: There should be a better way to generate this..)
    available_write_space: Sets a threshold for Tx queue and when it is surpassed then  the available write space signal is lowered or raised respectively
    load: Gets the MSB and if '1' the FIFO is full
    full: If head pointer is valid you can pull fro mthe FIFO
  */
  generate
    case(PORT_EN)
      3'b000: begin
        assign  status_o  = space;
      end
      3'b001: begin
        reg available_write_space;  // bit that signals if there is avaialble space to write data in the transmit FIFO
        always @ (posedge clk_i, negedge arstn_i) begin
          if (~arstn_i)
            available_write_space <= 1'b1;
          else begin
            if(rst_i)
              available_write_space <= 1'b1;
            else begin
              if (space >= FIFO_THRESHOLD[INDEX_LENGTH:0])
                available_write_space <= 1'b1;
              else
                available_write_space <= 1'b0;
            end
          end
        end
        assign  status_o  = {available_write_space, space};
      end
      3'b010: begin
        wire  full = available_int[INDEX_LENGTH]; // signals that the FIFO is full
        assign  status_o  = {full, space};
      end
      3'b011: begin
        reg available_write_space;  // bit that signals if there is avaialble space to write data in the transmit FIFO
        always @ (posedge clk_i, negedge arstn_i) begin
          if (~arstn_i)
            available_write_space <= 1'b1;
          else begin
            if(rst_i)
              available_write_space <= 1'b1;
            else begin
              if (space >= FIFO_THRESHOLD[INDEX_LENGTH:0])
                available_write_space <= 1'b1;
              else
                available_write_space <= 1'b0;
            end
          end
        end
        wire  full = available_int[INDEX_LENGTH]; // signals that the FIFO is full
        assign  status_o  = {full, available_write_space, space};
      end
      3'b100: begin
        wire  load = valid_int[head_int]; // the fifo has loaded data
        assign  status_o  = {load, space};
      end
      3'b101: begin
        reg available_write_space;  // bit that signals if there is avaialble space to write data in the transmit FIFO
        always @ (posedge clk_i, negedge arstn_i) begin
          if (~arstn_i)
            available_write_space <= 1'b1;
          else begin
            if(rst_i)
              available_write_space <= 1'b1;
            else begin
              if (space >= FIFO_THRESHOLD[INDEX_LENGTH:0])
                available_write_space <= 1'b1;
              else
                available_write_space <= 1'b0;
            end
          end
        end
        wire  load = valid_int[head_int]; // the fifo has loaded data
        assign  status_o  = {load, available_write_space, space};
      end
      3'b110: begin
        wire  full = available_int[INDEX_LENGTH]; // signals that the FIFO is full
        wire  load = valid_int[head_int]; // the fifo has loaded data
        assign  status_o  = {load, full, space};
      end
      3'b111: begin
        reg available_write_space;  // bit that signals if there is avaialble space to write data in the transmit FIFO
        always @ (posedge clk_i, negedge arstn_i) begin
          if (~arstn_i)
            available_write_space <= 1'b1;
          else begin
            if(rst_i)
              available_write_space <= 1'b1;
            else begin
              if (space >= FIFO_THRESHOLD[INDEX_LENGTH:0])
                available_write_space <= 1'b1;
              else
                available_write_space <= 1'b0;
            end
          end
        end
        wire  full = available_int[INDEX_LENGTH]; // signals that the FIFO is full
        wire  load = valid_int[head_int]; // the fifo has loaded data
        assign  status_o  = {load, full, available_write_space, space};
      end
    endcase
  endgenerate

endmodule // axi_internal_fifo

`default_nettype wire
