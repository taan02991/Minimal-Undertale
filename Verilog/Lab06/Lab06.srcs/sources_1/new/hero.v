`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/16/2020 12:50:00 AM
// Design Name: 
// Module Name: hero
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

module hero #(
    R=6,
    IX=100,
    IY=100,
    D_WIDTH=200,
    D_HEIGHT=200
    )
    (
    input wire[9:0] x,
    input wire[9:0] y,
    input wire clk,
    input wire rst,
    input wire is_active,
    input wire[7:0] char,
    output wire is_intersected
    );
    reg[9:0] h = IX;
    reg[9:0] k = IY;
//    x,y h,k, R
    
    //assign is_intersected = ( (  (x-h)*(x-h) + (y-k)*(y-k) <= R*R  ) && is_active ) ? 1 : 0;
//    assign X = x-h;
//    assign Y = y-k;
    
    assign is_intersected = (( (x-h)**2 + (y-k)**2 - R**2 )**3 == (x-h)**2*(y-k)**3  && is_active ) ? 1 : 0;

    always @(posedge clk) begin
        if(rst) begin
            h = IX;
            k = IY;
        end
        case(char)
            8'h77: begin k = k < R ? k : k - 1; end //w
            8'h73: begin k = k > D_HEIGHT - R ? k : k + 1; end //s
            8'h64: begin h = h > D_WIDTH - R ? h : h + 1; end //d
            8'h61: begin h = h < R ? h : h - 1; end //a
        endcase
    end

endmodule