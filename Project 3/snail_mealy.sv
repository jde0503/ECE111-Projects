`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineer: Joshua Escobar, PID: A11606542
// 
// Create Date: 10/30/2017 05:07:51 PM
// Design Name: snail_mealy
// Module Name: snail_mealy
// Project Name: ECE 111 Project 3
// Description: An FSM to recognize bit sequences 1101 or 1110
// 
// Dependencies: None
// 
//////////////////////////////////////////////////////////////////////////////////


module snail_mealy(clk, rst, A, Y);
    
    // Port declaration
    input logic clk, rst, A;
    output logic Y;
    
    // Internal variable declaration
    logic [2:0] state; // 7 states > 3 bits
    
    // Parameter declaration
    parameter s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4, s5 = 3'd5,
              s6 = 3'd6;
              
    // Logic of Mealy Machine
    always_ff @ (posedge clk, posedge rst) begin
        if (rst)
            state <= s0;
            
        else begin
            case (state)
                s0: begin
                    if (A) begin
                        Y <= 0;
                        state <= s1;
                    end
                    else begin
                        Y <= 0;
                        state <= s0;
                    end
                end
                
                s1: begin
                    if (A) begin
                        Y <= 0;
                        state <= s2;
                    end
                    else begin
                        Y <= 0;
                        state <= s0;
                    end
                end
                
                s2: begin
                    if (A) begin
                        Y <= 0;
                        state <= s4;
                    end
                    else begin
                        Y <= 0;
                        state <= s3;
                    end
                end
                
                s3: begin
                    if (A) begin
                        Y <= 1;
                        state <= s5;
                    end
                    else begin
                        Y <= 0;
                        state <= s0;
                    end
                end
                
                s4: begin
                    if (A) begin
                        Y <= 0;
                        state <= s4;
                    end
                    else begin
                        Y <= 1;
                        state <= s6;
                    end
                end
                
                s5: begin
                    if (A) begin
                        Y <= 0;
                        state <= 2;
                    end
                    else begin
                        Y <= 0;
                        state <= s0;
                    end
                end
                
                s6: begin
                    if (A) begin
                        Y <= 1;
                        state <= 5;
                    end
                    else begin
                        Y <= 0;
                        state <= 0;
                    end
                end
                
                default: begin
                    Y <= 0;
                    state <= s0;
                end
            endcase
        end
    end
endmodule