# AXI4-Lite UART

![lint-verilator](https://github.com/m4j0rt0m/axi-lite_uart-ipcore/workflows/lint-verilator/badge.svg)
![synth-quartus](https://github.com/m4j0rt0m/axi-lite_uart-ipcore/workflows/synth-quartus/badge.svg)
![synth-yosys](https://github.com/m4j0rt0m/axi-lite_uart-ipcore/workflows/synth-yosys/badge.svg)

[TOC]

## Introduction

The IP core implements a subset of the Xilinx **AXI UART 16550 v2.0 LogiCORE IP** with some modifications.

## Features


## Overview

![](https://raw.githubusercontent.com/m4j0rt0m/axi-lite_uart-ipcore/develop/documentation/axi-uart.png)


## Register Space

### Register Address Map

| LCR (7) | Address Offset | Register Name | Access Type |         Description          |
|:-------:|:--------------:|:-------------:|:-----------:|:----------------------------:|
|    0    |     0x0000     |      RBR      |     RO      |   Receiver Buffer Register   |
|    0    |     0x0000     |      THR      |     WO      | Transmitter Holding Register |
|    0    |     0x0004     |      IER      |     WO      |  Interrupt Enable Register   |
|    1    |     0x0008     |   BAUD_DIV    |     WO      |    Divisor Latch Register    |
|    x    |     0x000C     |      LCR      |     WO      |    Line Control Register     |
|    x    |     0x0014     |      LSR      |     RO      |     Line Status Register     |


### Receiver Buffer Register


### Transmitter Holding Register


### Interrupt Enable Register


### Divisor Latch Register


### Line Control Register


### Line Status Register

