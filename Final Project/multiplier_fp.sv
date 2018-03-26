`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineers: Joshua Escobar, PID: A11606542
//            Daniel Yeung,   PID: A14195251
// 
// Create Date: 11/11/2017 06:54:19 PM
// Design Name: Floating Point Multiplier
// Module Name: multiplier_fp
// Project Name: ECE 111 Project 4
// Target Devices: ZYNQ-7 ZC702 Evaluation Board
// Description: Contains module for a floating point multiplier
//              Format: Single (32 bit) precsion IEEE 754
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Combined idle & pack, specialCases & multiply_s1, pack & final
//						to decrease number of clock cycles needed for operation.
// 
//////////////////////////////////////////////////////////////////////////////////


module multiplier_fp(
    input logic clk,
    input logic start,
    input logic [31:0] A,
    input logic [31:0] B,
    output logic busy,
    output logic ready,
    output logic [31:0] Y = 32'd0
    );
    
    // Internal Variable Declaration
    logic [23:0] a_m, b_m, y_m;
    logic signed [9:0] a_e, b_e, y_e; // 10 bits to check for sign and overflow
    logic a_s, b_s, y_s;
    logic guard, roundBit, sticky;
    logic [49:0] product;
    logic [2:0] state = 3'd0;
	logic firstCycle = 1;
    
    // Parameter Declaration
    parameter idleAndUnpack = 3'd0,
              specialCases = 3'd1,
              multiply_s2 = 3'd2,
              normalize_s1 = 3'd3,
              normalize_s2 = 3'd4,
              round = 3'd5,
              pack = 3'd6;
              
    always_ff @ (posedge clk) begin
        case (state)
            idleAndUnpack: begin
                busy <= 0;
                ready <= 0;
                if (start == 1 && firstCycle == 0) begin
					busy <= 1;
					a_m <= {1'b1, A[22:0]}; // Implicit 1 and fraction from input's mantissa
                	b_m <= {1'b1, B[22:0]}; // Implicit 1 and fraction from input's mantissa
                	a_e <= A[30:23] - 10'd127; // Subtract bias to get signed exponent
                	b_e <= B[30:23] - 10'd127; // Subtract bias to get signed exponent
               		a_s <= A[31];
                	b_s <= B[31];
                	state <= specialCases;
				end
                else begin
					firstCycle <= 0;
                    state <= idleAndUnpack;
				end
            end
            
            specialCases: begin
                // If A or B is NaN, return NaN
                if ((a_e == 128 && a_m[22:0] != 0) || (b_e == 128 && b_m[22:0] != 0)) begin
                    Y[31:0] <= ~0;
					ready <= 1;
                    state <= idleAndUnpack;
                end
                //If A * B = inf * 0, return NaN
                else if (((a_e == 128 && a_m[22:0] == 0) && (b_e == -127 && b_m[22:0] == 0))
                     ||  ((a_e == -127 && a_m[22:0] == 0) && (b_e == 128 && b_m[22:0] == 0))) begin
                    Y[31:0] <= ~0;
					ready <= 1;
                    state <= idleAndUnpack;
                end
                
                // If A or B is inf, return inf with appropriate sign
                else if ((a_e == 128) || (b_e == 128)) begin
                    Y[31] <= a_s ^ b_s;
                    Y[30:23] <= ~0;
                    Y[22:0] <= 0;
					ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A or B are 0, return 0
                else if ((a_e == -127 && a_m[22:0] == 0) || (b_e == -127 && b_m[22:0] == 0)) begin
                    Y <= 0;
					ready <= 1;
                    state <= idleAndUnpack;
                end
                // Otherwise, start multiplication
                else begin
					y_s <= a_s ^ b_s;
                	y_e <= a_e + b_e + 1;
                	product <= a_m * b_m * 4;
					state <= multiply_s2;
				end
                    
            end
            
            multiply_s2: begin
                y_m <= product [49:26];
                guard <= product[25];
                roundBit <= product[24];
                sticky <= |(product[23:0]);
                state <= normalize_s1;
            end
            
            normalize_s1: begin
                if (y_m[23] == 0) begin
                    y_e <= y_e - 1;
                    y_m <= y_m << 1;
                    y_m[0] <= guard;
                    guard <= roundBit;
                    roundBit <= 0;
                end
                else
                    state <= normalize_s2;
            end
            
            normalize_s2: begin
                if (y_e < -126) begin
                    y_e <= y_e + 1;
                    y_m <= y_m >> 1;
                    guard <= y_m[0];
                    roundBit <= guard;
                    sticky <= sticky | roundBit;
                end
                else
                    state <= round;
            end
            
            round: begin
                if (guard && (roundBit | sticky | y_m[0])) begin
                    y_m <= y_m + 1;
                    if (y_m == 24'hffffff) begin
                        y_e <= y_e + 1;
                    end
                end
                state <= pack;
            end
            
            pack: begin
                // If overflow, return inf
                if (y_e > 127) begin
                    Y[31] <= y_s;
                    Y[30:23] <= 255;
                    Y[22:0] <= 0;
					ready <= 1;
                end
                // If underflow, return 0
                else if (y_e == -126 && y_m[23] == 0) begin
                    Y <= 0;
					ready <= 1;
                end
                // Otherwise, pack output
                else begin
                    Y[31] <= y_s;
                    Y[30:23] <= y_e[7:0] + 127;
                    Y[22:0] <= y_m[22:0];
					ready <= 1;
                end
				state <= idleAndUnpack;
            end
            
            default:
                state <= idleAndUnpack;
        endcase
    end 
endmodule