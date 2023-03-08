/*
Silas Rodriguez
R11679913
*/

module PWM8bit (
    input clk,
    input res,
    input [7:0] width,
    input [7:0] cmp,
    output reg PWM
);
    //initialize registers
    reg [7:0] COUNTER, PERIOD, COMPARE;

    always @(posedge clk) begin
        //reset registers on input line
        if (res) begin
            PERIOD  <= 0;
            COMPARE <= 0;
            PWM     <= 0;
            COUNTER <= 0;
        end
        else if (COUNTER > PERIOD)
            COUNTER <= 0;
        else begin
            //Update registers from busses
            COMPARE <= cmp;
            PERIOD  <= width;
            COUNTER <= COUNTER + 1;
            
            // if counter is less than the compare value, PWM -> 1
            if (COUNTER <= COMPARE && COMPARE > 0)
                PWM <= 1;
            else
                PWM <= 0;
        end
    end
endmodule