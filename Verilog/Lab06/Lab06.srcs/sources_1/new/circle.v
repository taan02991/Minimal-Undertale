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


module circle(
    output[9:0] ty,
    output[9:0] by,
    output[9:0] lx,
    output[9:0] rx,
    input[9:0] y,
    input[9:0] x
    );
    
    assign ty = y + 100;
    assign by = y - 100;
    assign lx = x - 100;
    assign rx = x + 100;



endmodule
