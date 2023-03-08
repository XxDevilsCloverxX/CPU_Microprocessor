/*
Name: Silas Rodriguez
R#: R-11679913
Assignment: Project 2
*/

//GPR access RW
module register_file(
    input clk,
    input rw,
    input [4:0] d_addr,
    input [4:0] a_addr,
    input [4:0] b_addr,
    input [31:0] data,
    output [31:0] a_data,
    output [31:0] b_data
);
    //create an array of 32 bit registers size 32
    reg [31:0] registers [31:0];

    //update the outputs to match the registers selected by A & B data
    assign a_data = registers[a_addr];
    assign b_data = registers[b_addr];

    //update every clk cycle
    always @(posedge clk) begin
        //only allow register writes on write en
        if (rw)
            //access the specific register specified by d and write to it
            registers[d_addr] <= data;
    end

endmodule