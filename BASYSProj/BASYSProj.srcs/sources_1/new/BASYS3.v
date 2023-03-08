module BASYS3(CLK,OCP,IPS,IR,COLOR,SQUARE, RESET, ENCOL,ENPWM, CTRLF, CTRLR, CLICK_LEFT, CLICK_RIGHT,
    RED,GRN,BLU,S0,S1,S2,S3, LED, PWMA,PWMB,PWMSERVO, DIR1,DIR2,DIR3,DIR4, RELAY, ENABLE,seg,
    REG_LEDS);
    
//DECLARE THE INPUT SIGNALS AND OUTPUT SIGNALS
input CLK, OCP, IPS, IR, COLOR,SQUARE, RESET, ENCOL, ENPWM, CTRLF, CTRLR, CLICK_LEFT, CLICK_RIGHT;
output RED,GRN,BLU,S0,S1,S2,S3, PWMA,PWMB,PWMSERVO, RELAY, DIR1,DIR2,DIR3,DIR4;
output [3:0] ENABLE;
output [6:0] seg;

output wire [6:0] LED;
output wire [8:0] REG_LEDS;

//wire outputs of modules that loop to other modules
wire OCSIG,IPSSIG,IRSIG, OUTA,OUTB, REDDIG,GRNDIG,BLUDIG,REDTCS,GRNTCS,BLUTCS,REDin,GRNin,BLUin, FOUND,FINISH, kHzCLK;
wire DISCOL, ENABLECOL;
//INPUT SIGNALS
PULLDOWN_INVERTER MASTER_BOARD(OCP, OCSIG, IPS, IPSSIG, IR, IRSIG);   //INVERTS EXTERNAL HARDWARE LOGIC

//MOTOR MODULES
OCRES RES(CLK, OCSIG, RELAY);                //RESETS OVERCURRENT AS NEEDED
PWM_GENERATOR MOTORA(CLK,OUTA,FOUND,FINISH); //CREATES A 25KHZ 50% DUTY CYCLE WAVE
PWM_GENERATOR MOTORB(CLK,OUTB,FOUND,FINISH); //CREATES A 25KHZ 50% DUTY CYCLE WAVE
DIRECTION_CONTROLLER CONTROLLER(CLK, IPSSIG,IRSIG, CTRLF, CTRLR,DIR1,DIR2,DIR3,DIR4, CLICK_LEFT, CLICK_RIGHT);    //MOTOR DIRECTION CONTROLLER
assign ENABLECOL = ~DISCOL & ENCOL;
//COLORSENSOR SUBMODULES
HZ_COUNTER TCS3200(ENABLECOL,CLK, SQUARE, S0,S1,S2,S3, REDTCS,GRNTCS,BLUTCS);
COLORSEN DIGICOL(ENABLECOL, CLK, COLOR, RED,GRN,BLU, REDDIG,GRNDIG,BLUDIG);
//UPDATE TRUE COLORSENSOR VALUE
assign REDin = REDTCS & REDDIG;
assign GRNin = GRNTCS & GRNDIG;
assign BLUin = BLUTCS & BLUDIG;

SHIFT_REG FLIP_CHAIN(CLK, REDin,GRNin,BLUin,FOUND,FINISH, REG_LEDS, RESET); //shift register controller
SERVO CLOCK_TOW(FOUND,CLK,REDin,GRNin,BLUin,PWMSERVO);    //SERVO CONTROLLER
CLK_WIZ100K kCLK(CLK, kHzCLK);
SEVENSEG DISPLAY(kHzCLK, REDin, GRNin, BLUin, ENABLE, seg, FOUND);   //SEVENSEG CONTROLLER

