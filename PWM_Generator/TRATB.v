`timescale 1ns / 1ps

module TRATB;

//create driver registers
reg clk, res;
reg [7:0] sw;
//create monitor wires
wire [7:0] led;
wire [1:0] dirA, dirB;
wire PWMA, PWMB;
reg [7:0] i;    //8 bit sim reg

//simulate a 100MHz clk 10 ns = period, toggle twice in this -> #5
initial begin
    clk = 0;
    forever begin
    #5 clk = ~clk;
    end
end

//simulate input signals
initial begin
    res = 1;    //reset teh hardware
    sw = 0; //switches off
    i = 0;  //loop var = 0
    #500000000;    //wait .5s cycle at least for register restting
    res =0; //hardware reset over
    
    //run the first 3 switch combinations
    for (i=0; i<2; i=i+1) begin
        sw[7:4] = i; //update the value of the switches for motor B
        sw[3:0] = i; //update the value of the switches for motor A
        #100000000 res =1;  //wait 1s at this speed
        #10 res = 0;    //reset off 
    end
    sw = 0;
    res = 1;
end

//module instance
TOP UUT(.clk(clk), .res(res), .sw(sw), .led(led), .dirA(dirA), .dirB(dirB), .PWMA(PWMA), .PWMB(PWMB));

endmodule
