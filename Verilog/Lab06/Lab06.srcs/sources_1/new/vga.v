`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Bee's Group
// Engineer: Bee's Group
//
// Create Date: 05/14/2020 03:31:32 PM
// Design Name: Bee's Group
// Module Name: vga
// Project Name: Bee's Group
// Target Devices: Bee's Group
// Tool Versions: Bee's Group
// Description: Bee's Group
//
// Dependencies: Bee's Group
//
// Revision: Bee's Group
// Revision 0.01 - File Created
// Additional Comments: Bee's Group
//
//////////////////////////////////////////////////////////////////////////////////
module vga_sync
	(
		input wire clk, reset,
		output wire hsync, vsync, video_on, p_tick,
		output wire [9:0] x, y
	);

	// constant declarations for VGA sync parameters
	localparam H_DISPLAY       = 640; // horizontal display area
	localparam H_L_BORDER      =  48; // horizontal left border
	localparam H_R_BORDER      =  16; // horizontal right border
	localparam H_RETRACE       =  96; // horizontal retrace
	localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
	localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
	localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;

	localparam V_DISPLAY       = 480; // vertical display area
	localparam V_T_BORDER      =  10; // vertical top border
	localparam V_B_BORDER      =  33; // vertical bottom border
	localparam V_RETRACE       =   2; // vertical retrace
	localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
        localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
	localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;

	// mod-4 counter to generate 25 MHz pixel tick
	reg [1:0] pixel_reg;
	wire [1:0] pixel_next;
	wire pixel_tick;

	always @(posedge clk, posedge reset)
		if(reset)
		  pixel_reg <= 0;
		else
		  pixel_reg <= pixel_next;

	assign pixel_next = pixel_reg + 1; // increment pixel_reg

	assign pixel_tick = (pixel_reg == 0); // assert tick 1/4 of the time

	// registers to keep track of current pixel location
	reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;

	// register to keep track of vsync and hsync signal states
	reg vsync_reg, hsync_reg;
	wire vsync_next, hsync_next;

	// infer registers
	always @(posedge clk, posedge reset)
		if(reset)
		    begin
                    v_count_reg <= 0;
                    h_count_reg <= 0;
                    vsync_reg   <= 0;
                    hsync_reg   <= 0;
		    end
		else
		    begin
                    v_count_reg <= v_count_next;
                    h_count_reg <= h_count_next;
                    vsync_reg   <= vsync_next;
                    hsync_reg   <= hsync_next;
		    end

	// next-state logic of horizontal vertical sync counters
	always @*
		begin
		h_count_next = pixel_tick ?
		               h_count_reg == H_MAX ? 0 : h_count_reg + 1
			       : h_count_reg;

		v_count_next = pixel_tick && h_count_reg == H_MAX ?
		               (v_count_reg == V_MAX ? 0 : v_count_reg + 1)
			       : v_count_reg;
		end

        // hsync and vsync are active low signals
        // hsync signal asserted during horizontal retrace
        assign hsync_next = h_count_reg >= START_H_RETRACE
                            && h_count_reg <= END_H_RETRACE;

        // vsync signal asserted during vertical retrace
        assign vsync_next = v_count_reg >= START_V_RETRACE
                            && v_count_reg <= END_V_RETRACE;

        // video only on when pixels are in both horizontal and vertical display region
        assign video_on = (h_count_reg < H_DISPLAY)
                          && (v_count_reg < V_DISPLAY);

        // output signals
        assign hsync  = hsync_reg;
        assign vsync  = vsync_reg;
        assign x      = h_count_reg;
        assign y      = v_count_reg;
        assign p_tick = pixel_tick;
endmodule

module vga_test
	(
		input wire clk,
		input wire [11:0] sw,
		input wire [1:0] push,
		output wire hsync, vsync,
		output wire [11:0] rgb,
		input wire[7:0] char,
		output reg[15:0] led
	);

	parameter WIDTH = 640;
	parameter HEIGHT = 480;
    parameter MIN_HERO_HEALTH = 221;
	parameter MAX_HERO_HEALTH = 419;
	parameter MIN_MONT1_HEALTH = 50;
    parameter MIN_MONT2_HEALTH = 326;	
    parameter MAX_MONT1_HEALTH = 319;
    parameter MAX_MONT2_HEALTH = 611;

	//clk div
	reg[23:0] target_clk;

	//health
	reg [10:0] hero_health = MAX_HERO_HEALTH;
//	reg [1:0] mon1 = 3;
//	reg [1:0] mon2 = 3;
	reg [10:0] mont_1_health = MAX_MONT1_HEALTH;
    reg [10:0] mont_2_health = MAX_MONT2_HEALTH;

	//state controller
	reg [2:0] state = 1;

	// register for Basys 2 8-bit RGB DAC
	reg [11:0] rgb_reg;
	reg reset = 0;
	wire [9:0] x, y;

	// video status output from vga_sync to tell when to route out rgb signal to DAC
	wire video_on;
    wire p_tick;
	// instantiate vga_sync
	vga_sync vga_sync_unit (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync), .video_on(video_on), .p_tick(p_tick), .x(x), .y(y));

	// rgb circle
	reg[9:0] h, k;
	reg[18:0] d_sq;
	reg [11:0] sel_color;
	reg [9:0] move;
	reg [1:0] direction;
	wire H_is_intersected;
	reg H_rst, H_is_active;
	hero inw(x - 220, y - 140, clk, H_rst, H_is_active, char, H_is_intersected);
	wire C_is_intersected;
	reg C_rst, C_is_active, C2_rst, C2_is_active, CX_rst, CX_is_active,CX2_rst, CX2_is_active;
	
	circle #(.IX(80), .IY(0)) c(x - 220, y - 140, target_clk[18], C_rst, C_is_active, C_is_intersected);
	circle #(.IX(200), .IY(100)) c2(x - 220, y - 140, target_clk[18], C2_rst, C2_is_active, C2_is_intersected);
	circleX #(.IX(80), .IY(0)) cx(x - 220, y - 140, target_clk[18], CX_rst, CX_is_active, CX_is_intersected);
	circleX #(.IX(180), .IY(220), .STEP_X(0), .STEP_Y(5)) cx2(x - 220, y - 140, target_clk[18], CX2_rst, CX2_is_active, CX2_is_intersected);
	
	Pixel_On_Text2 #(.displayText("Nonthanat Theeratanapartkul  6031019821")) t1(
                clk,
                200, // text position.x (top left)
                100, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                res  // result, 1 if current pixel is on text, 0 otherwise
   );
   Pixel_On_Text2 #(.displayText("Thanawat Jierawatanakanok    6031020321")) t2(
                clk,
                200, // text position.x (top left)
                150, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                res2  // result, 1 if current pixel is on text, 0 otherwise
   );
   Pixel_On_Text2 #(.displayText("Nithipud Tunticharoenviwat   6031032921")) t3(
                clk,
                200, // text position.x (top left)
                200, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                res3  // result, 1 if current pixel is on text, 0 otherwise
   );
   Pixel_On_Text2 #(.displayText("Krit Kruaykitanon            6031002021")) t4(
                clk,
                200, // text position.x (top left)
                250, // text position.y (top left)
                x, // current position.x
                y, // current position.y
                res4  // result, 1 if current pixel is on text, 0 otherwise
   );
    
   
	 
	// hero_is_alive from hero_blood is lower than MIN_HERO_HEALTH
	// mont_is_alive use the same logic here
    reg can_attack = 0;
    // attack_to : 1 >> attack mont 1, attack_to : 2 >> attack mont 2
    reg [1:0] attack_to = 0; 
    reg attack_bar_moving = 0;
	
    initial begin
        h = 320;
        k = 240;
        H_rst = 0;
        H_is_active = 1;
        C_rst = 0;
        C_is_active = 1;
        C2_rst = 0;
        C2_is_active = 1;
        CX_rst = 0;
        CX_is_active = 1;
        CX2_rst = 0;
        CX2_is_active = 1;
        
        
        // attack bar
        move = 1;
        direction = 1;
        
    end

    always @(posedge clk) begin
			//start_bee

			//end_bee
            
            
			//start_taan
			// Rectangle block in bullet avoiding phase
            if( ((x == 220 || x == 420) && (y >= 140 && y <= 340)) 
            || ((x >= 220 && x <= 420) && (y == 140 || y == 340)) ) begin
                rgb_reg = 12'b111111111111;
            end
            // hero blood frame
            else if( ((x == MIN_HERO_HEALTH-1 || x == MAX_HERO_HEALTH+1) && (y >= 50 && y <= 80)) 
            || ((x >= MIN_HERO_HEALTH-1 && x <= MAX_HERO_HEALTH+1) && (y == 50 || y == 80)) ) begin
                rgb_reg = 12'b111111111111;
            end
            // Monster 1 blood frame
            else if( ((x == MIN_MONT1_HEALTH-1 || x == MAX_MONT1_HEALTH+1) && (y >= 400 && y <= 420)) 
            || ((x >= MIN_MONT1_HEALTH-1 && x <= MAX_MONT1_HEALTH+1) && (y == 400 || y == 420)) ) begin
                rgb_reg = 12'b111111111111;
            end
            // Monster 2 blood frame
            else if( ((x == MIN_MONT2_HEALTH-1 || x == MAX_MONT2_HEALTH+1) && (y >= 400 && y <= 420)) 
            || ((x >= MIN_MONT2_HEALTH-1 && x <= MAX_MONT2_HEALTH+1) && (y == 400 || y == 420)) ) begin
                rgb_reg = 12'b111111111111;
            end
            // attack bar frame
            else if(( ((x == 150 || x == 490) && (y >= 350 && y <= 390)) 
            || ((x >= 150 && x <= 490) && (y == 350 || y == 390)) )&& state==2) begin
                rgb_reg = 12'b111111111111;
            end
            // attack bar pin go and back in frame 150 and 490
            else if( (x >= 151+move && x <= 155+move)  && (y >= 351 && y <= 388) && state==2) begin
                rgb_reg = 12'b111111111111;         
            end   
            else begin
                rgb_reg = 12'b000000000000;
            end
            
            
            // hero blood            
            if( (y >= 51 && y <= 79)
            && (x >= MIN_HERO_HEALTH && x <= hero_health) ) begin
                rgb_reg = 12'b111100000000;
            end
            // monster 1's blood
            else if( (y >= 401 && y <= 419) 
            && (x >= MIN_MONT1_HEALTH && x <= mont_1_health) ) begin
                rgb_reg = 12'b000000001111;
            end
            // monster 2's blood
            else if( (y >= 401 && y <= 419)
            && (x >= MIN_MONT2_HEALTH && x <= mont_2_health)) begin
                rgb_reg = 12'b000011110000;
            end
            


            if(H_is_intersected) begin // Hero
                rgb_reg = 12'b111100000000;
            end
            if(C_is_intersected) begin // Circle
                rgb_reg = 12'b000000001111;
            end
            if(C2_is_intersected) begin // Circle
                rgb_reg = 12'b000000001111;
            end
            if(CX_is_intersected) begin // CircleX
                rgb_reg = 12'b000011110000;
            end
            if(CX2_is_intersected) begin // CircleX
                rgb_reg = 12'b000011110000;
            end
            if(H_is_intersected && C_is_intersected) begin
                C_is_active = 0;
                hero_health = hero_health - 50;
            end
            if(H_is_intersected && C2_is_intersected) begin
                C2_is_active = 0;
                hero_health = hero_health - 50;
            end
            if(H_is_intersected && CX_is_intersected && CX_is_active) begin
                CX_is_active = 0;
                hero_health = hero_health - 100;
            end
            if(H_is_intersected && CX2_is_intersected && CX2_is_active) begin
                CX2_is_active = 0;
                hero_health = hero_health - 100;
            end
            target_clk = target_clk + 1;
			//end_taan


			//start_pud
			if(state==2) begin
			// control logic of attack bar
            if(x == 155 && y==489 && attack_bar_moving && state==2) begin 
                if(direction)begin
                   move = move+3;
                end
                else begin
                   move = move-3;
                end
               if(move > 490 - 150 - 5 && attack_bar_moving) begin
                  direction = 0;
                end
                else if (move < 4) begin
                  direction = 1;
                end
            end
            
			   //guide line attack bar
               if(x >= 270 && x <= 370 && y <= 393 && y >= 346 && state==2) begin
                rgb_reg = 12'b111100000000;
               end
               
            end
			//end_pud

			//start_ou
            if(res || res2 || res3 || res4) begin
                rgb_reg = 12'b111111111111;
            end
			//end_ou

//        if( ( (x-h)*(x-h) + (y-k)*(y-k) ) <= 10000) begin
//            rgb_reg = sel_color;
//        end
//        else begin
//            rgb_reg = 12'b000000000000;
//        end
    end

	always @(posedge clk) begin
	    case(char)
	       8'h00: led[8] = 1;
	       8'h20: begin 
	           led[0] = 1; sel_color = 12'b111111111111; 
	           if (attack_bar_moving && can_attack && attack_to != 0) begin
	               attack_bar_moving = 0;
	               if(attack_to == 1) begin
	                   if(state == 2) begin
	                       //100px from center(x=320) area
                           if(move+153 >= 270 && move+153 <= 370) begin
                               mont_1_health = mont_1_health - 100;
                           end
                           else begin
                               mont_1_health = mont_1_health - 50;
                           end
                           state = 1;
    	               end
	               end
	               else if(attack_to == 2) begin
	                   if(state ==2) begin
                           //100px from center(x=320) area
                           if(move+153 >= 270 && move+153 <= 370) begin
                               mont_2_health = mont_2_health - 100;
                           end
                           else begin
                               mont_2_health = mont_2_health - 50;
                           end
                           state = 1;
    	               end
	               end
	               attack_to = 0;
	               can_attack = 0;
	           end
	           // push space bar again to hit monsteer // test
//	           else begin attack_bar_moving = 1; end;
	       end //SPACE
	       8'h6c: begin // L
	           //change state to attack state
	           state = 2;
	       
	           // need to check state in attack mode
	           if(can_attack == 0 && MIN_MONT1_HEALTH+10 <= mont_1_health) begin
	               can_attack = 1;
	               attack_to = 1;
	               attack_bar_moving = 1;
	               led[1] = 1;
	           end
	       end
	       8'h72: begin // R
	           //change state to attack state
	           state = 2;
	       
	           if(can_attack == 0 && MIN_MONT2_HEALTH+10 <= mont_2_health) begin
	               can_attack = 1;
	               attack_to = 2;
	               attack_bar_moving = 1;
	               led[2] = 1;
	           end
	       end
	       8'h6d: begin led[1] = 1; sel_color = 12'b111100001111; end //m
	       8'h63: begin led[2] = 1; sel_color = 12'b000011111111; end //c
	       8'h79: begin led[3] = 1; sel_color = 12'b111111110000; end //y
	       8'h77: begin led[4] = 1; k = k - 1; end//w
	       8'h73: begin led[5] = 1; k = k + 1; end //s
	       8'h64: begin led[6] = 1; h = h + 1; end //d
	       8'h61: begin led[7] = 1; h = h - 1; end //a
	       default: led = 0;
	    endcase
	end

//	output
	assign rgb = (video_on) ? rgb_reg : 12'b0;
endmodule


