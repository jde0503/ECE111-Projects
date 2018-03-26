`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineers: Joshua Escobar, PID: A11606542
//            Daniel Yeung,   PID: A14195251
// 
// Create Date: 11/11/2017 06:54:19 PM
// Design Name: Floating Point Adder
// Module Name: adder_fp
// Project Name: ECE 111 Project 4
// Target Devices: ZYNQ-7 ZC702 Evaluation Board
// Description: Contains module for a floating point adder
//              Format: Single (32 bit) precsion IEEE 754
//
// Revision:
// Revision 2 - Reworked
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////


module adder_fp(
    input logic clk,
    input logic start,
    input logic op,
    input logic [31:0] A,
    input logic [31:0] B,
    output logic ready,
    output logic busy,
    output logic [31:0] Y = 32'd0
    );
    
    // Internal Variable Declaration
    logic [26:0] a_m, b_m;
    logic [23:0] y_m;
    logic signed [9:0] a_e, b_e, y_e;
    logic a_s, b_s, y_s;
    logic guard, roundBit, sticky;
    logic [27:0] sum;
    logic [2:0] state = 3'd0;
    logic firstCycle = 1;
    
    
    // Parameter Declaration
    parameter idleAndUnpack = 3'd0,
              specialCases = 3'd1,
              add_s1 = 3'd2,
              add_s2 = 3'd3,
              normalize_s1 = 3'd4,
              normalize_s2 = 3'd5,
              round = 3'd6,
              pack = 3'd7;
    
    always_ff @ (posedge clk) begin
        case (state)
            idleAndUnpack: begin
                busy <= 0;
                ready <= 0;
                if (start == 1 && firstCycle == 0) begin
                    busy <= 1;
                    a_m <= {1'b1, A[22:0], 3'd0};
                    b_m <= {1'b1, B[22:0], 3'd0};
                    a_e <= A[30:23] - 10'd127;
                    b_e <= B[30:23] - 10'd127;
                    a_s <= A[31];
                    b_s <= B[31] ^ op;
                    state <= specialCases;
                end
                else begin
                    firstCycle <= 0;
                    state <= idleAndUnpack;
                end
            end
            
            specialCases: begin
                // If A or B is NaN, return NaN
                if ((a_e == 128 && a_m[25:0] != 0)
                 || (b_e == 128 && b_m[25:0] != 0)) begin
                    Y[31:0] <= ~0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A and B are inf with differing signs, return NaN
                else if ((a_e == 128 && a_m[25:0] == 0 && b_e == 128 && b_m[25:0] == 0)
                 && (a_s != b_s)) begin
                    Y[31] <= 1;
                    Y[30:0] <= ~0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A and B are inf with same sign, return inf with appropriate sign
                else if ((a_e == 128 && a_m[25:0] == 0 && b_e == 128)
                      && (b_m[25:0] == 0)) begin
                    Y[31] <= a_s;
                    Y[30:23] <= ~0;
                    Y[22:00] <= 0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A + B = inf + X, return Inf with appropriate sign
                else if (a_e == 128 && a_m[25:0] == 0 && b_e != 128 && b_m[25:0] != 0) begin
                    Y[31] <= a_s;
                    Y[30:23] <= ~0;
                    Y[22:0] <= 0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A + B = X + inf, return inf with appropriate sign
                else if (b_e == 128 && b_m[25:0] == 0 && a_e != 128 && a_m[25:0] != 0) begin
                    Y[31] <= b_s;
                    Y[30:23] <= ~0;
                    Y[22:0] <= 0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A and B are 0, return 0
                else if ((a_e == -127 && a_m[25:0] == 0 && b_e == -127)
                      && (b_m[25:0] == 0)) begin
                    Y <= 0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A is 0, return B
                else if (a_e == -127 && a_m[25:0] == 0) begin
                    Y[31] <= b_s;
                    Y[30:23] <= b_e[7:0] + 127;
                    Y[22:0] <= b_m[25:3];
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If B is 0, return A
                else if (b_e == -127 && b_m[25:0] == 0) begin
                    Y[31] <= a_s;
                    Y[30:23] <= a_e[7:0] + 127;
                    Y[22:0] <= a_m[25:3];
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // If A = B with differing signs, return 0
                else if ((a_e == b_e && a_m == b_m) && (a_s != b_s)) begin
                    Y <= 0;
                    ready <= 1;
                    state <= idleAndUnpack;
                end
                // Otherwise, start alignment
                else begin
                    if (a_e > b_e) begin
                        b_e <= b_e + 1;
                        b_m <= b_m >> 1;
                        b_m[0] <= b_m[0] | b_m[1];
                    end
                    else if (a_e < b_e) begin
                        a_e <= a_e + 1;
                        a_m <= a_m >> 1;
                        a_m[0] <= a_m[0] | a_m[1];
                    end
                    else
                        state <= add_s1;
                end
            end
            
            add_s1: begin
                y_e <= a_e;
                if (a_s == b_s) begin
                    sum <= a_m + b_m;
                    y_s <= a_s;
                end
                else begin
                    if (a_m >= b_m) begin
                        sum <= a_m - b_m;
                        y_s <= a_s;
                    end
                    else begin
                        sum <= b_m - a_m;
                        y_s <= b_s;
                    end
                end
                state <= add_s2;
            end
            
            add_s2: begin
                if (sum[27]) begin
                    y_m <= sum[27:4];
                    guard <= sum[3];
                    roundBit <= sum[2];
                    sticky <= sum[1] | sum[0];
                    y_e <= y_e + 1;
                end
                else begin
                    y_m <= sum[26:3];
                    guard <= sum[2];
                    roundBit <= sum[1];
                    sticky <= sum[0];
                end
                state <= normalize_s1;
            end
            
            normalize_s1: begin
                if (y_m[23] == 0 && y_e > -126) begin
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
