module alu (
    input clk,
    input [31:0] a,
    input [31:0] b,
    input [7:0] op,

    output reg [31:0] out,
    output wire zflag,      //zero flag
    output wire nflag,      //negative flag
    output reg cflag,       //carry flag
    output wire vflag,       //two's compliment overflow flag
    output wire sflag,       //sign flag
    output reg hflag       //half carry flag
);
    //I want these wires to update when the output changes 'instantaneously'
    assign zflag = (out == 0);
    assign nflag = out[31];
    assign vflag = (out[31] && a[31]==0 && b[31]==0)||(~out[31] && a[31] && b[31]);   //overflow for signed math. signs of operands don't match output sets v
    assign sflag = nflag ^ vflag;
    
    always @(negedge clk) begin
        case (op)
            //LD -> flags should remain what they were before
            8'h01: begin
                out = a;
                cflag = 0;
                hflag = 0;
            end
            //add
            8'h03: begin
                out = a + b;
                cflag = (out < a);
                hflag = ((a[15:0] + b[15:0]) < a[15:0]);    //add the lower words, then comare if lower than either word
            end
            //sub
            8'h04: begin
                out = a - b;
                cflag = (out > a);
                hflag = ((a[15:0] + b[15:0]) > a[15:0]);    //add the lower words, then comare if lower than either word
            end
            //and
            8'h05: begin 
                out = a & b;
                cflag = 0;
                hflag = 0;
            end
            //or
            8'h06: begin
                out = a | b;
                cflag = 0;
                hflag = 0;
            end
            //xor
            8'h07: begin
                out = a ^ b;
                cflag = 0;
                hflag = 0;
            end
            //not
            8'h08: begin 
                out = ~a;
                cflag = 0;
                hflag = 0;
            end
            //SL
            8'h09: begin
                out = a << (b-1);
                cflag = out[31];
                hflag = out[15];    //get the bit below the upper word
                out = out << 1;
            end
            //SR
            8'h0A: begin
                out = a >> (b-1);
                cflag = out[0];
                hflag = out[16];    //get the bit above the lower word
                out = out >> 1;
            end

        endcase
    end

endmodule