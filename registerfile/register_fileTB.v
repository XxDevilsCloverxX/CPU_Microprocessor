/*
Name: Silas Rodriguez
R#: R-11679913
Assignment: Project 2
*/
`timescale 1ns/1ps

//Module that simulates the register file
module regfileTB;
    //define drivers & itterators
    reg clk, rw;
    reg [4:0] d_addr, a_addr, b_addr;
    reg [31:0] data;
    //instantiate outputs
    wire [31:0] a_data, b_data;
    //set a simulator variable
    integer i;
    
    //clk driver
    initial begin
        clk = 0;
        forever begin
            #10 clk = ~clk;
        end
    end

    //simulation
    initial begin
        //set all the registers
        rw = 1;
        a_addr = 0;
        b_addr = 0;
        for (i=0; i<32; i= i+1) begin
            d_addr = i;
            data = i;
            #20;    //wait one clk cycle for changes to occur
        end

        //read from all the registers
        rw = 0;
        d_addr = 0;
        data = 0;
        for (i=0; i<32; i=i+1) begin
            a_addr = i;     //a and b read in reverse to show 
            b_addr = 31-i;  //they are not codependent
            #20;    //wait one clk cycle for changes to occur
        end

    end

    //module instance
    register_file GPR_Access(.clk(clk), .rw(rw), .d_addr(d_addr), .a_addr(a_addr),
    .b_addr(b_addr), .data(data), .a_data(a_data), .b_data(b_data));

endmodule