//logic for rover control
assign PWMA = ((OUTA & ENPWM) | ((CTRLF | CTRLR) & OUTA)) & ~OCSIG;   //autonomous control on left parenthesis
assign PWMB = ((OUTB & ENPWM) | ((CTRLF | CTRLR) & OUTB)) & ~OCSIG;   //manual control on left, still with pwm
assign LED = {FOUND,FINISH,SQUARE,IRSIG,IPSSIG,OCSIG,COLOR};

endmodule

//MODULE THAT INVERTS LOGIC FROM EXTERNAL HARDWARE
module PULLDOWN_INVERTER(OCIN, OCOUT, IPSIN,IPSOUT, IRIN,IROUT);
    //EXTERNAL HARDWARE INPUTS
    input OCIN, IPSIN, IRIN;
    //SYSTEM OUTPUTS
    output OCOUT, IPSOUT,IROUT;
    
    assign OCOUT = ~OCIN;
    assign IPSOUT= ~IPSIN;
    assign IROUT = IRIN;
endmodule

//THIS MODULE IS DONE AND AUTORESETS THE OC
module OCRES(CLK, OCsig, RES);
input OCsig, CLK;
output reg RES;
reg [28:0] DELAY;

initial begin
    DELAY = 0;
    RES = 0;
end

always @(posedge CLK) begin
    if (OCsig) begin
        DELAY = DELAY +1;   //WAIT 1 SEC WITH HIGH SIG
    end
    if (DELAY >= 150000000)  begin//AFTER 1.5 s, execute this:
       RES = 1; //short cap for 1 sec
       DELAY = DELAY +1; //keep counting for another sec
    end
    else begin
       RES = 0; //allow float
       end
end
endmodule

//GENERATE A 50% PWM WAVE FOR MOTOR
module PWM_GENERATOR(CLK,PWM, FOUND, FINISH);
    input CLK, FOUND, FINISH;
    output reg PWM;
    reg [11:0] COUNTER;
    localparam WIDTH = 2000;
    
    initial begin
    COUNTER = 0;
    PWM = 0;
    end
    
    //create the 25 kHz signal
    always @(posedge CLK) begin
        COUNTER = COUNTER +1;
        if (COUNTER >= 4000)
            COUNTER = 0;
    end
    
    //Create the 50% duty cycle
    always @(posedge CLK) begin
        if (COUNTER <= WIDTH) begin
            PWM = 1;
        end
        else begin
            PWM = 0;
        end
        //COLOR FOUND OR END OF PROGRAM, so pause
        if (FOUND || FINISH) begin
            PWM = 0;
        end
    end
endmodule

//COLOR SENSOR BOARD STATE
module COLORSEN(EN, CLK,EXT,RED,GRN,BLU,R_out,G_out,B_out);
    //DEFINE INPUTS
    input CLK, EXT, EN;
    //DEFINE OUTPUTS
    output reg RED,GRN,BLU, R_out,G_out,B_out;
    
    reg [2:0] COLOROUT; //CONTROLS FILTERS
    reg [24:0] DELAY;   //oscillates the color sensor
    
    initial begin
    COLOROUT = 0;
    DELAY = 0;
    RED=0;
    GRN=0;
    BLU=0;
    R_out=0;
    G_out=0;
    B_out=0;
    end
    
    //oscilliate in sync with TCS3200
    always @(posedge CLK) begin
        //only operate on enables
        if (EN) begin
            DELAY = DELAY +1;
            if (DELAY >= 15000000) begin
                COLOROUT = COLOROUT +1;
                DELAY = 0;
            end
        end
        //hold all values to off during disables
        else begin
            COLOROUT = 0;
            DELAY = 0;
        end
    end
    
    always @(posedge CLK) begin
        case (COLOROUT)
            //START OFF & RESET
            3'B000: begin
            {RED, GRN, BLU} = 3'B000;
            {R_out, G_out, B_out} = 3'B000;
            end
            //check red
            3'B001: begin
            {RED, GRN, BLU} = 3'B100;
            // UPDATE if RED was found
            if (EXT)
               R_out = 1;
            end
            //off then GRN
            3'B011: begin
            {RED, GRN, BLU} = 3'B010;
            // UPDATE if BLU was found
            if (EXT)
               G_out = 1;
            end
            //off then BLU
            3'B101: begin
            {RED, GRN, BLU} = 3'B001;
            // UPDATE if BLUE was found
            if (EXT)
               B_out = 1;
            end
            //determine the synchonized output by turning lights off and letting registers float
            3'B111: begin
            {RED, GRN, BLU} = 3'B000;
            end
            default:{RED, GRN, BLU} = 3'B000;
        endcase
    end
