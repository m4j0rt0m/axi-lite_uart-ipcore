/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : uart_receiver.v
 * Description    : UART RX interface
 * Organization   : BSC; CIC-IPN
 * Author(s)      : Abraham J. Ruiz R. (aruiz) (https://github.com/m4j0rt0m)
 *                  Vatistas Kostalabros (vkostalamp)
 * Email(s)       : abraham.ruiz@bsc.es; abraham.j.ruiz.r@gmail.com
 *                  vatistas.kostalabros@bsc.es
 * References     :
 * ------------------------------------------------------------------------------
 * Revision History
 *  Revision   | Author      | Description
 *  1.0        | aruiz       | First IP version with Avalon-Bus interface
 *  2.0        | vkostalamp  | AXI-Bus porting and documentation
 *  2.1        | aruiz       | Code refactoring with asynchronous reset
 *  3.0        | aruiz       | Two clock domains integration, a fixed
 *             |             | clock and an axi-bus clock
 * -----------------------------------------------------------------------------*/

`default_nettype none

/*
Title: uart_receiver
FSM controlling the receiving of data bits from the external UART interface.
*/
module uart_receiver
# (
    parameter DIV_SIZE    = 16, // The size of the baudrate divisor
    parameter START_BIT   = 1,  // Number of start bits
    parameter DATA_UART   = 8,  // how many bits in each UART data packet
    parameter PARITY_BIT  = 1,  // Number of parity bits
    parameter STOP_BITS   = 1,  // Number of stop bits
    parameter DATA_SIZE   = START_BIT + DATA_UART + PARITY_BIT + STOP_BITS  // max data size
  )
(
  input   wire                  clk_i,        // clock
  input   wire                  rstn_i,       // reset
  input   wire                  en_i,         // uart enable
  input   wire                  stop_bits_i,  // uart stop bits <0=1bit>/<1=2bits>
  input   wire                  parity_bit_i, // uart parity bit enable
  input   wire  [DIV_SIZE-1:0]  baud_div_i,   // baudrate freq_div value
  input   wire                  rx_i,         // rx input
  output  wire  [DATA_UART-1:0] rx_data_o,    // rx data output
  output  wire                  rx_valid_o    // rx valid output
);

  /* regs and wires */
  reg   [DATA_UART-1:0] rx_data, rx_data_d;                   // rx data output
  reg                   rx_valid, rx_valid_d;                 // rx valid output
  reg   [DIV_SIZE-1:0]  counter_int, counter_int_d;           // sampling counter
  reg   [3:0]           bitcount_int, bitcount_int_d;         // sampling bit count
  reg   [2:0]           rx_trigger_int;                       // metastability rx tripple trigger latching
  reg   [DATA_UART-1:0] rx_data_int, rx_data_int_d;           // sampling rx data reg
  reg                   rx_stop_bits_int, rx_stop_bits_int_d; // checked first stop bit flag <0=false>/<1=true>

  /* fsm parameters */
  localparam  ResetState      = 6'b000000;  // reset state
  localparam  IdleState       = 6'b000011;  // waiting for incoming rx data
  localparam  StartBitState   = 6'b000101;  // receive start bit
  localparam  DataUartState   = 6'b001001;  // receive data bits
  localparam  ParityBitState  = 6'b010001;  // receive parity bit
  localparam  StopBitsState   = 6'b100001;  // receive stop bits
  reg [5:0] state, state_d;

  /*
    Always description:
     stable rx
     Regiters to stabilize the incoming received bits
  */
  always @ (posedge clk_i, negedge rstn_i) begin
    if(~rstn_i) begin
      rx_trigger_int      <= 3'b111;
    end else begin
      rx_trigger_int[0]   <= rx_i;
      rx_trigger_int[2:1] <= rx_trigger_int[1:0];
    end
  end
  wire rx = rx_trigger_int[2]; // rx bit

  /*
    Always description:
    The receiver FSM responsible to read the data packet from the external UART interface and sample it correctly 
  */
  // --- fsm: comb
  always @ (*) begin
    counter_int_d       = counter_int;
    bitcount_int_d      = bitcount_int;
    rx_data_int_d       = rx_data_int;
    rx_stop_bits_int_d  = rx_stop_bits_int;
    rx_data_d           = rx_data;
    rx_valid_d          = rx_valid;
    state_d             = state;
    case(state)
      ResetState: begin     // "reset" fsm state
        counter_int_d       = {DIV_SIZE{1'b0}};
        bitcount_int_d      = 4'b0;
        rx_data_int_d       = {DATA_UART{1'b0}};
        rx_stop_bits_int_d  = 1'b0;
        rx_data_d           = {DATA_UART{1'b0}};
        rx_valid_d          = 1'b0;
        state_d             = IdleState;
      end
      IdleState: begin      // "idle" fsm state
        if(~rx & en_i) begin  // uart enabled and incoming data (start bit)
          counter_int_d = baud_div_i>>1;  // freq_div / 2
          state_d       = StartBitState;  // go to receive start bit
        end
        bitcount_int_d      = 4'b0; // reset bitcount_int
        rx_valid_d          = 1'b0; // no rx_data_int valid
        rx_stop_bits_int_d  = 1'b0; // reset checked fist stop bit flag
      end
      StartBitState: begin  // "receive start bit" fsm state
        if(counter_int >= baud_div_i-1) begin // freq_div reached //How does this part work???
          counter_int_d = 0;
          state_d       = DataUartState;
        end
        else
          counter_int_d = counter_int + 1;
      end
      DataUartState: begin  // "receive data bits" fsm state
        if(counter_int >= (baud_div_i-1)) begin // freq_div reached
          rx_data_int_d[DATA_UART-1]    = rx;
          rx_data_int_d[DATA_UART-2:0]  = rx_data_int[DATA_UART-1:1];
          bitcount_int_d                = bitcount_int + 4'b1;
          counter_int_d                 = {DIV_SIZE{1'b0}};
          if(bitcount_int == DATA_UART-1) begin // finished receiving data
            if(parity_bit_i) begin
              state_d = ParityBitState;
            end else begin
              state_d = StopBitsState;
            end
          end
        end
        else
          counter_int_d = counter_int + 1;
      end
      ParityBitState: begin // "receive parity bit" fsm state
        if(counter_int >= baud_div_i-1) begin // freq_div reached
          counter_int_d = 0;
          state_d       = StopBitsState;
        end
        else
          counter_int_d = counter_int + 1;
      end
      StopBitsState: begin  // "receive stop bits" fsm state
        if(counter_int >= (baud_div_i-1)) begin // freq_div reached
          case(stop_bits_i)
            0: begin    // 1 stop bit required
              rx_data_d   = rx_data_int;
              rx_valid_d  = 1'b1;
              state_d     = IdleState;
            end
            1: begin    // 2 stop bits required
              case(rx_stop_bits_int)
                0: begin  // latch another stop bit
                  rx_stop_bits_int_d  = 1'b1;
                  counter_int_d       = {DIV_SIZE{1'b0}};
                end
                1: begin  // return to idle state
                  rx_data_d   = rx_data_int;
                  rx_valid_d  = 1'b1;
                  state_d     = IdleState;
                end
              endcase
            end
          endcase
        end
        else
          counter_int_d = counter_int + 1;
      end
      default: begin
        counter_int_d       = {DIV_SIZE{1'b0}};
        bitcount_int_d      = 4'b0;
        rx_data_int_d       = {DATA_UART{1'b0}};
        rx_stop_bits_int_d  = 1'b0;
        rx_data_d           = {DATA_UART{1'b0}};
        rx_valid_d          = 1'b0;
        state_d             = ResetState;
      end
    endcase
  end

  // --- fsm: seq
  always @ (posedge clk_i, negedge rstn_i) begin
    if(~rstn_i) begin
      counter_int       <= {DIV_SIZE{1'b0}};
      bitcount_int      <= 4'b0;
      rx_data_int       <= {DATA_UART{1'b0}};
      rx_stop_bits_int  <= 1'b0;
      rx_data           <= {DATA_UART{1'b0}};
      rx_valid          <= 1'b0;
      state             <= ResetState;
    end
    else begin
      counter_int       <= counter_int_d;
      bitcount_int      <= bitcount_int_d;
      rx_data_int       <= rx_data_int_d;
      rx_stop_bits_int  <= rx_stop_bits_int_d;
      rx_data           <= rx_data_d;
      rx_valid          <= rx_valid_d;
      state             <= state_d;
    end
  end

  /* output assignments */
  assign rx_data_o  = rx_data;
  assign rx_valid_o = rx_valid;

endmodule

`default_nettype wire
