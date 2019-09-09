 /* -----------------------------------------------
 * Project Name   : DRAC
 * File           : uart_transmitter.v
 * Organization   : Barcelona Supercomputing Center, CIC-IPN
 * Author(s)      : Abraham J. Ruiz R., Vatistas Kostalabros
 * Email(s)       : abraham.ruiz@bsc.es, vatistas.kostalabros@bsc.es
 * References     : 
 * -----------------------------------------------
 * Revision History
 *  Revision   | Author      | Commit | Description
 *  ******     | vkostalamp  | 236c2  | Contribution
 * -----------------------------------------------*/


`default_nettype none

/*
Title: uart_transmitter
Module responsible to transmitting the data from the AXI BUS to the UART interface. This module instantiates also a parity bit computation module in order to form the whole UART data packet.
Lastly it also inserts the start and stop bits to the correct position in the data packet.
*/
module uart_transmitter
#    (
        parameter     DIV_SIZE            =  16,            // size of the baudrate divisor
        parameter     DATA_UART           =  8              // size of he data UART packet
    )
(
    input        wire              clk_i,                      // clock signal 
    input        wire              rstn_i,                     // reset signal 
    input        wire              en_i,                       // enable signal 
    input        wire              stop_bits_i,                // number of required stop bits  
    input        wire              parity_bit_i,               // signal enabling/disabling parity bit 
    input        wire              parity_bit_mode_i,          // the mode of parity <0=odd>/<1=even> 
    input   wire [DIV_SIZE-1:0]    baud_div_i,                 // Baud rate value  
    output  reg                    tx_o,                       // tha transmitted bit 
    input   wire [DATA_UART-1:0]   tx_data_i,                  // the parallel incoming bits to be sent serially 
    input        wire              tx_send_i,                  // signals the sending of a bit 
    output  reg                    tx_ready_o,                 // transmitter is ready to receive the next bits to send from the controller 
    output  reg                    busy_o                      // indicates that the 
);

    /* regs and wires */
    reg     [DATA_UART-1:0]        tx_data_int;                // register holding the bits to be transmitted 
    reg     [3:0]                  bitcount_int;               // counter holding the number of data bits transmitted in each packet 
    reg     [1:0]                  tx_stop_bits_int;           // counter holding the number of stop bits allready transmitted in each packet 
    wire                           parity_bit_int;             // the parity bit to be transmitted 
    reg     [DIV_SIZE-1:0]                  counter_int;                // counter holding clock cycles to signal the sending of a bit according to the baudrate value 
    reg                            tx_sample_reset_int;        // signal sent to the parity computation module to signal the arrival of new data 
    reg                            tx_sample_data_int;         // the bit sent to the parity computatio module 
    reg                            tx_sample_valid_int;        // signal indicating the validity of the bit sent to the parity bit computation module 

    /* fsm parameters */
    localparam    ResetState        =    5'b00000; //reset state
    localparam    IdleState        =    5'b00011;  //waiting for incoming tx data
    localparam    DataState        =    5'b00101; // receive data bits
    localparam    ParityState    =    5'b01001; // receive parity bit
    localparam    StopState        =    5'b10001;  // receive stop bits
        reg     [4:0]                  state;                      

/*
Always description: 
 Transmitter fsm controlling the sending of the parallel bits to a serial manner
 It is also responsible to insert the necessary start, stop and parity bits to the stream
*/
    always @ (posedge clk_i, negedge rstn_i)    begin
        case(state)
            ResetState:        begin
                tx_o                    <=    1'b1;
                tx_data_int                <=    {(DATA_UART){1'b0}}; 
                counter_int                <=    0;
                bitcount_int                <=    4'b0;
                tx_sample_reset_int    <=    1'b0;
                tx_sample_data_int        <=    1'b0;
                tx_sample_valid_int    <=    1'b0;
                tx_stop_bits_int        <=    2'b0;
                tx_ready_o            <=    1'b0;
                if(rstn_i)    begin
                    busy_o        <=    1'b0;
                    state        <=    IdleState;
                end else begin
                    busy_o            <=    1'b1;
                end
            end
            IdleState:        begin
                if(~rstn_i) begin
                    state    <=    ResetState;
                end else    begin
                    counter_int                <=    0;
                    bitcount_int                <=    4'b0;
                    tx_sample_valid_int    <=    1'b0;
                    tx_stop_bits_int        <=    2'b0;
                    tx_ready_o            <=    1'b0;
                    if(tx_send_i & en_i)    begin
                        tx_o                    <=    1'b0;
                        tx_data_int                <=    tx_data_i;
                        tx_sample_reset_int    <=    1'b1;
                        busy_o                    <=    1'b1;
                        state                    <=    DataState;
                    end
                end
            end
            DataState:        begin
                if(~rstn_i) begin
                    state    <=    ResetState;
                end else    begin
                    if(counter_int>=baud_div_i)    begin
                        if(bitcount_int==DATA_UART-1)    begin
                            case(parity_bit_i)
                                0:    state    <=    StopState;
                                1:    state    <=    ParityState;
                            endcase
                        end
                        tx_o                            <=    tx_data_int[0];
                        tx_data_int[DATA_UART-2:0]    <=    tx_data_int[DATA_UART-1:1];
                        tx_sample_data_int                <=    tx_data_int[0];
                        tx_sample_valid_int            <=    1'b1;
                        bitcount_int                        <=    bitcount_int + 4'b1;
                        counter_int                        <=    0;
                    end else    begin
                        tx_sample_valid_int    <=    1'b0;
                        counter_int                <=    counter_int + 1;
                     end
                 end
            end
            ParityState:    begin
                if(~rstn_i) begin
                    state    <=    ResetState;
                end else begin
                    if(counter_int>=baud_div_i)    begin
                        tx_o        <=    parity_bit_int;
                        counter_int    <=    0;
                        state        <=    StopState;
                    end else begin
                        counter_int    <=    counter_int + 1;
                    end
                end
                tx_sample_valid_int    <=    1'b0;
                end
            StopState:        begin
                if(~rstn_i) begin
                    state    <=    ResetState;
                end else begin
                    if(counter_int>=baud_div_i)    begin
                        case(stop_bits_i)
                            0:    begin
                                if(tx_stop_bits_int==1)    begin
                                    tx_ready_o    <=    1'b1;
                                    busy_o            <=    1'b0;
                                    state            <=    IdleState;
                                end
                            end
                            1:    begin
                                if(tx_stop_bits_int==2)    begin
                                    tx_ready_o    <=    1'b1;
                                    busy_o            <=    1'b0;
                                    state            <=    IdleState;
                                end
                            end
                        endcase
                        tx_o                <=    1'b1;
                        tx_stop_bits_int    <=    tx_stop_bits_int + 2'b1;
                        counter_int            <=    0;
                    end else begin
                        counter_int    <=    counter_int + 1;
                    end
                end
                tx_sample_valid_int    <=    1'b0;
                tx_sample_reset_int    <=    1'b0;
            end
            
            default: state <= ResetState;
        endcase
    end

    /* calculate parity bit */
    uart_parity_bit_compute
        uart_parity_bit_compute_tx_inst    (
            .clk_i                (clk_i),                    // clock
            .rstn_i                (tx_sample_reset_int),    // reset (active low)
            .data_i            (tx_sample_data_int),        // data
            .valid_i            (tx_sample_valid_int),    // valid data
            .mode_i            (parity_bit_mode_i),    // <0=even>/<1=odd>
            .parity_bit_o    (parity_bit_int)            // parity bit
        );


endmodule

`default_nettype wire
