/*
    Name: Silas Rodriguez
    R-Number: R-11679913
    Assignment: Project 3 
*/

module alu (
    input clk,
    input [31:0] a,
    input [31:0] b,
    input [4:0] op,

    output reg [31:0] out,
    output reg zflag,      //zero flag
    output reg nflag,      //negative flag
    output reg cflag,       //carry flag
    output reg vflag,       //two's compliment overflow flag
    output wire sflag,       //sign flag
    output reg hflag       //half carry flag
);
    //I want this flag to update when the status register changes
    assign sflag = nflag ^ vflag;
    
    always @(negedge clk) begin
        case (op)
            //LD -> flags should remain what they were before
            5'h01: begin
                out = a;
            end
            //add
            5'h03: begin
                out = a + b;
                cflag = (out < a);
                vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);   //overflow for signed math. signs of operands don't match output sets v
                hflag = ((a[15:0] + b[15:0]) < a[15:0]);    //add the lower words, then comare if lower than either word
                zflag = (out == 0);
                nflag = (out[31]);
            end
            //sub
            5'h04: begin
                out = a - b;
                cflag = (out > a);
                hflag = ((a[15:0] + b[15:0]) > a[15:0]);    //add the lower words, then comare if lower than either word
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);   //overflow for signed math. signs of operands don't match output sets v
            end
            //and
            5'h05: begin 
                out = a & b;
                cflag = 0;
                hflag = 0;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = 0;   //based on msp430 manual
            end
            //or
            5'h06: begin
                out = a | b;
                cflag = 0;
                hflag = 0;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = 0;   //based on msp430 manual
            end
            //xor
            5'h07: begin
                out = a ^ b;
                cflag = 0;
                hflag = 0;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);;   //based on msp430 manual
            end
            //not
            5'h08: begin 
                out = ~a;
                cflag = 0;
                hflag = 0;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = 0;   //based on msp430 manual
            end
            //SL
            5'h09: begin
                out = a << (b-1);
                cflag = out[31];
                hflag = out[15];    //get the bit below the upper word
                out = out << 1;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);;   //based on msp430 manual
            end
            //SR
            5'h0A: begin
                out = a >> (b-1);
                cflag = out[0];
                hflag = out[16];    //get the bit above the lower word
                out = out >> 1;
                zflag = (out == 0);
                nflag = (out[31]);
                vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);;   //based on msp430 manual
            end

        endcase
    end

endmodule