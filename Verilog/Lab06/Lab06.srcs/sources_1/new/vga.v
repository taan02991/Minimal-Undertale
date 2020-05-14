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

	//health
	reg [1:0] hero = 3;
	reg [1:0] mon1 = 3;
	reg [1:0] mon2 = 3;

	//state controller
	reg [2:0] state = 0;

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
    initial begin
        h = 320;
        k = 240;
    end

    always @(posedge clk) begin
			//start_bee

			//end_bee


			//start_taan

			//end_taan


			//start_tee

			//end_tee


			//start_pud

			//end_pud


			//start_ou

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
	       8'h20: begin led[0] = 1; sel_color = 12'b111111111111; end //SPACE
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
