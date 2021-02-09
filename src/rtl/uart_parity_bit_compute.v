/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : uart_parity_bit_compute.v
 * Description    : Generates the odd/even parity bit for the next rx/tx data packet
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
Title: uart_parity_bit_compute
This module generates the next odd/even parity bit.
*/
module uart_parity_bit_compute (
  input   wire  clk_i,        // clock signal
  input   wire  arstn_i,      // asynchronous reset signal (active low)
  input   wire  rst_i,        // soft reset (active high)
  input   wire  data_i,       // incoming bit
  input   wire  valid_i,      // valid data signal
  input   wire  mode_i,       // parity mode selection <0=odd>/<1=even>
  output  wire  parity_bit_o  // parity bit output
);
  reg counter_int;  // signal that gets the value "1" in even appearances of bit "1" and the value "0" in odd appearances of bit "1"

  /*
    Always description:
    The following code block is responsible to alternate the value of the counter at every valid data that the module is fed with. This way it alternates netween the even and odd parity bit value.
  */
  always @ (posedge clk_i, negedge arstn_i) begin
    if(~arstn_i) begin
      counter_int <=  1'b0; // reset the counter signal
    end
    else begin
      if(rst_i)
        counter_int   <=  1'b0;
      else if(valid_i & data_i)       // if we have a valid incoming bit that is "1"
        counter_int <=  ~counter_int; // change the counter_int signal accordingly
    end
  end

  /*
    Assign description:
    if mode_i is 0 then ~counter_int is selected (odd parity) otherwise counter_int is selected (even parity)
  */
  assign  parity_bit_o = (~mode_i) ? ~counter_int : counter_int;

endmodule

`default_nettype wire