endmodule

//100 kHz Clock
module CLK_WIZ100K(CLKin, CLKOUT);
    input CLKin;
    output reg CLKOUT;
    
    reg [9:0] oscillator;
    
    initial begin
    oscillator = 0;
    CLKOUT = 0;
    end
    
    always @(posedge CLKin) begin
        oscillator = oscillator +1;
        if (oscillator >= 1000) begin
            CLKOUT = ~CLKOUT;
            oscillator = 0;
        end
    end
    
endmodule

//Seven segment detection for colors
module SEVENSEG(CLK, RED, GRN, BLU, ENABLE, seg, FOUND);

    input CLK, FOUND;
    input RED, BLU, GRN;
    output reg[3:0] ENABLE;
    output reg [6:0] seg; 
        
 initial begin
    ENABLE = 4'B1111;   //start displays off
 end
 
 reg [15:0] dig_delay = 0;
 
 localparam dash = 7'b0111111;
 localparam H=  7'b0001001;
 localparam R = 7'b1001110;
 localparam E = 7'b0000110;
 localparam D = 7'b0100001;
 localparam B = 7'b0000011; 
 localparam L = 7'b1000111;
 localparam U = 7'b1000001;
 localparam G = 7'b0010000; 
 localparam N = 7'b1001000;
 localparam first = 4'B1110;
 localparam second =4'B1101;
 localparam third = 4'B1011;
 localparam fourth =4'B0111;
 
 always @(posedge CLK) begin
    dig_delay = dig_delay +1;
    if (dig_delay >=12500)
        dig_delay =0;
 end
 
 always @(posedge CLK) begin
        case({FOUND, RED, GRN, BLU})
            //SPELL RED
            4'b0100: begin 
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = R;
             end
             else if (dig_delay <=6250) begin
                 ENABLE = third;
                 seg = E;
             end
             else if (dig_delay <=9375) begin
                 ENABLE = second;
                 seg = D;
             end
             else begin
                 ENABLE = first;
                 seg = dash;
             end
            end
            //SPELL GRN
            4'b0010:  begin
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = G;
             end
             else if (dig_delay <= 6250) begin
                 ENABLE = third;
                 seg = R;
             end
             else if (dig_delay <= 9375) begin
                 ENABLE = second;
                 seg = N;
             end
             else begin
                 ENABLE = first;
                 seg = dash;
             end
            end
            //SPELL BLUE
            4'b0001:   begin
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = B;
             end
             else if (dig_delay <= 6250) begin
                 ENABLE = third;
                 seg = L;
             end
             else if (dig_delay <= 9375) begin
                 ENABLE = second;
                 seg = U;
             end
             else begin
                 ENABLE = first;
                 seg = E;
             end
            end
            //SPELL HERE
            4'b1100:   begin
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = H;
             end
             else if (dig_delay <= 6250) begin
                 ENABLE = third;
                 seg = E;
             end
             else if (dig_delay <= 9375) begin
                 ENABLE = second;
                 seg = R;
             end
             else begin
                 ENABLE = first;
                 seg = E;
             end
            end
            4'b1010:   begin
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = H;
             end
             else if (dig_delay <= 6250) begin
                 ENABLE = third;
                 seg = E;
             end
             else if (dig_delay <= 9375) begin
                 ENABLE = second;
                 seg = R;
             end
             else begin
                 ENABLE = first;
                 seg = E;
             end
            end
            4'b1001:   begin
             if (dig_delay <=3125) begin
                 ENABLE = fourth;
                 seg = H;
             end
             else if (dig_delay <= 6250) begin
                 ENABLE = third;
                 seg = E;
             end
             else if (dig_delay <= 9375) begin
                 ENABLE = second;
                 seg = R;
             end
             else begin
                 ENABLE = first;
                 seg = E;
             end
            end
            default: begin
             ENABLE = 4'B0000;  //all on
             seg = dash;    //all dash
            end
        endcase
        
    end
     
