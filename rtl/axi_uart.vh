/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart.vh
 * Description    : AXI4-Lite UART Header file
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

  `ifndef _AXI_UART_H_
  `define _AXI_UART_H_

  // The receiver data register | UART_DATA_RX
  `define _UART_RBR_          0
  // The transmitter register | UART_DATA_TX
  `define _UART_THR_          0
  // The interrupt enable register | UART_IRQ_EN
  `define _UART_IER_          1
  //  Custom baud divisor register
  `define _UART_BAUD_DIVISOR_ 2

  /* LCR config bits */
  /* || 31 | 30.......5    |         4       |        3      |        2       |   1     |    0   || */
  /* ||     reserved       | parity_bit_mode | parity_bit_en | stop_bits(1/2) |  Word Length Set || */
  /*            0                    0                1               0           1          1   || = 0X0B */
  // Parity bit mode = <0 odd / 1 = even>
  // The Line Control register
  `define _UART_LCR_                3
  `define _UART_CONFIG_DLAB_        7
  // 0=1bit / 1=2bits
  `define _UART_CONFIG_STOP_BITS_   2
  //LCR[3]
  `define _UART_CONFIG_PARITY_EN_   3
  // 0=odd / 1=even
  `define _UART_CONFIG_PARITY_MODE_ 4

  /* LSR config bits */
  /* || 31 | 30.......7    |         6         |   5...1     |     0       || */
  /* ||     reserved       | transmitter empty |  reserved   | data ready  || */
  /* data ready = <0= All data is read / 1= Complete char has been received>       */
  /* transmiter empty = <0= THR contains data / 1=THR is empty> or above threshold */
  `define _UART_LSR_            5
  `define _UART_LSR_DATA_READY_ 0
  `define _UART_LSR_TEMT_       6

  /* axi uart parameters */
  `define _DATA_WIDTH_UART_ 8

  `endif
