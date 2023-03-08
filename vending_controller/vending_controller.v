`timescale 1ns / 1ps

module vending_controller(
    input CLK,
    input RESET,
    input inquarter,
    input indime,
    input innickle,
    input inbev1,
    input inbev2,
    input inbev3,
    input RETURN,
    output reg outquarter,
    output reg outdime,
    output reg outnickle,
    output wire outbev1,
    output wire outbev2,
    output wire outbev3
    );
    
    reg EN, RET, bev1, bev2, bev3;
    integer price;      //integer allows a large amt of money to be inserted without overflow
    integer balance;    //realistically though, the largest price is 120, which only requires 7 bits to represent
    
    assign outbev1 = EN & bev1;
    assign outbev2 = EN & bev2;
    assign outbev3 = EN & bev3;
    
    always @(posedge CLK) begin
        //Hardware reset registers when line is high
        if (RESET) begin
            balance<=0;
            price<=0;
            EN<=0;
            RET<=0;
            {bev1, bev2, bev3} <= 3'B000;
            {outquarter, outdime, outnickle} <= 3'B000;
        end
        
        //case statement allows price to be changed based on selection, no default means the price register remains unmodified between cycles
        case ({inbev1, inbev2, inbev3})
            3'B100: begin 
            price <= 100;
            //save the current selection when button released  //disable switched cases i.e. 2 -> 1 leaves bev2 = 1 and bev1=1 for the price of bev 1.
            {bev1, bev2, bev3} <= 3'B100;
            end
            3'B010: begin 
            price <= 120;
            {bev1, bev2, bev3} <= 3'B010;
            end
            3'B001: begin
            price <= 115;
            {bev1, bev2, bev3} <= 3'B001;   //'exotic' syntax to set 3 bits ;)
            end
        endcase
    
        //case statement that modifies balance based on coin inputs
        case({inquarter, indime, innickle})
            3'B100: balance <= balance + 25;
            3'B010: balance <= balance + 10;
            3'B001: balance <= balance + 5;
        endcase
        
        //if a selection is made, and the balance >= price, vend selection
        if(price>0 && balance >= price) begin
            EN <= 1; //active high 1 clock cycle and vends
            price <= 0;
            balance <= balance - price; //update the balance to be the remainder
            RET<=1;     //return change to user
        end
        else begin
            EN <= 0;
        end
        
        //Input button that dispenses change when pressed
        if (RETURN)
            RET <=1;
            
        //return change block
        if (RET && balance >=25) begin
            //toggle the change line
            outquarter<=~outquarter;
            //if the line is toggled high, decrease the balance
            if (outquarter)
                balance <= balance-25;
        end
        else if (RET && balance >=10) begin
            //toggle the change line
            outdime<=~outdime;
            //if the line is toggled high, decrease the balance
            if (outdime)
                balance <= balance-10;
        end
        else if (RET && balance >= 5) begin
            //toggle the change line
            outnickle<=~outnickle;
            //if the line is toggled high, decrease the balance
            if (outnickle)
                balance <= balance-5;
        end
        else if (RET)
            RET <=0;    //stop change distribution
        //clean lines
        else
            {outquarter, outdime, outnickle} <= 3'B000;
    end
   
endmodule