endmodule

//SERVO Controller Works Perfectly
module SERVO(EN, CLK, RED,GRN,BLU, PWMSERVO);
    input EN, CLK, RED,GRN,BLU;
    output reg PWMSERVO;
    
    initial begin
    PWMSERVO = 0; 
    end
     
    reg [20:0] COUNT;
    reg [18:0] WIDTH;
    
    initial begin
        WIDTH = 150000;
        COUNT = 0;
        PWMSERVO=0;
    end
    
    always @(posedge CLK) begin
        COUNT = COUNT +1;
        case ({EN, RED, GRN, BLU})
            4'B1100: WIDTH = 250000;//show red
            4'B1010: WIDTH = 95000;//show grn
            4'B1001: WIDTH = 45000; //blue angle
            default: WIDTH = 0;//float
        endcase
        if (COUNT < WIDTH ) begin 
        PWMSERVO = 1;
        end
        else begin
        PWMSERVO =0;
        if(COUNT >= 2000000)
            COUNT = 0;  //create the correct frequency
        end
    end
endmodule

//SHIFT_REG WORKS PERFECTLY
module SHIFT_REG(CLK, RED,GRN,BLU,FOUND,FINISH, FF_OUT, RESET);
    input CLK, RED, GRN, BLU, RESET; //color sensor state
    output reg FOUND, FINISH; //outputs for top
    output reg [8:0] FF_OUT; //SHOW NUMBER IN FF3
    
    //flip flops
    reg old;
    reg [2:0] FF1;  //entry ff
    reg [2:0] FF2;
    reg [2:0] FF3;
    reg [2:0] FF4;  //outro ff
    reg [2:0] FILL; //how many colors have been pushed
    reg [28:0] WAIT;
    initial begin
        WAIT = 0;
        FF1 = 3'B000;
        FF2 = 3'B000;
        FF3 = 3'B000;
        FF4 = 3'B000;
        FOUND = 0;
        FILL =  0;
        FINISH =0;
    end

    always @(posedge CLK) begin
        if (FOUND)
            WAIT = WAIT +1;
        else
            WAIT = 0;
        //reset after 5 seconds
        if (WAIT >= 500000000)
            WAIT = 0;
    end

    //REGISTER UPDATES WITH CLK for SYNC
    always @(posedge CLK) begin
        //DETERMINE STATE OF MACHINE WHEN TRIGGERED
        case({RED, GRN, BLU})
            3'b100: FF1 = 3'b100;
            3'b010: FF1 = 3'b010;
            3'b001: FF1 = 3'b001;
            default:FF1 = 3'b000;   //load empty, doesn't shift registers because 0 is always in SR before filled, and is never output
        endcase
        //reset the FF if colors read wrong
        if (RESET) begin
            old = 0;
            FF4   = 0;
            FF3   = 0;
            FF2   = 0;
            FF1   = 0;
            FILL  = 0;
            FINISH= 0;
            FOUND = 0;
            end
        //if filling the SR, and the value pushing in doesn't exist already also non-zero
        if (FILL<3 && FF1 != FF2 && FF1 != FF3 && FF1 !=FF4) begin
            FILL = FILL +1;
            //UPDATE THE NEXT REGISTERS TO MATCH LATEST REG
            FF4 = FF3;
            FF3 = FF2;
            FF2 = FF1;
        end
        //only execute when fill has reached 3
        else if (FILL>=3) begin
            //when a color is found after fill
            if(FF1 == FF4 && FF1 !=0) begin
                FOUND=1; //SET SWITCH on FOUND for 2 sec
                FILL = FILL+1; //UPDATE THE PUSHED AMOUNT
                FF4 = FF3;
                FF3 = FF2; //UPDATE FF3
                FF2 = 0;   //CLEAR FF2
            end
            //stop operations for 4.5 seconds like a chad
            if (WAIT >= 450000000)
                FOUND = 0;
            if (FILL >=6) begin
                FILL = 6;   //LOCK FILL
                FINISH = 1; //OUTPUT TO END OF THE PROGRAM
            end
        end
    FF_OUT = {FF2, FF3, FF4};
    end
    
