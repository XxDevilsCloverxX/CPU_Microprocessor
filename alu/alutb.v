`timescale 1ns / 1ps

/*
    Name: Silas Rodriguez
    R-Number: R-11679913
    Assignment: Project 3 
*/

module alutb;

reg [31:0] a, b;
reg [4:0] op;
reg clk;

wire [31:0] out;
wire zflag, nflag, cflag, vflag, sflag, hflag;

//Create the clk driver
initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

//Create the input driver
initial begin
    
    //LD Op, should set z = 0;
    a = 0;
    b = 0;
    op = 5'h01;
    #10;
    //add -> try to set carry and keep z = 0
    a = 32'hffffffff;
    b = 1;
    op = 5'H03;
    #10;
    //add but, but try to induce the s flag
    a = 32'h7fffffff;
    #10;
    //sub -> try to set v flag
    a = -8;
    b = -32'hffffffff;
    op = 5'H04;
    #10;
    //and
    a = 32'hf0;
    b = 32'h0f;
    op = 5'H05;
    #10;
    //or
    op = 5'H06;
    #10;
    //xor
    op = 5'H07;
    #10;
    //not
    op = 5'H08;
    #10;
    //change b for shifts, C=1 for SL and 0 for SR
    b = 2;
    //SL    -> Try to show H flag
    a = 32'hffff;
    b = 3;
    op = 5'H09;
    #10;
    //SR
    op = 5'H0A;
    #10;
    a = 0;
    b = 0;
    op= 5'H01;  //LD 0 for z flag
    #10;
end

//alu instance
alu alu1 (
    .clk(clk),
    .a(a),
    .b(b),
    .op(op),
    .out(out),
    .zflag(zflag),
    .nflag(nflag),
    .cflag(cflag),
    .vflag(vflag),
    .hflag(hflag),
    .sflag(sflag)
);
endmodule