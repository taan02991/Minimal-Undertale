`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2020 12:42:28 PM
// Design Name: 
// Module Name: circle
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module circle #(
    R=5,
    IX=100,
    IY=100,
    DIR_X=1,
    DIR_Y=0,
    D_WIDTH=200,
    D_HEIGHT=200
    )
    (
    input wire[9:0] x,
    input wire[9:0] y,
    input wire clk,
    input wire rst,
    input wire is_active,
    output wire is_intersected
    );
    reg[9:0] h = IX;
    reg[9:0] k = IY;
    reg dir_x = DIR_X;
    reg dir_y = DIR_Y;
    
    assign is_intersected = (((x-h)*(x-h) + (y-k)*(y-k) <= R*R) && is_active) ? 1 : 0; 
    
    always @(posedge clk) begin
        if(rst) begin
            h = IX;
            k = IY;
            dir_x = DIR_X;
            dir_y = DIR_Y;
        end
        if(is_active) begin
            h = dir_x ? h + 1: h - 1;
            k = dir_y ? k + 1: k - 1;
            if(h <= R + 1) dir_x = 1;
            if(h >= D_WIDTH - R + 1) dir_x = 0;
            if(k <= R + 1) dir_y = 1;
            if(k >= D_HEIGHT - R + 1) dir_y = 0;
        end
    end
endmodule
