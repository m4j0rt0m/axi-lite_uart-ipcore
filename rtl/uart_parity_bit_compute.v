 /* -----------------------------------------------
 * Project Name   : DRAC
 * File           : uart_parity_bit_compute.v
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
Title: uart_parity_bit_compute
Desciption of the module: you can use in every part of this desciption a @tag
to reference another part of the codedoes not matter if it is in other file.
*/
module uart_parity_bit_compute    (
    input        wire              clk_i,                      // clock signal 
    input        wire              rstn_i,                     // reset signal (active high) 
    input        wire              data_i,                     // incoming bit 
    input        wire              valid_i,                    // valid data signal 
    input        wire              mode_i,                     // parity mode selection <0=odd>/<1=even> 
    output       wire              parity_bit_o                // parity bit output 
);
    reg                            counter_int;                // signal that gets the value "1" in even appearances of bit "1" and the value "0" in odd appearances of bit "1" 

    // At a positive edge of the clock signal

/*
Always description: 
The following code block is responsible to alternate the value of the counter at every valid data that the module is fed with. This way it alternates netween the even and odd parity bit value.
*/
    always @ (posedge clk_i, negedge rstn_i) begin
        if(~rstn_i) begin
            counter_int    <=    1'b0;                // reset the counter signal
        end else if(valid_i & data_i) begin           // if we have a valid incoming bit that is "1"
            counter_int    <=    ~counter_int;   // change the counter_int signal accordingly
        end
    end


/*
Assign description: 
if mode_i is 0 then ~counter_int is selected (odd parity) otherwise counter_int is selected (even parity)  
*/
    assign    parity_bit_o = (~mode_i) ? ~counter_int : counter_int;     
endmodule

`default_nettype wire
