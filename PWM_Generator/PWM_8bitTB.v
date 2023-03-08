/*
Silas Rodriguez
R11679913
*/


/* Time delay math:
counter <- counter +1 every 1000 ns. I want to show each 255 clock cycle pulse with resets in between of 1 cycle each
255 * 1000 = 255000 ns time delay before doing CMP changes
RESETS -> 1000ns delay each

The program has 255000 * 2 * 6 delays + 7000ns to complete: run simulation for 3,067,000 ns or 3.067 ms 

****apx 4 ms will be good for simulation time****
*/

`timescale 1ns/1ps  //used for simulation delays

module PWM8bitTB;

//redefine inputs and outputs
reg clk, res;
reg [7:0] width, cmp;
wire PWM;

//simulation block for clk
initial begin
   clk = 0; 
   //for a FREQ = 1 MHz: period = 1 / 1,000,000 for time delay/cycle = 1 us = 1000 ns. Delay cut to 500 ns because 1 cycle is 2 toggles.
   forever begin
    #500 clk = ~clk;
   end
end

//simulation block for period and compare registers
initial begin
    cmp = 8'H1F;    //initial compare to be set
    repeat (3) begin
        //init registers
        res = 1;
        width = 0;
        #1000;  //wait a cycle
        res = 0;
        width = 8'H7F;
        #(255000<<1);    //wait 255 cycles, 2 times
        cmp = (cmp<<1) + 1; //modify compare
    end
    
    //do the simulation again with another width
    cmp = 8'H1F;    //initial compare to be set
    repeat (3) begin
        //init registers
        res = 1;
        width = 0;
        #1000;  //wait a cycle
        res = 0;
        width = 8'HFF;
        #(255000<<1);    //wait 255 cycles 2 times
        cmp = (cmp<<1) + 1; //modify compare
    end
    //Clear outputs
    res = 1;
    width = 0;
    cmp = 0;
    #1000;
    
end

//create a testbench instance
PWM8bit UUT(.clk(clk), .res(res), .PWM(PWM), .width(width), .cmp(cmp));

endmodule