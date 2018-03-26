`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineers: Joshua Escobar, PID: A11606542
//            Daniel Yeung,   PID: A14195251
// 
// Create Date: 11/19/2017 06:54:19 PM
// Design Name: Sum of Squared Error (SSE)
// Module Name: SSE
// Project Name: ECE 111 Project 5
// Target Devices: ZYNQ-7 ZC702 Evaluation Board
// Description: Contains module for computing a running sum of squared error
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SSE(
    input logic clk,
    input logic rst,
    input logic pause,
    input logic stop,
    input logic [31:0] A,
    input logic [31:0] B,
    output logic ready,
    output logic next,
    output logic [31:0] Y
    );
    
    // Internal variables and registers
    logic start = 1'b0;
    logic stopped = 1'b0;
    logic  [1:0] countFromStart = 2'd0;
    logic [1:0] countFromStop = 2'd0;
    logic [2:0] readiness = 3'b111;
    logic sub_ready, mult_ready, add_ready;
    logic [31:0] sub_mult_pipe, mult_add_pipe, sum_pipe;
    logic [31:0] sum = 32'd0;
    
    // Instantiate internal modules
    adder_fp subtractor(.clk(clk), .start(start), .op(1'b1), .A(A), .B(B),
                        .busy(), .ready(sub_ready), .Y(sub_mult_pipe));
    multiplier_fp multiplier(.clk(clk), .start(start), .A(sub_mult_pipe),
                             .B(sub_mult_pipe), .busy(),
                             .ready(mult_ready), .Y(mult_add_pipe));
    adder_fp adder(.clk(clk), .start(start), .op(1'b0), .A(mult_add_pipe),
                   .B(sum), .busy(), .ready(add_ready), .Y(sum_pipe));
    
    always_ff @ (posedge clk) begin
        // Check for reset signal
        if (rst) begin
            ready <= 0;
            next <= 1;
            start <= 0;
            countFromStart <= 2'd0;
            countFromStop <= 2'd0;
            stopped <= 0;
            readiness <= 3'b111;
            sum <= 32'd0;
            Y <= 0;
        end
        else begin
            // Check if stop signal has been given
            if (stop)
                stopped <= 1;
            
            // Check if module is stopping, but input needs shifting
            if ((stop || stopped) && (readiness == 3'b111) && (countFromStop < 2'd2)) begin
                readiness <= 0;
                ready <= 0;
                start <= 1;
                countFromStop <= countFromStop + 2'd1;
            end
    
            // Check for new inputs
            else if (next && ~pause && ~stopped) begin
                readiness <= 0;
                next <= 0;
                ready <= 0;
                start <= 1;
                if (countFromStart < 2'd3)
                    countFromStart <= countFromStart + 2'd1;
            end
            
            // Check if ready to request new inputs, shifting, and/or give output
            else if (~pause) begin
                start <= 0;
                
                if ((readiness == 3'b111) && (~stopped))
                    next <= 1;
                if (sub_ready) begin
                    readiness[0] <= 1;
                    if (readiness[1] && readiness[2] && ~stopped)
                        next <= 1;
                end
                if (mult_ready) begin
                    readiness[1] <= 1;
                    if (readiness[0] && readiness[2] && ~stopped)
                        next <= 1;
                end
                if (add_ready) begin
                    readiness[2] <= 1;
                    if (readiness[0] && readiness[1] && ~stopped)
                        next <= 1;
                    if ((~stopped) && (countFromStart > 2'd2)) begin
                        ready <= 1;
                        sum <= sum_pipe;
                        Y <= sum_pipe;
                    end
                    else if ((stopped) && (countFromStop < 2'd2)) begin
                        ready <= 1;
                        sum <= sum_pipe;
                        Y <= sum_pipe;
                    end
                end
                else
                    ready <= 0;
            end
        end
    end
endmodule
