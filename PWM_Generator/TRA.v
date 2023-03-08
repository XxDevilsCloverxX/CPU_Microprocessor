`timescale 1ns / 1ps

//This TOP module currently controls two motors using the BASYS3 FPGA
module TOP(
    input clk,
    input res,
    input [7:0] sw,
    output [7:0] led,
    output [1:0] dirA,
    output [1:0] dirB,
    output PWMA,
    output PWMB
);
    //create additional wires to "Bench" module outputs
    assign led = sw;    //allows user to see leds on BASYS3 from switch use
    //declare module instances
    Motor_Controller_50Hz MOTORA(.clk(clk), .res(res), .sw(sw[3:0]), .PWM(PWMA), .dir(dirA)); //directions flipped
    Motor_Controller_50Hz MOTORB(.clk(clk), .res(res), .sw(sw[7:4]), .PWM(PWMB), .dir(dirB)); //for convinience in sim
    
endmodule

//Take a 1MHz -> 50Hz and generate a duty cycle based on bus
module Motor_Controller_50Hz (
    input clk,
    input res,
    input [3:0] sw,
    output reg PWM,
    output [1:0] dir
);
    
    assign dir[0] = sw[3];
    assign dir[1] = ~dir[0];
    
    //initialize registers
    reg [20:0] COUNTER, CMP;
    
    //create the 50 Hz signal, period = 20 from 1kHz clock
    always @(posedge clk) begin
        if (res)
            COUNTER <= 0;
        else if (COUNTER > 2000000)
            COUNTER <= 0;
        else
            COUNTER <= COUNTER + 1;
    end
    //monitor counter, adjust duty cycle
    always @(posedge clk) begin
        if (res) begin
            CMP <= 0;
            PWM <= 0;
        end
        else begin
            //update the width of the pulse based on lower 3 bits
            case (sw[2:0])
                3'B001: CMP<=500000;
                3'B010: CMP<=1000000;
                3'B100: CMP<=1500000;
                3'B111: CMP<=2000000;
                default:CMP<= 0;
            endcase
            //update PWM
            if (COUNTER < CMP)
                PWM <=1;
            else
                PWM <=0;
        end
   end
        
endmodule