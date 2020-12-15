 /* -----------------------------------------------------------------------------
 * Project Name   : DRAC
 * File           : uart_controller.v
 * Organization   : Barcelona Supercomputing Center, CIC-IPN
 * Author(s)      : Abraham J. Ruiz R. (aruiz)
 *                  Vatistas Kostalabros (vkostalamp)
 * Email(s)       : abraham.ruiz@bsc.es
 *                  vatistas.kostalabros@bsc.es
 * References     :
 * ------------------------------------------------------------------------------
 * Revision History
 *  Revision   | Author      | Commit | Description
 *  1.0        | aruiz       | *****  | First IP version with Avalon-Bus interface
 *  2.0        | vkostalamp  | 236c2  | Contribution
 *  2.1        | aruiz       | *****  | Code refactoring with asynchronous reset
 * -----------------------------------------------------------------------------*/

`default_nettype none

/*
Title: uart_controller
This module serves as a controller of the transmitter and receiver modules that communicate with the external UART chip.
It contains an FSM for this reason and it also instantiates the respective uart_transmitter and uart_receiver modules.
*/
module uart_controller
# (
    parameter DATA_UART = 8,  // uart data size
    parameter DATA_SIZE = 32, // reg data size
    parameter DIV_SIZE  = 16  // freq div size
  )
(
    input   wire                  clk_i,                      // clock signal
    input   wire                  rstn_i,                     // reset signal
    input   wire                  uart_en_i,                  // enable signal
    input   wire                  uart_stop_bits_i,           // the stop bits configuration provided by the user
    input   wire                  uart_parity_bit_i,          // the parity enable configuration
    input   wire                  uart_parity_bit_mode_i,     // the parity bit mode
    input   wire [DIV_SIZE-1:0]   uart_baudrate_div_i,        // the baudrate divisor value to compute the signal sampling
    input   wire                  uart_rx_i,                  // the incoming bit received
    output  wire                  uart_tx_o,                  // the bit to send
    output  wire [DATA_UART-1:0]  rx_data_o,                  // the data packet received
    output  wire                  rx_push_o,                  // push data to the receive FIFO
    input   wire                  tx_load_i,                  // available data to load from transmit FIFO
    input   wire                  tx_full_i,                  // transmit FIFO is full
    input   wire [DATA_UART-1:0]  tx_data_i,                  // the data packet to transmit
    output  reg                   tx_pull_o                   // pull fro the transmit FIFO
);

  /* regs and wires */
  reg   [DATA_UART-1:0] tx_data_int;
  reg                   tx_send_int;
  wire                  tx_ready_int;
  wire                  tx_busy;


  /* tx controller */
  localparam  ResetState  = 3'b000;
  localparam  IdleState   = 3'b011;
  localparam  SendState   = 3'b101;
  reg [2:0] state;

  /*
    Always description:
    The FSM controlling the transmitting of the data from the transmitter FIFO to the transmitter module in order to be send through the external UART interface.
  */
  always @ (posedge clk_i, negedge rstn_i)    begin
    if(~rstn_i) begin
      tx_data_int <=  {DATA_UART{1'b0}};
      tx_send_int <=  1'b0;
      tx_pull_o   <=  1'b0;
      state       <=  ResetState;
    end
    else begin
      case(state)
          ResetState:    begin
            tx_data_int <=  {DATA_UART{1'b0}};
            tx_send_int <=  1'b0;
            tx_pull_o   <=  1'b0;
            state       <=  IdleState;
          end
          IdleState:    begin
            if(tx_load_i & (~tx_busy))    begin
              tx_data_int <=  tx_data_i;
              tx_send_int <=  1'b1;
              tx_pull_o   <=  1'b1;
              state       <=  SendState;
            end
          end
          SendState:    begin
            if (tx_ready_int) begin
              state <=  IdleState;
            end
            if(tx_busy) begin
              tx_send_int <=  1'b0;
            end
            tx_pull_o <= 1'b0;
          end
          default: state <= ResetState;
      endcase
    end
  end

  /* uart receiver */
  uart_receiver
    # (
        .DATA_UART  (DATA_UART),
        .DIV_SIZE   (DIV_SIZE)
      )
    uart_receiver_inst (
        .clk_i        (clk_i),
        .rstn_i       (rstn_i),
        .en_i         (uart_en_i),
        .stop_bits_i  (uart_stop_bits_i),
        .parity_bit_i (uart_parity_bit_i),
        .baud_div_i   (uart_baudrate_div_i),
        .rx_i         (uart_rx_i),
        .rx_data_o    (rx_data_o),
        .rx_valid_o   (rx_push_o)
      );

  /* uart transmitter */
  uart_transmitter
    # (
        .DATA_UART  (DATA_UART),
        .DIV_SIZE   (DIV_SIZE)
      )
    uart_transmitter_inst (
        .clk_i              (clk_i),
        .rstn_i             (rstn_i),
        .en_i               (uart_en_i),
        .stop_bits_i        (uart_stop_bits_i),
        .parity_bit_i       (uart_parity_bit_i),
        .parity_bit_mode_i  (uart_parity_bit_mode_i),
        .baud_div_i         (uart_baudrate_div_i),
        .tx_o               (uart_tx_o),
        .tx_data_i          (tx_data_int),
        .tx_send_i          (tx_send_int),
        .tx_ready_o         (tx_ready_int),
        .busy_o             (tx_busy)
      );


endmodule

`default_nettype wire
