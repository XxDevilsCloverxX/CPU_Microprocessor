`timescale 1ns / 1ps

module vending_controllerTB;
    //reg input drivers
    reg CLK, RESET, RETURN;
    reg inquarter, indime,innickle;
    reg inbev1,inbev2,inbev3;
    //wire outputs
    wire outquarter, outdime, outnickle;
    wire outbev1, outbev2, outbev3;
    
    //simulation variables- change these for different simulation effects
    localparam quarters = 5;
    localparam dimes = 0;
    localparam nickels = 0;
    //localparam ret = 0;   -> added after submission + review for confusion purposes
    
    //clock driver
    initial begin
        CLK =0;
        forever begin
            #20 CLK = ~CLK;
        end
    end
    
    //hardware driver
    initial begin
    RESET <=1;  //reset the hardware
    RETURN <=0;  //Button not pressed
    
    //initialize inputs to 0
    {inquarter, indime, innickle} <= 3'B000;
    {inbev1, inbev2, inbev3} <= 3'B000;
    
    #40;    //wait one clock cycle
    RESET <= 0;

    // <<1 allows the correct simulated amount of coins to be serialized with correct pulse width
    repeat (quarters<<1) begin
        @(posedge CLK)
            inquarter <= ~inquarter;
        end
    //again for dimes
    repeat (dimes<<1) begin
        @(posedge CLK)
            indime <= ~indime;
        end
    //again for nickels
    repeat (nickels<<1) begin
        @(posedge CLK)
            innickle <= ~innickle;
        end
    #40;    //wait a clock cycle
    {inbev1, inbev2, inbev3, RETURN} <= 4'B0100;
    //RETURN <= ret;    -> added after due to confusion
    #40;    //wait one clock cycle
    {inbev1, inbev2, inbev3, RETURN} <= 4'B0000;
    //RETURN <= ret; -> added after due to confusion
    end
    
vending_controller UUT(.CLK(CLK), .RESET(RESET), .inquarter(inquarter), .indime(indime),
.innickle(innickle), .inbev1(inbev1), .inbev2(inbev2), .inbev3(inbev3), .outbev1(outbev1),
.outbev2(outbev2), .outbev3(outbev3), .outquarter(outquarter), .outdime(outdime), .outnickle(outnickle), .RETURN(RETURN));
    
    
endmodule