/* -------------------------------------------------------------------------------
 * Project Name   : DRAC
 * File           : my_defines.vh
 * Organization   : Barcelona Supercomputing Center, CIC-IPN
 * Author(s)      : Abraham J. Ruiz R. (aruiz)
 * Email(s)       : abraham.ruiz@bsc.es
 * References     :
 * -------------------------------------------------------------------------------
 * Revision History
 *  Revision   | Author      | Commit | Description
 *  1.0        | aruiz       | *****  | First macro defines version
 * -----------------------------------------------------------------------------*/

  `ifndef _MY_DEFINES_
  `define _MY_DEFINES_

  //..difference between two sizes
  `define _DIFF_SIZE_(a, b) a-b

  //..log2(x) used for address width calculation
  `define _myLOG2_(x) \
    (x  <=  1)          ? 1   : \
    (x  <=  3)          ? 2   : \
    (x  <=  7)          ? 3   : \
    (x  <=  15)         ? 4   : \
    (x  <=  31)         ? 5   : \
    (x  <=  63)         ? 6   : \
    (x  <=  127)        ? 7   : \
    (x  <=  255)        ? 8   : \
    (x  <=  511)        ? 9   : \
    (x  <=  1023)       ? 10  : \
    (x  <=  2047)       ? 11  : \
    (x  <=  4095)       ? 12  : \
    (x  <=  8191)       ? 13  : \
    (x  <=  16383)      ? 14  : \
    (x  <=  32767)      ? 15  : \
    (x  <=  65535)      ? 16  : \
    (x  <=  131071)     ? 17  : \
    (x  <=  262143)     ? 18  : \
    (x  <=  524287)     ? 19  : \
    (x  <=  1048575)    ? 20  : \
    (x  <=  2097151)    ? 21  : \
    (x  <=  4194303)    ? 22  : \
    (x  <=  8388607)    ? 23  : \
    (x  <=  16777215)   ? 24  : \
    (x  <=  33554431)   ? 25  : \
    (x  <=  67108863)   ? 26  : \
    (x  <=  134217727)  ? 27  : \
    (x  <=  268435455)  ? 28  : \
    (x  <=  536870911)  ? 29  : \
    (x  <=  1073741823) ? 30  : \
    (x  <=  2147483647) ? 31  : \
    (x  <=  4294967295) ? 32  : \
    -1

  //..some common defines
  `define _BYTE_  8

  `endif
