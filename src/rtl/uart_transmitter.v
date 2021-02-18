/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : uart_transmitter.v
 * Description    : UART TX interface
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
Title: uart_transmitter
Module responsible to transmitting the data from the AXI BUS to the UART interface. This module instantiates also a parity bit computation module in order to form the whole UART data packet.
Lastly it also inserts the start and stop bits to the correct position in the data packet.
*/
module uart_transmitter
# (
    parameter DIV_SIZE  = 16, // size of the baudrate divisor
    parameter DATA_UART = 8   // size of he data UART packet
  )
(
  input   wire                  clk_i,              // clock signal
  input   wire                  rstn_i,             // reset signal
  input   wire                  en_i,               // enable signal
  input   wire                  stop_bits_i,        // number of required stop bits
  input   wire                  parity_bit_i,       // signal enabling/disabling parity bit
  input   wire                  parity_bit_mode_i,  // the mode of parity <0=odd>/<1=even>
  input   wire  [DIV_SIZE-1:0]  baud_div_i,         // Baud rate value
  output  wire                  tx_o,               // the transmitted bit
  input   wire  [DATA_UART-1:0] tx_data_i,          // the parallel incoming bits to be sent serially
  input   wire                  tx_send_i,          // signals the sending of a bit
  output  wire                  tx_ready_o,         // transmitter is ready to receive the next bits to send from the controller
  output  wire                  busy_o              // indicates that the transmitter is busy
);

  /* regs and wires */
  reg                   tx, tx_d;                                   // the transmitted bit
  reg                   tx_ready, tx_ready_d;                       // transmitter is ready to receive the next bits to send from the controller
  reg                   busy, busy_d;                               // indicates that the transmitter is busy
  reg   [DATA_UART-1:0] tx_data_int, tx_data_int_d;                 // register holding the bits to be transmitted
  reg   [3:0]           bitcount_int, bitcount_int_d;               // counter holding the number of data bits transmitted in each packet
  reg   [1:0]           tx_stop_bits_int, tx_stop_bits_int_d;       // counter holding the number of stop bits allready transmitted in each packet
  wire                  parity_bit_int;                             // the parity bit to be transmitted
  reg   [DIV_SIZE-1:0]  counter_int, counter_int_d;                 // counter holding clock cycles to signal the sending of a bit according to the baudrate value
  reg                   tx_sample_reset_int, tx_sample_reset_int_d; // signal sent to the parity computation module to signal the arrival of new data
  reg                   tx_sample_data_int, tx_sample_data_int_d;   // the bit sent to the parity computatio module
  reg                   tx_sample_valid_int, tx_sample_valid_int_d; // signal indicating the validity of the bit sent to the parity bit computation module

  /* fsm parameters */
  localparam  ResetState  = 5'b00000; //reset state
  localparam  IdleState   = 5'b00011; //waiting for incoming tx data
  localparam  DataState   = 5'b00101; // receive data bits
  localparam  ParityState = 5'b01001; // receive parity bit
  localparam  StopState   = 5'b10001; // receive stop bits
  reg [4:0] state, state_d;

  /*
    Always description:
    Transmitter fsm controlling the sending of the parallel bits to a serial manner
    It is also responsible to insert the necessary start, stop and parity bits to the stream
  */
  // --- fsm: comb
  always @ (*) begin
    tx_d                  = tx;
    tx_data_int_d         = tx_data_int;
    counter_int_d         = counter_int;
    bitcount_int_d        = bitcount_int;
    tx_sample_reset_int_d = tx_sample_reset_int;
    tx_sample_data_int_d  = tx_sample_data_int;
    tx_sample_valid_int_d = tx_sample_valid_int;
    tx_stop_bits_int_d    = tx_stop_bits_int;
    tx_ready_d            = tx_ready;
    busy_d                = busy;
    state_d               = state;
    case(state)
      ResetState: begin
        tx_d                  = 1'b1;
        tx_data_int_d         = {(DATA_UART){1'b0}};
        counter_int_d         = {DIV_SIZE{1'b0}};
        bitcount_int_d        = 4'b0;
        tx_sample_reset_int_d = 1'b1;
        tx_sample_data_int_d  = 1'b0;
        tx_sample_valid_int_d = 1'b0;
        tx_stop_bits_int_d    = 2'b0;
        tx_ready_d            = 1'b0;
        busy_d                = 1'b0;
        state_d               = IdleState;
      end
      IdleState: begin
        counter_int_d         = {DIV_SIZE{1'b0}};
        bitcount_int_d        = 4'b0;
        tx_sample_valid_int_d = 1'b0;
        tx_stop_bits_int_d    = 2'b0;
        tx_ready_d            = 1'b0;
        if(tx_send_i & en_i) begin
          tx_d                  = 1'b0;
          tx_data_int_d         = tx_data_i;
          tx_sample_reset_int_d = 1'b0;
          busy_d                = 1'b1;
          state_d               = DataState;
        end
      end
      DataState: begin
        if(counter_int >= baud_div_i) begin
          if(bitcount_int == DATA_UART-1) begin
            case(parity_bit_i)
              0:  state_d = StopState;
              1:  state_d = ParityState;
            endcase
          end
          tx_d                          = tx_data_int[0];
          tx_data_int_d[DATA_UART-2:0]  = tx_data_int[DATA_UART-1:1];
          tx_sample_data_int_d          = tx_data_int[0];
          tx_sample_valid_int_d         = 1'b1;
          bitcount_int_d                = bitcount_int + 4'd1;
          counter_int_d                 = {DIV_SIZE{1'b0}};
        end else begin
          tx_sample_valid_int_d = 1'b0;
          counter_int_d         = counter_int + {{(DIV_SIZE-1){1'b0}},1'b1};
         end
      end
      ParityState: begin
        if(counter_int >= baud_div_i) begin
          tx_d          = parity_bit_int;
          counter_int_d = {DIV_SIZE{1'b0}};
          state_d       = StopState;
        end else begin
          counter_int_d = counter_int + {{(DIV_SIZE-1){1'b0}},1'b1};
        end
        tx_sample_valid_int_d = 1'b0;
      end
      StopState: begin
        if(counter_int >= baud_div_i) begin
          case(stop_bits_i)
            0: begin
              if(tx_stop_bits_int == 1) begin
                tx_ready_d    = 1'b1;
                busy_d        = 1'b0;
                state_d       = IdleState;
              end
            end
            1: begin
              if(tx_stop_bits_int == 2) begin
                tx_ready_d    = 1'b1;
                busy_d        = 1'b0;
                state_d       = IdleState;
              end
            end
          endcase
          tx_d                = 1'b1;
          tx_stop_bits_int_d  = tx_stop_bits_int + 2'd1;
          counter_int_d       = {DIV_SIZE{1'b0}};
        end else begin
          counter_int_d = counter_int + {{(DIV_SIZE-1){1'b0}},1'b1};
        end
        tx_sample_valid_int_d = 1'b0;
        tx_sample_reset_int_d = 1'b1;
      end
      default: begin
        tx_d                  = 1'b1;
        tx_data_int_d         = {(DATA_UART){1'b0}};
        counter_int_d         = {DIV_SIZE{1'b0}};
        bitcount_int_d        = 4'b0;
        tx_sample_reset_int_d = 1'b0;
        tx_sample_data_int_d  = 1'b0;
        tx_sample_valid_int_d = 1'b0;
        tx_stop_bits_int_d    = 2'b0;
        tx_ready_d            = 1'b0;
        busy_d                = 1'b1;
        state_d               = ResetState;
      end
    endcase
  end

  // --- fsm: seq
  always @ (posedge clk_i, negedge rstn_i) begin
    if(~rstn_i) begin
      tx                  <= 1'b1;
      tx_data_int         <= {(DATA_UART){1'b0}};
      counter_int         <= {DIV_SIZE{1'b0}};
      bitcount_int        <= 4'b0;
      tx_sample_reset_int <= 1'b0;
      tx_sample_data_int  <= 1'b0;
      tx_sample_valid_int <= 1'b0;
      tx_stop_bits_int    <= 2'b0;
      tx_ready            <= 1'b0;
      busy                <= 1'b1;
      state               <= ResetState;
    end
    else begin
      tx                  <= tx_d;
      tx_data_int         <= tx_data_int_d;
      counter_int         <= counter_int_d;
      bitcount_int        <= bitcount_int_d;
      tx_sample_reset_int <= tx_sample_reset_int_d;
      tx_sample_data_int  <= tx_sample_data_int_d;
      tx_sample_valid_int <= tx_sample_valid_int_d;
      tx_stop_bits_int    <= tx_stop_bits_int_d;
      tx_ready            <= tx_ready_d;
      busy                <= busy_d;
      state               <= state_d;
    end
  end

  /* calculate parity bit */
  uart_parity_bit_compute
    uart_parity_bit_compute_tx_inst (
        .clk_i        (clk_i),                // clock
        .arstn_i      (rstn_i),               // asynchronou reset (active low)
        .rst_i        (tx_sample_reset_int),  // soft reset (active high)
        .data_i       (tx_sample_data_int),   // data
        .valid_i      (tx_sample_valid_int),  // valid data
        .mode_i       (parity_bit_mode_i),    // <0=even>/<1=odd>
        .parity_bit_o (parity_bit_int)        // parity bit
      );

  /* output assignments */
  assign tx_o       = tx;
  assign tx_ready_o = tx_ready;
  assign busy_o     = busy;

endmodule

`default_nettype wire
