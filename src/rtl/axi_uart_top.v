/* -----------------------------------------------------------------------------
 * Project        : AXI-lite UART IP Core
 * File           : axi_uart_top.v
 * Description    : AXI4-Lite UART Slave Module
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
Title: axi_uart_top
This is the top level file of the axi-lite uart core. It contains two decoupled FSM's (one for reading and one for writing in order to fulfil the AXI protocol specs)
It also further instatiates the appropriate controller module as well as a receiver and transmitter FIFO that communicates with the AXI bus.
*/
module axi_uart_top (/*AUTOARG*/
   // Outputs
   axi_arready_o, axi_rid_o, axi_rdata_o, axi_rresp_o, axi_rvalid_o,
   axi_awready_o, axi_wready_o, axi_bid_o, axi_bresp_o, axi_bvalid_o,
   read_interrupt_o, uart_tx_o,
   // Inputs
   fixed_clk_i, axi_aclk_i, axi_aresetn_i, axi_arid_i, axi_araddr_i,
   axi_arvalid_i, axi_rready_i, axi_awid_i, axi_awaddr_i,
   axi_awvalid_i, axi_wdata_i, axi_wstrb_i, axi_wvalid_i,
   axi_bready_i, uart_rx_i
   );

  /* includes */
  `include "axi_uart_defines.vh"  //..axi interface defines
  `include "axi_uart.vh"          //..uart custom register map & configuration bits

  /* local parameters */
  localparam  BYTE            = 8;
  localparam  AXI_DATA_WIDTH  = `_AXI_UART_DATA_WIDTH_;
  localparam  AXI_ADDR_WIDTH  = `_AXI_UART_ADDR_WIDTH_;
  localparam  AXI_DIV_WIDTH   = `_AXI_UART_DIV_WIDTH_;
  localparam  AXI_ID_WIDTH    = `_AXI_UART_ID_WIDTH_;
  localparam  AXI_RESP_WIDTH  = `_AXI_UART_RESP_WIDTH_;
  localparam  AXI_FIFO_DEPTH  = `_AXI_UART_FIFO_DEPTH_;
  localparam  AXI_FIFO_ADDR   = $clog2(AXI_FIFO_DEPTH);
  localparam  AXI_BYTE_NUM    = AXI_DATA_WIDTH/BYTE;
  localparam  AXI_LSB_WIDTH   = $clog2(AXI_BYTE_NUM);
  localparam  DEADLOCK_LIMIT  = `_AXI_UART_DEADLOCK_;
  localparam  DEADLOCK_WIDTH  = $clog2(DEADLOCK_LIMIT);

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
  localparam  UART_LSR_THRE           = `_UART_LSR_THRE_;
  localparam  DATA_WIDTH_UART         = `_DATA_WIDTH_UART_;
  localparam  UART_BAUDRATE_DIV_INIT  = `_UART_BAUDRATE_DIV_INIT_;

  /* axi4-lite interface ports */
  input   wire                        fixed_clk_i;
  input   wire                        axi_aclk_i;
  input   wire                        axi_aresetn_i;

  input   wire  [AXI_ID_WIDTH-1:0]    axi_arid_i;
  input   wire  [AXI_ADDR_WIDTH-1:0]  axi_araddr_i;
  input   wire                        axi_arvalid_i;
  output  wire                        axi_arready_o;

  output  wire  [AXI_ID_WIDTH-1:0]    axi_rid_o;
  output  wire  [AXI_DATA_WIDTH-1:0]  axi_rdata_o;
  output  wire  [AXI_RESP_WIDTH-1:0]  axi_rresp_o;
  output  wire                        axi_rvalid_o;
  input   wire                        axi_rready_i;

  input   wire  [AXI_ID_WIDTH-1:0]    axi_awid_i;
  input   wire  [AXI_ADDR_WIDTH-1:0]  axi_awaddr_i;
  input   wire                        axi_awvalid_i;
  output  wire                        axi_awready_o;

  input   wire  [AXI_DATA_WIDTH-1:0]  axi_wdata_i;
  input   wire  [AXI_BYTE_NUM-1:0]    axi_wstrb_i;
  input   wire                        axi_wvalid_i;
  output  wire                        axi_wready_o;

  output  wire  [AXI_ID_WIDTH-1:0]    axi_bid_o;
  output  wire  [AXI_RESP_WIDTH-1:0]  axi_bresp_o;
  output  wire                        axi_bvalid_o;
  input   wire                        axi_bready_i;

  /* uart interrupt */
  output  reg                         read_interrupt_o;

  /* uart interface ports */
  input   wire                        uart_rx_i;
  output  wire                        uart_tx_o;

  /* integeres and genvars */
  genvar I;

  /* sync regs and wires declarations */
  wire                        axi_wren;                       //..axi-transaction write enable
  wire                        axi_nwren;                      //..axi-transaction write disable
  wire                        axi_rden;                       //..axi-transaction read enable
  wire                        axi_nrden;                      //..axi-transaction read disable
  wire                        axi_wrresp;                     //..axi-transaction write valid response
  wire                        axi_nwrresp;                    //..axi-transaction write finished response
  wire                        axi_rdresp;                     //..axi-transaction read valid response
  wire                        axi_nrdresp;                    //..axi-transaction read finished response
  reg                         axi_sync_wren, axi_sync_wren_d; //..write axi-transaction synchronizer between clock domains
  reg                         axi_sync_rden, axi_sync_rden_d; //..read axi-transaction synchronizer between clock domains

  /* internal regs and wires declarations */
  wire  [AXI_FIFO_ADDR:0]     rx_status_int;                                  //..rx status flag
  wire  [AXI_FIFO_ADDR+3:0]   tx_status_int;                                  //..tx status flag
  reg                         rx_fifo_reset_int, rx_fifo_reset_int_d;         //
  wire                        push_controller_rx_fifo;                        //
  reg                         rx_fifo_pull_int, rx_fifo_pull_int_d;           //
  wire  [DATA_WIDTH_UART-1:0] data_rx_controller_fifo;                        //..uart->fifo
  wire  [DATA_WIDTH_UART-1:0] rx_fifo_data_out_int;                           //..fifo->axi
  wire  [AXI_FIFO_ADDR:0]     rx_fifo_space_int;                              //
  reg                         tx_fifo_reset_int, tx_fifo_reset_int_d;         //
  reg                         tx_fifo_push_int, tx_fifo_push_int_d;           //
  wire                        pull_controller_tx_fifo;                        //
  wire                        load_tx_fifo_controller;                        //
  wire                        tx_fifo_full_int;                               //
  reg   [DATA_WIDTH_UART-1:0] tx_fifo_data_in_int, tx_fifo_data_in_int_d;     //..axi->fifo
  wire  [DATA_WIDTH_UART-1:0] data_tx_fifo_controller;                        //..fifo->uart
  wire  [AXI_FIFO_ADDR:0]     tx_fifo_available_int;                          //
  wire  [AXI_FIFO_ADDR:0]     tx_fifo_space_int;                              //
  wire                        available_write_space_int;                      //
  reg   [AXI_DATA_WIDTH-1:0]  uart_config_reg_int, uart_config_reg_int_d;     //
  wire  [AXI_DATA_WIDTH-1:0]  uart_lsr_reg_int;                               //
  wire                        uart_en_int;                                    //
  wire                        uart_parity_en_int;                             //
  wire                        uart_parity_mode_int;                           //
  wire                        uart_stop_bits_sel_int;                         //
  wire                        uart_dlab_int;                                  //
  reg   [AXI_DIV_WIDTH-1:0]   uart_baudrate_div_int, uart_baudrate_div_int_d; //Initial value 115200 bps

  /* Extra bit flag to enable/disable interrupts */
  reg                         uart_irq_en_int, uart_irq_en_int_d;             //..
  reg   [AXI_DIV_WIDTH-1:0]   baudrate_divisor_int, baudrate_divisor_int_d;   //Initial default value configured at 115200 bps for 50 MHz

  /* axi interface registers declarations */
  reg                         axi_awready, axi_awready_d; //..aw  channel - ready
  reg                         axi_wready, axi_wready_d;   //..w   channel - ready
  reg   [AXI_ID_WIDTH-1:0]    axi_bid, axi_bid_d;         //..b   channel - id
  reg   [AXI_RESP_WIDTH-1:0]  axi_bresp, axi_bresp_d;     //..b   channel - resp
  reg                         axi_bvalid, axi_bvalid_d;   //..b   channel - valid
  reg                         axi_arready, axi_arready_d; //..ar  channel - ready
  reg   [AXI_ID_WIDTH-1:0]    axi_rid, axi_rid_d;         //..r   channel - id
  reg   [AXI_DATA_WIDTH-1:0]  axi_rdata, axi_rdata_d;     //..r   channel - data
  reg   [AXI_RESP_WIDTH-1:0]  axi_rresp, axi_rresp_d;     //..r   channel - resp
  reg                         axi_rvalid, axi_rvalid_d;   //..r   channel - valid

  /*LCR*/
  assign  uart_en_int             = 1'b1; //TODO initialize in reset and check if functional. Otherwise remove enable functionality (enable would be always on)
  assign  uart_parity_en_int      = uart_config_reg_int[UART_CONFIG_PARITY_EN];
  assign  uart_parity_mode_int    = uart_config_reg_int[UART_CONFIG_PARITY_MODE];
  assign  uart_stop_bits_sel_int  = uart_config_reg_int[UART_CONFIG_STOP_BITS];
  assign  uart_dlab_int           = uart_config_reg_int[UART_CONFIG_DLAB];

  /* axi-transaction start-end enable assignments */
  assign axi_wren     = axi_awvalid_i & axi_wvalid_i;
  assign axi_nwren    = ~(axi_awvalid_i | axi_wvalid_i | axi_bvalid_o);
  assign axi_rden     = axi_arvalid_i;
  assign axi_nrden    = ~(axi_arvalid_i | axi_rvalid_o);

  /* axi-transaction start-end response assignments */
  assign axi_wrresp   = axi_awready & axi_wready;
  assign axi_nwrresp  = ~(axi_awready | axi_wready | axi_bvalid);
  assign axi_rdresp   = axi_arready;
  assign axi_nrdresp  = ~(axi_arready | axi_rvalid);

  /* axi-transaction synchronizer - write: comb */
  always @ (*) begin
    axi_sync_wren_d = axi_sync_wren;
    case(axi_sync_wren)
      1'b0: axi_sync_wren_d = (axi_nwren & axi_wrresp) ? 1'b1 : 1'b0;
      1'b1: axi_sync_wren_d = (axi_nwrresp) ? 1'b0 : 1'b1;
    endcase
  end

  /* axi-transaction synchronizer - write: seq */
  always @ (posedge axi_aclk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i)
      axi_sync_wren <= 1'b0;
    else
      axi_sync_wren <= axi_sync_wren_d;
  end

  /* axi-transaction synchronizer - read: comb */
  always @ (*) begin
    axi_sync_rden_d = 1'b0;
    case(axi_sync_rden)
      1'b0: axi_sync_rden_d = (axi_nrden & axi_rdresp) ? 1'b1 : 1'b0;
      1'b1: axi_sync_rden_d = (axi_nrdresp) ? 1'b0 : 1'b1;
    endcase
  end

  /* axi-transaction synchronizer - read: seq */
  always @ (posedge axi_aclk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i)
      axi_sync_rden <= 1'b0;
    else
      axi_sync_rden <= axi_sync_rden_d;
  end

  /* axi responses assignments */
  assign axi_awready_o  = (axi_wren & ~axi_sync_wren) ? axi_awready : 1'b0;
  assign axi_wready_o   = (axi_wren & ~axi_sync_wren) ? axi_wready  : 1'b0;
  assign axi_bid_o      = /*(axi_wren & ~axi_sync_wren) ?*/ axi_bid /*    : {AXI_ID_WIDTH{1'b0}}*/;
  assign axi_bresp_o    = (axi_wren & ~axi_sync_wren) ? axi_bresp   : {AXI_RESP_WIDTH{1'b0}};
  assign axi_bvalid_o   = (axi_wren & ~axi_sync_wren) ? axi_bvalid  : 1'b0;
  assign axi_arready_o  = (axi_rden & ~axi_sync_rden) ? axi_arready : 1'b0;
  assign axi_rid_o      = /*(axi_rden & ~axi_sync_rden) ?*/ axi_rid /*    : {AXI_ID_WIDTH{1'b0}}*/;
  assign axi_rdata_o    = /*(axi_rden & ~axi_sync_rden) ?*/ axi_rdata /*  : {AXI_DATA_WIDTH{1'b0}}*/;
  assign axi_rresp_o    = (axi_rden & ~axi_sync_rden) ? axi_rresp   : {AXI_RESP_WIDTH{1'b0}};
  assign axi_rvalid_o   = (axi_rden & ~axi_sync_rden) ? axi_rvalid  : 1'b0;

  /*-----------------------------------------------------------------READ FSM---------------------------------------------------------------------------*/

  /* slave read bus interface ctrl */
  localparam  ResetReadState  = 4'b0000;  // 0
  localparam  ConfigReadState = 4'b0011;  // 3
  localparam  IdleReadState   = 4'b0101;  // 5
  localparam  AckReadState    = 4'b1001;  // 9
  reg [3:0] read_state, read_state_d;

  /*
  Always description:
  The FSM purposed to serve the read requests. The user can read the incoming through the UART data as well as the already present configuration information it needs by addressing the specific internal register.
  */
  // --- read fsm: comb
  always @ (*) begin
    axi_arready_d       = axi_arready;
    axi_rdata_d         = axi_rdata;
    axi_rresp_d         = axi_rresp;
    axi_rvalid_d        = axi_rvalid;
    axi_rid_d           = axi_rid;
    rx_fifo_reset_int_d = rx_fifo_reset_int;
    rx_fifo_pull_int_d  = rx_fifo_pull_int;
    read_state_d        = read_state;
    case(read_state)
      ResetReadState: begin
        axi_arready_d       = 1'b0;
        axi_rdata_d         = {AXI_DATA_WIDTH{1'b0}};
        axi_rresp_d         = 2'b0;
        axi_rvalid_d        = 1'b0;
        axi_rid_d           = {AXI_ID_WIDTH{1'b0}};
        rx_fifo_reset_int_d = 1'b1;
        rx_fifo_pull_int_d  = 1'b0;
        read_state_d        = ConfigReadState;
      end
      ConfigReadState: begin
        axi_arready_d       = 1'b0;
        axi_rresp_d         = 2'b0;
        axi_rvalid_d        = 1'b0;
        axi_rid_d           = {AXI_ID_WIDTH{1'b0}};
        rx_fifo_reset_int_d = 1'b1;
        read_state_d        = IdleReadState;
      end
      IdleReadState: begin
        if(axi_rden) begin //..read operation
          case(axi_araddr_i[AXI_ADDR_WIDTH-1:AXI_LSB_WIDTH]) // 4 downto 2
            UART_RBR: begin //..read rx data
              if (uart_dlab_int == 0) begin //give access only of the specific bit is set to zero
                axi_arready_d       = 1'b1;
                axi_rdata_d         = {{(AXI_DATA_WIDTH-DATA_WIDTH_UART){1'b0}},rx_fifo_data_out_int};
                axi_rvalid_d        = 1'b1;
                axi_rresp_d         = 2'b0;
                rx_fifo_pull_int_d  = 1'b1;
                read_state_d        = AckReadState;
              end else begin
                axi_arready_d       = 1'b1;
                axi_rresp_d         = 2'b0;
                axi_rvalid_d        = 1'b1;
                read_state_d        = AckReadState;
              end
            end
            UART_LSR: begin
              axi_arready_d   = 1'b1;
              axi_rdata_d     = uart_lsr_reg_int;
              axi_rresp_d     = 2'b0;
              axi_rvalid_d    = 1'b1;
              read_state_d    = AckReadState;
            end
            default: begin
              axi_arready_d   = 1'b0;
              axi_rresp_d     = 2'b0;
              axi_rvalid_d    = 1'b0;
              read_state_d    = AckReadState;
            end
          endcase
          axi_rid_d       = axi_arid_i;
        end else begin
          axi_arready_d   = 1'b0;
          axi_rresp_d     = 2'b0;
          axi_rvalid_d    = 1'b0;
          //axi_rid_d       = {AXI_ID_WIDTH{1'b0}};
          read_state_d    = IdleReadState;
        end
      end
      AckReadState: begin
        axi_arready_d       = 1'b0;
        axi_rresp_d         = 2'b0;
        axi_rvalid_d        = 1'b0;
        axi_rid_d           = {AXI_ID_WIDTH{1'b0}};
        rx_fifo_pull_int_d  = 1'b0;
        rx_fifo_reset_int_d = 1'b0;
        read_state_d        = IdleReadState;
      end
      default: begin
        axi_arready_d       = 1'b0;
        axi_rdata_d         = {AXI_DATA_WIDTH{1'b0}};
        axi_rresp_d         = 2'b0;
        axi_rvalid_d        = 1'b0;
        axi_rid_d           = {AXI_ID_WIDTH{1'b0}};
        rx_fifo_reset_int_d = 1'b1;
        rx_fifo_pull_int_d  = 1'b0;
        read_state_d        = ResetReadState;
      end
    endcase
  end

  // --- read fsm: seq
  always @ (posedge fixed_clk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i) begin
      axi_arready       <= 1'b0;
      axi_rdata         <= {AXI_DATA_WIDTH{1'b0}};
      axi_rresp         <= 2'b0;
      axi_rvalid        <= 1'b0;
      axi_rid           <= {AXI_ID_WIDTH{1'b0}};
      rx_fifo_reset_int <= 1'b1;
      rx_fifo_pull_int  <= 1'b0;
      read_state        <= ResetReadState;
    end
    else begin
      axi_arready       <= axi_arready_d;
      axi_rdata         <= axi_rdata_d;
      axi_rresp         <= axi_rresp_d;
      axi_rvalid        <= axi_rvalid_d;
      axi_rid           <= axi_rid_d;
      rx_fifo_reset_int <= rx_fifo_reset_int_d;
      rx_fifo_pull_int  <= rx_fifo_pull_int_d;
      read_state        <= read_state_d;
    end
  end

  /*-----------------------------------------------------------------WRITE FSM---------------------------------------------------------------------------*/

  /* slave write bus interface ctrl */
  localparam  ResetWriteState = 3'b000; // 0 //
  localparam  IdleWriteState  = 3'b011; // 3 //
  localparam  AckWriteState   = 3'b101; // 5 //
  reg [2:0] write_state, write_state_d;

  /*
  Always description:
  The FSM purposed to serve the write requests. By addressing the correct internal registers the user can define a new configuration (parity mode, # of start/stop bits e.tc)
  as well as to write data to be transmitted serially through the UART
  */
  // --- write fsm: comb
  always @ (*) begin
    axi_awready_d           = axi_awready;
    axi_wready_d            = axi_wready;
    axi_bvalid_d            = axi_bvalid;
    axi_bresp_d             = axi_bresp;
    axi_bid_d               = axi_bid;
    tx_fifo_reset_int_d     = tx_fifo_reset_int;
    tx_fifo_push_int_d      = tx_fifo_push_int;
    tx_fifo_data_in_int_d   = tx_fifo_data_in_int;
    uart_baudrate_div_int_d = uart_baudrate_div_int;
    baudrate_divisor_int_d  = baudrate_divisor_int;
    uart_config_reg_int_d   = uart_config_reg_int;
    uart_irq_en_int_d       = uart_irq_en_int;
    write_state_d           = write_state;
    case(write_state)
      ResetWriteState: begin
        axi_awready_d           = 1'b0;
        axi_wready_d            = 1'b0;
        axi_bvalid_d            = 1'b0;
        axi_bresp_d             = 2'b0;
        axi_bid_d               = {AXI_ID_WIDTH{1'b0}};
        tx_fifo_reset_int_d     = 1'b1;
        tx_fifo_push_int_d      = 1'b0;
        tx_fifo_data_in_int_d   = {DATA_WIDTH_UART{1'b0}};
        uart_baudrate_div_int_d = UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
        baudrate_divisor_int_d  = UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
        uart_config_reg_int_d   = {AXI_DATA_WIDTH{1'b0}};
        uart_irq_en_int_d       = 1'b0;
        write_state_d           = IdleWriteState;
      end
      IdleWriteState: begin
        if(axi_wren) begin  //..write operation
          case(axi_awaddr_i[AXI_ADDR_WIDTH-1:AXI_LSB_WIDTH])
            UART_THR: begin
              if (uart_dlab_int == 0) begin
                if(~tx_fifo_full_int) begin
                  axi_awready_d         = 1'b1;//0;
                  axi_wready_d          = 1'b1;//0;
                  axi_bvalid_d          = 1'b1;
                  axi_bresp_d           = 2'b0;
                  tx_fifo_push_int_d    = 1'b1;
                  tx_fifo_data_in_int_d = axi_wdata_i[DATA_WIDTH_UART-1:0];
                  write_state_d         = AckWriteState;
                end
              end else begin
                axi_awready_d         = 1'b1;
                axi_wready_d          = 1'b1;
                axi_bvalid_d          = 1'b1;
                axi_bresp_d           = 2'b0;
                write_state_d         = AckWriteState;
              end
            end
            UART_IER: begin
              if (uart_dlab_int == 0) begin //give access only of the specific bit is set to zero
                axi_awready_d     = 1'b1;
                axi_wready_d      = 1'b1;
                axi_bvalid_d      = 1'b1;
                axi_bresp_d       = 2'b0;
                uart_irq_en_int_d = axi_wdata_i[0];
                write_state_d     = AckWriteState;
              end else begin
                axi_awready_d     = 1'b1;
                axi_wready_d      = 1'b1;
                axi_bvalid_d      = 1'b1;
                axi_bresp_d       = 2'b0;
                write_state_d     = AckWriteState;
              end
            end
            UART_BAUD_DIVISOR: begin
              if (uart_dlab_int == 1) begin //give access only of the specific bit is set to one
                axi_awready_d           = 1'b1;
                axi_wready_d            = 1'b1;
                axi_bvalid_d            = 1'b1;
                axi_bresp_d             = 2'b0;
                baudrate_divisor_int_d  = axi_wdata_i;
                write_state_d           = AckWriteState;
              end else begin
                axi_awready_d           = 1'b1;
                axi_wready_d            = 1'b1;
                axi_bvalid_d            = 1'b1;
                axi_bresp_d             = 2'b0;
                write_state_d           = AckWriteState;
              end
            end
            UART_LCR: begin
              axi_awready_d         = 1'b1;
              axi_wready_d          = 1'b1;
              axi_bvalid_d          = 1'b1;
              axi_bresp_d           = 2'b0;
              uart_config_reg_int_d = axi_wdata_i;
              write_state_d         = AckWriteState;
            end
            default: begin    // The case where the address is not present but we doo not want the AXI bus to hang
              axi_awready_d   = 1'b1;
              axi_wready_d    = 1'b1;
              axi_bvalid_d    = 1'b1;
              axi_bresp_d     = 2'b0;
              write_state_d   = AckWriteState;
            end
          endcase
          axi_bid_d     = axi_awid_i;
        end else begin
          axi_awready_d   = 1'b0;
          axi_wready_d    = 1'b0;
          axi_bvalid_d    = 1'b0;
          axi_bresp_d     = 2'b0;
          //axi_bid_d       = {AXI_ID_WIDTH{1'b0}};
          write_state_d   = IdleWriteState;
        end
      end
      AckWriteState: begin
        axi_awready_d           = 1'b0;
        axi_wready_d            = 1'b0;
        axi_bvalid_d            = 1'b0;
        axi_bresp_d             = 2'b0;
        axi_bid_d               = {AXI_ID_WIDTH{1'b0}};
        tx_fifo_push_int_d      = 1'b0;
        tx_fifo_reset_int_d     = 1'b0;
        uart_baudrate_div_int_d = baudrate_divisor_int;
        write_state_d           = IdleWriteState;
      end
      default: begin
        axi_awready_d           = 1'b0;
        axi_wready_d            = 1'b0;
        axi_bvalid_d            = 1'b0;
        axi_bresp_d             = 2'b0;
        axi_bid_d               = {AXI_ID_WIDTH{1'b0}};
        tx_fifo_reset_int_d     = 1'b1;
        tx_fifo_push_int_d      = 1'b0;
        tx_fifo_data_in_int_d   = {DATA_WIDTH_UART{1'b0}};
        uart_baudrate_div_int_d = UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
        baudrate_divisor_int_d  = UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
        uart_config_reg_int_d   = {AXI_DATA_WIDTH{1'b0}};
        uart_irq_en_int_d       = 1'b0;
        write_state_d           = ResetWriteState;
      end
    endcase
  end

  // --- write fsm: seq
  always @ (posedge fixed_clk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i) begin
      axi_awready           <= 1'b0;
      axi_wready            <= 1'b0;
      axi_bvalid            <= 1'b0;
      axi_bresp             <= 2'b0;
      axi_bid               <= {AXI_ID_WIDTH{1'b0}};
      tx_fifo_reset_int     <= 1'b1;
      tx_fifo_push_int      <= 1'b0;
      tx_fifo_data_in_int   <= {DATA_WIDTH_UART{1'b0}};
      uart_baudrate_div_int <= UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
      baudrate_divisor_int  <= UART_BAUDRATE_DIV_INIT[AXI_DIV_WIDTH-1:0];
      uart_config_reg_int   <= {AXI_DATA_WIDTH{1'b0}};
      uart_irq_en_int       <= 1'b0;
      write_state           <= ResetWriteState;
    end
    else begin
      axi_awready           <= axi_awready_d;
      axi_wready            <= axi_wready_d;
      axi_bvalid            <= axi_bvalid_d;
      axi_bresp             <= axi_bresp_d;
      axi_bid               <= axi_bid_d;
      tx_fifo_reset_int     <= tx_fifo_reset_int_d;
      tx_fifo_push_int      <= tx_fifo_push_int_d;
      tx_fifo_data_in_int   <= tx_fifo_data_in_int_d;
      uart_baudrate_div_int <= uart_baudrate_div_int_d;
      baudrate_divisor_int  <= baudrate_divisor_int_d;
      uart_config_reg_int   <= uart_config_reg_int_d;
      uart_irq_en_int       <= uart_irq_en_int_d;
      write_state           <= write_state_d;
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
        .clk_i                  (fixed_clk_i),
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
        //.tx_full_i              (tx_fifo_full_int),
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
        .clk_i    (fixed_clk_i),             // clock signal
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
  always @ (posedge fixed_clk_i, negedge axi_aresetn_i) begin
    if(~axi_aresetn_i) begin
      read_interrupt_o                        <= 1'b0;
      //uart_lsr_reg_int                        <= 32'h00000060; //..initial value for LSR
    end
	 else begin
      read_interrupt_o                        <= ~rx_fifo_space_int[AXI_FIFO_ADDR] & uart_irq_en_int ;
//      uart_lsr_reg_int                        = 32'h00000000;
      //uart_lsr_reg_int[UART_LSR_TEMT]         <= available_write_space_int;
      //uart_lsr_reg_int[UART_LSR_DATA_READY]   <= ~rx_fifo_space_int[AXI_FIFO_ADDR] & uart_irq_en_int ;
    end
  end

  generate
    for(I = 0; I < AXI_DATA_WIDTH; I = I + 1) begin: uart_lsr_assignment_gen
      case(I)
        UART_LSR_THRE:        assign uart_lsr_reg_int[I] = available_write_space_int;
        UART_LSR_TEMT:        assign uart_lsr_reg_int[I] = available_write_space_int;
        UART_LSR_DATA_READY:  assign uart_lsr_reg_int[I] = ~rx_fifo_space_int[AXI_FIFO_ADDR] & uart_irq_en_int ;
        default:              assign uart_lsr_reg_int[I] = 1'b0;
      endcase
    end
  endgenerate

  /* tx fifo */
  axi_internal_fifo
    # (
        .FIFO_SIZE    (AXI_FIFO_DEPTH),
        .DATA_SIZE    (DATA_WIDTH_UART),
        .INDEX_LENGTH (AXI_FIFO_ADDR),
        .PORT_EN      (3'b111)  //..flag port enable [3-bits]: load | full | available_space
      )
    axi_internal_fifo_tx_inst    (
        .clk_i                    (fixed_clk_i),               // clock signal
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
