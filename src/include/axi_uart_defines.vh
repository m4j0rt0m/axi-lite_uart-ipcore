/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart_defines.vh
 * Description    : AXI4-Lite UART parameters defines
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

  `ifndef _AXI_UART_DEFINES_H_
  `define _AXI_UART_DEFINES_H_

  `define _AXI_UART_DATA_WIDTH_ 32
  `define _AXI_UART_ADDR_WIDTH_ 5
  `define _AXI_UART_FIFO_DEPTH_ 32
  `define _AXI_UART_DIV_WIDTH_  32
  `define _AXI_UART_RESP_WIDTH_ 2
  `define _AXI_UART_ID_WIDTH_   12

  `define _AXI_UART_DEADLOCK_   2**20

  `endif
