/* -------------------------------------------------------------------------------
 * Project Name   : DRAC
 * File           : axi_uart_top.v
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

`default_nettype none

/*
Title: uart_core
This is the top level file of the uart core. It contains two decoupled FSM's (one for reading and one for writing in order to fulfil the AXI protocol specs)
It also further instatiates the appropriate controller module as well as a receiver and transmitter FIFO that communicates with the AXI bus.
*/
module axi_uart_top (/*AUTOARG*/
   // Outputs
   axi_arready_o, axi_rid_o, axi_rdata_o, axi_rresp_o, axi_rvalid_o,
   axi_awready_o, axi_wready_o, axi_bid_o, axi_bresp_o, axi_bvalid_o,
   read_interrupt_o, uart_tx_o,
   // Inputs
   axi_aclk_i, axi_aresetn_i, axi_arid_i, axi_araddr_i, axi_arvalid_i,
   axi_rready_i, axi_awid_i, axi_awaddr_i, axi_awvalid_i, axi_wdata_i,
   axi_wstrb_i, axi_wvalid_i, axi_bready_i, uart_rx_i
   );

  /* includes */
  `include "axi_uart_defines.vh"  //..axi interface defines
  `include "my_defines.vh"        //..common define macros
  `include "axi_uart.vh"          //..uart custom register map & configuration bits

  /* local parameters */
  localparam  BYTE            = `_BYTE_;
  localparam  AXI_DATA_WIDTH  = `_AXI_UART_DATA_WIDTH_;
  localparam  AXI_ADDR_WIDTH  = `_AXI_UART_ADDR_WIDTH_;
  localparam  AXI_DIV_WIDTH   = `_AXI_UART_DIV_WIDTH_;
  localparam  AXI_ID_WIDTH    = `_AXI_UART_ID_WIDTH_;
  localparam  AXI_RESP_WIDTH  = `_AXI_UART_RESP_WIDTH_;
  localparam  AXI_FIFO_DEPTH  = `_AXI_UART_FIFO_DEPTH_;
  localparam  AXI_FIFO_ADDR   = `_myLOG2_(AXI_FIFO_DEPTH-1);
  localparam  AXI_BYTE_NUM    = AXI_DATA_WIDTH/BYTE;
  localparam  AXI_LSB_WIDTH   = `_myLOG2_(AXI_BYTE_NUM-1);
  localparam  DEADLOCK_LIMIT  = 15;
  localparam  DEADLOCK_WIDTH  = `_myLOG2_(DEADLOCK_LIMIT-1);

  /* axi-uart parameters */
  localparam  UART_RBR                = `_UART_RBR_;
  localparam  UART_THR                = `_UART_THR_;
  localparam  UART_IER                = `_UART_IER_;
  localparam  UART_BAUD_DIVISOR       = `_UART_BAUD_DIVISOR_;
  localparam  UART_LCR                = `_UART_LCR_;
  localparam  UART_CONFIG_DLAB        = `_UART_CONFIG_DLAB_;
  localparam  UART_CONFIG_STOP_BITS   = `_UART_CONFIG_STOP_BITS_;
  localparam  UART_CONFIG_PARITY_EN   = `_UART_CONFIG_PARITY_EN_;
  localparam  UART_CONFIG_PARITY_MODE = `_UART_CONFIG_PARITY_MODE_;
  localparam  UART_LSR                = `_UART_LSR_;
  localparam  UART_LSR_DATA_READY     = `_UART_LSR_DATA_READY_;
  localparam  UART_LSR_TEMT           = `_UART_LSR_TEMT_;
  localparam  DATA_WIDTH_UART         = `_DATA_WIDTH_UART_;

  /* axi4-lite interface ports */
  input                             axi_aclk_i;
  input                             axi_aresetn_i;

  input       [AXI_ID_WIDTH-1:0]    axi_arid_i;
  input       [AXI_ADDR_WIDTH-1:0]  axi_araddr_i;
  input                             axi_arvalid_i;
  output reg                        axi_arready_o;

  output reg  [AXI_ID_WIDTH-1:0]    axi_rid_o;
  output reg  [AXI_DATA_WIDTH-1:0]  axi_rdata_o;
  output reg  [AXI_RESP_WIDTH-1:0]  axi_rresp_o;
  output reg                        axi_rvalid_o;
  input                             axi_rready_i;

  input       [AXI_ID_WIDTH-1:0]    axi_awid_i;
  input       [AXI_ADDR_WIDTH-1:0]  axi_awaddr_i;
  input                             axi_awvalid_i;
  output reg                        axi_awready_o;

  input       [AXI_DATA_WIDTH-1:0]  axi_wdata_i;
  input       [AXI_BYTE_NUM-1:0]    axi_wstrb_i;
  input                             axi_wvalid_i;
  output reg                        axi_wready_o;

  output reg  [AXI_ID_WIDTH-1:0]    axi_bid_o;
  output reg  [AXI_RESP_WIDTH-1:0]  axi_bresp_o;
  output reg                        axi_bvalid_o;
  input                             axi_bready_i;

  /* uart interrupt */
  output reg                        read_interrupt_o;

  /* uart interface ports */
  input                             uart_rx_i;
  output                            uart_tx_o;

  /* regs and wires */
  wire  [AXI_FIFO_ADDR:0]     rx_status_int;              //..rx status flag
  wire  [AXI_FIFO_ADDR+3:0]   tx_status_int;              //..tx status flag
  reg                         rx_fifo_reset_int;          //
  wire                        push_controller_rx_fifo;    //
  reg                         rx_fifo_pull_int;           //
  wire  [DATA_WIDTH_UART-1:0] data_rx_controller_fifo;    //..uart->fifo
  wire  [DATA_WIDTH_UART-1:0] rx_fifo_data_out_int;       //..fifo->axi
  wire  [AXI_FIFO_ADDR:0]     rx_fifo_space_int;          //
  reg                         tx_fifo_reset_int;          //
  reg                         tx_fifo_push_int;           //
  wire                        pull_controller_tx_fifo;    //
  wire                        load_tx_fifo_controller;    //
  wire                        tx_fifo_full_int;           //
  reg   [DATA_WIDTH_UART-1:0] tx_fifo_data_in_int;        //..axi->fifo
  wire  [DATA_WIDTH_UART-1:0] data_tx_fifo_controller;    //..fifo->uart
  wire  [AXI_FIFO_ADDR:0]     tx_fifo_available_int;      //
  wire  [AXI_FIFO_ADDR:0]     tx_fifo_space_int;          //
  wire                        available_write_space_int;  //
  reg   [AXI_DATA_WIDTH-1:0]  uart_config_reg_int;        //
  reg   [AXI_DATA_WIDTH-1:0]  uart_lsr_reg_int;           //
  wire                        uart_en_int;                //
  wire                        uart_parity_en_int;         //
  wire                        uart_parity_mode_int;       //
  wire                        uart_stop_bits_sel_int;     //
  wire                        uart_dlab_int;              //
  reg   [AXI_DIV_WIDTH-1:0]   uart_baudrate_div_int;      //Initial value 115200 bps
  /* Extra bit flag to enable/disable interrupts */
  reg                         uart_irq_en_int;            //
  reg   [AXI_DIV_WIDTH-1:0]   baudrate_divisor_int;       //Initial default value configured at 115200 bps for 50 MHz

  /*LCR*/
  assign  uart_en_int             = 1'b1; //TODO initialize in reset and check if functional. Otherwise remove enable functionality (enable would be always on)
  assign  uart_parity_en_int      = uart_config_reg_int[UART_CONFIG_PARITY_EN];
  assign  uart_parity_mode_int    = uart_config_reg_int[UART_CONFIG_PARITY_MODE];
  assign  uart_stop_bits_sel_int  = uart_config_reg_int[UART_CONFIG_STOP_BITS];
  assign  uart_dlab_int           = uart_config_reg_int[UART_CONFIG_DLAB];


  /*-----------------------------------------------------------------READ FSM---------------------------------------------------------------------------*/

  /* slave read bus interface ctrl */
  localparam  ResetReadState  = 4'b0000;  // 0
  localparam  ConfigReadState = 4'b0011;  // 3
  localparam  IdleReadState   = 4'b0101;  // 5
  localparam  AckReadState    = 4'b1001;  // 9
  reg [3:0] read_state;

  /*
  Always description:
  The FSM purposed to serve the read requests. The user can read the incoming through the UART data as well as the already present configuration information it needs by addressing the specific internal register.
  */
  always @ (posedge axi_aclk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i) begin
      axi_arready_o     <=  1'b0;
      axi_rdata_o       <=  {AXI_DATA_WIDTH{1'b0}};
      axi_rvalid_o      <=  1'b0;
      axi_rid_o         <=  {AXI_ID_WIDTH{1'b0}};
      rx_fifo_reset_int <=  1'b1;
      rx_fifo_pull_int  <=  1'b0;
      read_state        <=  ResetReadState;
    end
    else begin
      case(read_state)
        ResetReadState:        begin
          axi_arready_o     <=  1'b0;
          axi_rdata_o       <=  0;
          axi_rvalid_o      <=  1'b0;
          axi_rid_o         <=  {AXI_ID_WIDTH{1'b0}};
          rx_fifo_reset_int <=  1'b1;
          rx_fifo_pull_int  <=  1'b0;
          read_state        <=  ConfigReadState;
        end
        ConfigReadState:    begin
          axi_arready_o     <=  1'b1;
          axi_rresp_o       <=  2'b0;
          axi_rvalid_o      <=  1'b0;
          axi_rid_o         <=  {AXI_ID_WIDTH{1'b0}};
          rx_fifo_reset_int <=  1'b1;
          read_state        <=  IdleReadState;
        end
        IdleReadState:        begin
          if (axi_arvalid_i) begin
            case(axi_araddr_i[AXI_ADDR_WIDTH-1:AXI_LSB_WIDTH]) // 4 downto 2
              UART_RBR: begin //..read rx data
                if (uart_dlab_int == 0) begin //give access only of the specific bit is set to zero
                  axi_arready_o     <=  1'b0;
                  axi_rdata_o       <=  {{`_DIFF_SIZE_(AXI_DATA_WIDTH,DATA_WIDTH_UART){1'b0}},rx_fifo_data_out_int};
                  axi_rvalid_o      <=  1'b1;
                  axi_rresp_o       <=  2'b0;
                  rx_fifo_pull_int  <=  1'b01;
                  read_state        <=  AckReadState;
                end else begin
                  axi_arready_o     <=  1'b0;
                  axi_rresp_o       <=  2'b0;
                  axi_rvalid_o      <=  1'b1;
                  read_state        <=  AckReadState;
                end
              end
              UART_LSR:       begin
                axi_arready_o <=  1'b0;
                axi_rdata_o   <=  uart_lsr_reg_int;
                axi_rresp_o   <=  2'b0;
                axi_rvalid_o  <=  1'b1;
                read_state    <=  AckReadState;
              end
              default:    begin
                axi_arready_o <=  1'b0;
                axi_rresp_o   <=  2'b0;
                axi_rvalid_o  <=  1'b1;
                read_state    <=  AckReadState;
              end
            endcase
            axi_rid_o     <=  axi_arid_i;
          end else begin
            axi_arready_o <=  1'b1;
            axi_rresp_o   <=  2'b0;
            axi_rvalid_o  <=  1'b0;
            axi_rid_o     <=  {AXI_ID_WIDTH{1'b0}};
            read_state    <=  IdleReadState;
          end
        end
        AckReadState:    begin
          axi_arready_o     <=  1'b1;
          axi_rresp_o       <=  2'b0;
          axi_rvalid_o      <=  1'b0;
          axi_rid_o         <=  {AXI_ID_WIDTH{1'b0}};
          rx_fifo_pull_int  <=  1'b0;
          rx_fifo_reset_int <=  1'b0;
          read_state        <=  IdleReadState;
        end
        default: read_state <= ResetReadState;
      endcase
    end
  end


  /*-----------------------------------------------------------------WRITE FSM---------------------------------------------------------------------------*/

  /* slave write bus interface ctrl */
  localparam  ResetWriteState = 3'b000; // 0 //
  localparam  IdleWriteState  = 3'b011; // 3 //
  localparam  AckWriteState   = 3'b101; // 5 //
  reg [2:0] write_state;

  /*
  Always description:
  The FSM purposed to serve the write requests. By addressing the correct internal registers the user can define a new configuration (parity mode, # of start/stop bits e.tc)
  as well as to write data to be transmitted serially through the UART
  */
  always @ (posedge axi_aclk_i, negedge axi_aresetn_i)    begin
    if(~axi_aresetn_i) begin
      axi_awready_o         <=  1'b0;
      axi_wready_o          <=  1'b0;
      axi_bvalid_o          <=  1'b0;
      axi_bresp_o           <=  2'b0;
      axi_bid_o             <=  {AXI_ID_WIDTH{1'b0}};
      tx_fifo_reset_int     <=  1'b1;
      tx_fifo_push_int      <=  1'b0;
      uart_baudrate_div_int <=  434;
      baudrate_divisor_int  <=  434;
      uart_config_reg_int   <=  0;
      uart_irq_en_int       <=  1'b0;
      write_state           <=  ResetWriteState;
    end
    else begin
      case(write_state)
        ResetWriteState:        begin
          axi_awready_o         <=  1'b0;
          axi_wready_o          <=  1'b0;
          axi_bvalid_o          <=  1'b0;
          axi_bresp_o           <=  2'b0;
          axi_bid_o             <=  {AXI_ID_WIDTH{1'b0}};
          tx_fifo_reset_int     <=  1'b1;
          tx_fifo_push_int      <=  1'b0;
          uart_baudrate_div_int <=  434;
          baudrate_divisor_int  <=  434;
          uart_config_reg_int   <=  0;
          uart_irq_en_int       <=  1'b0;
          write_state           <=  IdleWriteState;
        end
        IdleWriteState:        begin
          if (axi_wvalid_i & axi_awvalid_i) begin
            case(axi_awaddr_i[AXI_ADDR_WIDTH-1:AXI_LSB_WIDTH])
              UART_THR:               begin
                if (uart_dlab_int == 0 & ~tx_fifo_full_int) begin //give access only of the specific bit is set to zero added the check not to send if the fifo is allready full
                  axi_awready_o       <=  1'b1;//0;
                  axi_wready_o        <=  1'b1;//0;
                  axi_bvalid_o        <=  1'b1;
                  axi_bresp_o         <=  2'b0;
                  tx_fifo_push_int    <=  1'b1;
                  tx_fifo_data_in_int <=  axi_wdata_i[DATA_WIDTH_UART-1:0];
                  write_state         <=  AckWriteState;
                end else begin
                  axi_awready_o       <=  1'b1;
                  axi_wready_o        <=  1'b1;
                  axi_bvalid_o        <=  1'b1;
                  axi_bresp_o         <=  2'b0;
                  write_state         <=  AckWriteState;
                end
              end
              UART_IER:            begin
                if (uart_dlab_int == 0) begin //give access only of the specific bit is set to zero
                  axi_awready_o   <=  1'b1;
                  axi_wready_o    <=  1'b1;
                  axi_bvalid_o    <=  1'b1;
                  axi_bresp_o     <=  2'b0;
                  uart_irq_en_int <=  axi_wdata_i[0];
                  write_state     <=  AckWriteState;
                end else begin
                  axi_awready_o   <=  1'b1;
                  axi_wready_o    <=  1'b1;
                  axi_bvalid_o    <=  1'b1;
                  axi_bresp_o     <=  2'b0;
                  write_state     <=  AckWriteState;
                end
              end
              UART_BAUD_DIVISOR:  begin
                if (uart_dlab_int == 1) begin //give access only of the specific bit is set to one
                  axi_awready_o         <=  1'b1;
                  axi_wready_o          <=  1'b1;
                  axi_bvalid_o          <=  1'b1;
                  axi_bresp_o           <=  2'b0;
                  baudrate_divisor_int  <=  axi_wdata_i;
                  write_state           <=  AckWriteState;
                end else begin
                  axi_awready_o         <=  1'b1;
                  axi_wready_o          <=  1'b1;
                  axi_bvalid_o          <=  1'b1;
                  axi_bresp_o           <=  2'b0;
                  write_state           <=  AckWriteState;
                end
              end
              UART_LCR:            begin
                axi_awready_o       <=  1'b1;
                axi_wready_o        <=  1'b1;
                axi_bvalid_o        <=  1'b1;
                axi_bresp_o         <=  2'b0;
                uart_config_reg_int <=  axi_wdata_i;
                write_state         <=  AckWriteState;
              end
              default:    begin    // The case where the address is not present but we doo not want the AXI bus to hang
                axi_awready_o <=  1'b1;
                axi_wready_o  <=  1'b1;
                axi_bvalid_o  <=  1'b1;
                axi_bresp_o   <=  2'b0;
                write_state   <=  AckWriteState;
              end
            endcase
            axi_bid_o   <=  axi_awid_i;
          end else begin
            axi_awready_o <=  1'b0;
            axi_wready_o  <=  1'b0;
            axi_bvalid_o  <=  1'b0;
            axi_bresp_o   <=  2'b0;
            axi_bid_o     <=  {AXI_ID_WIDTH{1'b0}};
            write_state   <=  IdleWriteState;
          end
        end
        AckWriteState:    begin
          axi_awready_o         <=  1'b0;
          axi_wready_o          <=  1'b0;
          axi_bvalid_o          <=  1'b0;
          axi_bresp_o           <=  2'b0;
          axi_bid_o             <=  {AXI_ID_WIDTH{1'b0}};
          tx_fifo_push_int      <=  1'b0;
          tx_fifo_reset_int     <=  1'b0;
          uart_baudrate_div_int <=  baudrate_divisor_int;
          write_state           <=  IdleWriteState;
        end
        default: write_state <= ResetWriteState;
      endcase
    end
  end

  /* uart controller */
  uart_controller
    # (
        .DATA_UART  (DATA_WIDTH_UART),
        .DATA_SIZE  (AXI_DATA_WIDTH),
        .DIV_SIZE   (AXI_DIV_WIDTH)
      )
    uart_controller_inst (
        /* flow control */
        .clk_i                  (axi_aclk_i),
        .rstn_i                 (axi_aresetn_i),

        /* uart configuration */
        .uart_en_i              (uart_en_int),
        .uart_stop_bits_i       (uart_stop_bits_sel_int),
        .uart_parity_bit_i      (uart_parity_en_int),
        .uart_parity_bit_mode_i (uart_parity_mode_int),
        .uart_baudrate_div_i    (uart_baudrate_div_int),

        /* rx */
        .uart_rx_i              (uart_rx_i),
        .rx_data_o              (data_rx_controller_fifo),
        .rx_push_o              (push_controller_rx_fifo),

        /* tx */
        .uart_tx_o              (uart_tx_o),
        .tx_load_i              (load_tx_fifo_controller),
        .tx_full_i              (tx_fifo_full_int),
        .tx_data_i              (data_tx_fifo_controller),
        .tx_pull_o              (pull_controller_tx_fifo)
      );

  /* rx fifo */
  axi_internal_fifo
    # (
        .FIFO_SIZE    (AXI_FIFO_DEPTH),
        .DATA_SIZE    (DATA_WIDTH_UART),
        .INDEX_LENGTH (AXI_FIFO_ADDR),
        .PORT_EN      (3'b000)  //..flag port enable [3-bits]: load | full | available_space
      )
    axi_internal_fifo_rx_inst (
        .clk_i    (axi_aclk_i),               // clock signal
        .arstn_i  (axi_aresetn_i),            // active-low asynchronous reset
        .rst_i    (rx_fifo_reset_int),        // active-high synchronous soft reset

        .push_i   (push_controller_rx_fifo),  // push a new entry into the rx fifo from receiver ctrl
        .pull_i   (rx_fifo_pull_int),         // pull the oldest entry from an axi read operation

        .data_i   (data_rx_controller_fifo),  // new entry data received from the rx ctrl
        .data_o   (rx_fifo_data_out_int),     // oldest entry data to be read by the axi controller

        .status_o (rx_status_int)             // status flag
      );

  assign rx_fifo_space_int  = rx_status_int;

  /*
  The next always block serves as a way to fill the TEMT and DATA_READY internal UART registers. It also propagates the read interrupt from the UART interface
  to notify the core that there are data to be read.
  */
  always @ (posedge axi_aclk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i)    begin
      read_interrupt_o                        <=  0;
      uart_lsr_reg_int                        <=  32'h00000060; //..initial value for LSR
    end
	 else begin
      read_interrupt_o                        <=  ~rx_fifo_space_int[AXI_FIFO_ADDR] & uart_irq_en_int ;
//      uart_lsr_reg_int                        =  32'h00000000;
      uart_lsr_reg_int[UART_LSR_TEMT]         <=  available_write_space_int;
      uart_lsr_reg_int[UART_LSR_DATA_READY]   <=  ~rx_fifo_space_int[AXI_FIFO_ADDR] & uart_irq_en_int ;
    end
  end

  /* tx fifo */
  axi_internal_fifo
    # (
        .FIFO_SIZE    (AXI_FIFO_DEPTH),
        .DATA_SIZE    (DATA_WIDTH_UART),
        .INDEX_LENGTH (AXI_FIFO_ADDR),
        .PORT_EN      (3'b111)  //..flag port enable [3-bits]: load | full | available_space
      )
    axi_internal_fifo_tx_inst    (
        .clk_i                    (axi_aclk_i),                 // clock signal
        .arstn_i                  (axi_aresetn_i),              // active-low asynchronous reset
        .rst_i                    (tx_fifo_reset_int),          // active-high synchronous soft reset

        .push_i                   (tx_fifo_push_int),           // push new entry to tx fifo
        .pull_i                   (pull_controller_tx_fifo),    // pull the oldest entry from tx fifo

        .data_i                   (tx_fifo_data_in_int),        // new entry data
        .data_o                   (data_tx_fifo_controller),    // oldest entry data

        .status_o                 (tx_status_int)               // status flag
  );

  assign tx_fifo_space_int          = tx_status_int[AXI_FIFO_ADDR:0];
  assign load_tx_fifo_controller    = tx_status_int[AXI_FIFO_ADDR+3];
  assign tx_fifo_full_int           = tx_status_int[AXI_FIFO_ADDR+2];
  assign available_write_space_int  = tx_status_int[AXI_FIFO_ADDR+1];

endmodule

`default_nettype wire