endmodule

//CONTROL THE DIRECTION OF THE ROVER
module DIRECTION_CONTROLLER(CLK, IPS,IR, btnu, btnd, DIR1,DIR2,DIR3,DIR4, LEFTBUMP, RIGHTBUMP, DISABLE);
    //DECLARE ALL INPUTS
    input CLK, IPS, IR, btnu,btnd, LEFTBUMP, RIGHTBUMP;
    //DECLARE OUTPUTS
    output reg DIR1, DIR2, DIR3, DIR4;
    reg STARTA, STARTB;
    reg [28:0] DELAY;   //enables actions up to 5.3 sec
    
    initial begin
    {DIR1,DIR2,DIR3,DIR4} = 4'B1001;    //initial direction forward
    DELAY = 0;
    STARTA= 0;
    STARTB = 0;
    end
    
    reg [28:0] WAIT;
    output reg DISABLE;
    
    always @(posedge CLK) begin
        if (DISABLE)
            WAIT = WAIT +1;
        if (WAIT > 520000000) begin
            WAIT = 0;
            DISABLE = 0;
            end
    end
    
    always @(posedge CLK) begin
        //START A COUNTER
        if (IPS | ~LEFTBUMP)
            STARTA = 1;
            DISABLE = 1;
        if (IR | ~RIGHTBUMP)
            STARTB = 1;
            DISABLE = 1;
        if (STARTA || STARTB)
            DELAY = DELAY+1;
        //RESET THE COUNTER AND CONDITION after 5 seconds
        if (DELAY >= 500000000) begin
            DELAY =0;
            STARTA = 0;
            STARTB = 0;
        end
    end
    
    always @(posedge CLK) begin
        case ({STARTA, STARTB, btnu, btnd})
            //IPS/LBUMP ON, btns not pressed (autonomous)
            4'B1000: begin
                if (DELAY<=200000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B0110;        //REVERSE two SECOND
                else if (DELAY <= 425000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B1010;        //TURN 2.25 SECONDS RIGHT
                else
                {DIR1,DIR2,DIR3,DIR4} = 4'B1001;        //RETURN FORWARD
            end
             //IPS & IR ON or BUMPS, btns not pressed (autonomous)
            4'B1100: begin
                if (DELAY<=200000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B0110;        //REVERSE two SECOND
                else if (DELAY <= 425000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B0101;        //TURN 2.25 SECONDS LEFT
                else
                {DIR1,DIR2,DIR3,DIR4} = 4'B1001;        //RETURN FORWARD
            end
            //IPS ON,btnd pressed (manual)
            4'B1001: {DIR1,DIR2,DIR3,DIR4} = 4'B0110;    //reverse
            //btnu pressed (manual)
            4'B0010: {DIR1,DIR2,DIR3,DIR4} = 4'B1001;    //forward
            //btnd pressed (manual)
            4'B0001: {DIR1,DIR2,DIR3,DIR4} = 4'B0110;    //reverse
            //NO IPS/BUMP, IR + bump (AUTO)
            4'B0100: begin
                if (DELAY<=150000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B0110;        //REVERSE 1.5 SECOND
                else if (DELAY <= 450000000)
                {DIR1,DIR2,DIR3,DIR4} = 4'B0101;        //TURN 3 SECONDS RIGHT
                else
                {DIR1,DIR2,DIR3,DIR4} = 4'B1001;        //RETURN FORWARD
            end

            default: {DIR1,DIR2,DIR3,DIR4} = 4'B1001;    //return direction forward

        endcase
    end
    
endmodule

//TCS3200 Submodule
module HZ_COUNTER(EN, CLK,TOGGLE, S0,S1,S2,S3, RED,GRN,BLU);
    //INPUTS
    input CLK, TOGGLE, EN;
    //OUTPUT CONTROL
    output reg S0,S1,S2,S3; //S0, S1 = pow||S2, S3 = filter 
    output reg RED, GRN, BLU;  //outputs
                
    reg old_sig;        //tracks old state of the signal
    reg [24:0] DELAY;   //oscillates color sen
    reg [2:0] COLOROUT; //controls the filters
    
    reg [15:0] red;     //red tracker
    reg [15:0] grn;     //grn tracker
    reg [15:0] blu;     //blu tracker

    //initalize all registers to 0
    initial begin
        DELAY = 0;
        old_sig = 0;
        COLOROUT = 0;
        red=0;
        grn=0;
        blu=0;
        {S0, S1} = 2'B00;   //sensor powered off.
        {S2, S3} = 2'B00;   //RED at 0
        {RED, GRN, BLU} = 3'B000;

    end
    
    //Timer for COLOROUT and DELAY of READS. 7 * time = calculation time, track color state
    always @(posedge CLK) begin
        //only operate on ENABLES
        if (EN) begin
            DELAY = DELAY +1;
            //after . sec, change filters
            if (DELAY >=15000000) begin
                COLOROUT = COLOROUT +1;
                DELAY = 0;
            end
            old_sig <= TOGGLE;
        end
        //HOLD SIGNALS TO 0 ON DISABLES
        else begin
            DELAY = 0;
            old_sig = 0;
            COLOROUT = 0;
        end
    end
        
    always @(posedge CLK) begin
            case (COLOROUT)
            //reset the TCS3200
            3'B000: begin
                red = 0;
                grn = 0;
                blu = 0;
                {S0, S1} = 2'B00; //sensor power off
                {RED, GRN, BLU} = 3'B000;
            end
            //calculate the red register
            3'B001: begin
                {S2, S3} = 2'B00;   //red filter
                {S0, S1} = 2'B10;   //sensor on at 20%
                if (TOGGLE != old_sig)
                    red = red +1;   //increment the red register in this time
            end
            //off then grn register
            3'B011: begin
                {S2, S3} = 2'B11;   //grn filter
                {S0, S1} = 2'B10;   //sensor on at 20%
                if (TOGGLE != old_sig)
                    grn = grn +1;   //increment the GRN register in this time
            end
            //off then blu register
            3'B101: begin
                {S2, S3} = 2'B01;   //blu filter
                {S0, S1} = 2'B10;   //sensor on at 20%
                if (TOGGLE != old_sig)
                    blu = blu +1;   //increment the BLU register in this time
            end
            //off then calculate and output the highest color
            3'B111: begin

                if(red > grn && red > blu && red >1000 && grn<800) begin
                    {RED, GRN, BLU} = 3'B100;
                end
                else if(blu > grn && blu > 650) begin
                    {RED, GRN, BLU} = 3'B001;
                end
                else if(grn> 500 && grn>blu && red <1000) begin
                    {RED, GRN, BLU} = 3'B010;
                end
                else
                    {RED, GRN, BLU} = 3'B000;
            end
            default: {S0, S1} = 2'B00;  //power off TCS3200 Between states
            endcase
    end
endmodule