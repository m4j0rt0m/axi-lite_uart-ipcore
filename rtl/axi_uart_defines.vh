/* -------------------------------------------------------------------------------
 * Project Name   : DRAC
 * File           : axi_uart_defines.vh
 * Organization   : Barcelona Supercomputing Center, CIC-IPN
 * Author(s)      : Abraham J. Ruiz R. (aruiz)
 *                  Vatistas Kostalabros (vkostalamp)
 * Email(s)       : abraham.ruiz@bsc.es
 *                  vatistas.kostalabros@bsc.es
 * References     :
 * -------------------------------------------------------------------------------
 * Revision History
 *  Revision   | Author      | Commit | Description
 *  1.0        | aruiz       | *****  | First IP version with Avalon-Bus interface
 *  2.0        | vkostalamp  | 236c2  | Contribution
 *  2.1        | aruiz       | *****  | Code refactoring with asynchronous reset
 * -----------------------------------------------------------------------------*/

  `ifndef _AXI_UART_DEFINES_
  `define _AXI_UART_DEFINES_

  `define _AXI_UART_DATA_WIDTH_ 32
  `define _AXI_UART_ADDR_WIDTH_ 5
  `define _AXI_UART_FIFO_DEPTH_ 32
  `define _AXI_UART_DIV_WIDTH_  32
  `define _AXI_UART_RESP_WIDTH_ 2
  `define _AXI_UART_ID_WIDTH_   12

  `endif
