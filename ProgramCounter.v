module TOP (S,A,B);

    input reg [7:0] A;
    input reg [7:0] B;
    output reg [7:0] S;

    wire w0, w1, w2, w3, w4, w5, w6;

    ADDER ADDER0(w0, S[0], A[0], B[0], 1'b0);
    ADDER ADDER1(w1, S[1], A[1], B[1], w0);
    ADDER ADDER2(w2, S[2], A[2], B[2], w1);
    ADDER ADDER3(w3, S[3], A[3], B[3], w2);
    ADDER ADDER4(w4, S[4], A[4], B[4], w3);
    ADDER ADDER5(w5, S[5], A[5], B[5], w4);
    ADDER ADDER6(w6, S[6], A[6], B[6], w5);
    ADDER ADDER7(,   S[7], A[7], B[7], w6);   //leave last output out

endmodule

module ADDER (S,A,B);
    input [7:0] A;
    input [7:0] B;
    output reg [7:0] S;

    always@(*) begin    //anytime an input changes
        S = A+B;
    end

endmodule

module testbench;
    reg [7:0] A;
    reg [7:0] B;
    wire reg [7:0] S;
    
    Adder UUT (S,A,B);

    initial begin
        for (integer i=0; i<65536; i++) begin
            $monitor("%d %d = %d", );
        end
    end
endmodule