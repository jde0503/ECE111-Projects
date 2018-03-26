`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineers: Joshua Escobar, PID: A11606542
//            Daniel Yeung,   PID: A14195251
// 
// Create Date: 11/19/2017 06:54:19 PM
// Design Name: FIR Filter & SSE
// Project Name: ECE 111 Project 6
// Target Devices: ZYNQ-7 ZC702 Evaluation Board
// Description: Contains module instantiating FIR filter and SSE module
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIR_SSE(
    input logic clk,
    input logic rst,
    input logic stop,
    input logic [31:0] in,
    input logic [31:0] out_gold,
    output logic next,
    output logic ready,
    output logic [31:0] out_filt,
    output logic [31:0] out_sse
    );
    
    // Parameter declaration
    parameter s0 = 1'b0, stopped = 1'b1;
    
    // Internal variables and registers
    logic state;
    logic [31:0] FIR_out;
    logic [31:0] SSE_queue [$];
    logic [31:0] golden_queue [$];
    logic [31:0] FIR_queue [$];
    logic [31:0] SSE_in1, SSE_in2;
    logic SSE_pause;
    logic SSE_stop;
    logic SSE_next;
    logic FIR_ready, SSE_ready;
    
    
    // Instantiate internal modules
    FIR filter(.clk(clk), .rst(rst), .stop(stop), .in(in),
               .next(next), .ready(FIR_ready), .out(FIR_out));
               
    SSE error(.clk(clk), .rst(rst), .pause(SSE_pause), .stop(SSE_stop), .A(SSE_in1),
              .B(SSE_in2), .ready(SSE_ready), .next(SSE_next), .Y(out_sse));
              
    always_ff @ (posedge clk) begin
        if (rst) begin
            SSE_pause <= 1;
            SSE_stop <= 0;
            state <= s0;
        end
        else begin
            case (state)
                s0: begin
                    if (stop)
                        state <= stopped;
                    else begin
                        if (next) begin
                            golden_queue.push_back(out_gold);
                        end
                    
                        if (FIR_ready) begin
                            SSE_queue.push_back(FIR_out);
                            FIR_queue.push_back(FIR_out);
                        end
                        
                        if (SSE_ready) begin
                            out_filt <= FIR_queue.pop_front();
                            ready <= 1;
                        end
                        else
                            ready <= 0;
                        
                        if (SSE_next && SSE_queue.size != 0) begin
                            SSE_pause <= 0;
                            SSE_in1 <= SSE_queue.pop_front();
                            SSE_in2 <= golden_queue.pop_front();
                        end
                        else if (SSE_next && SSE_queue.size == 0) begin
                            SSE_pause <= 1;
                        end
                        
                        state <= s0;
                    end
                end
                
                stopped: begin
                    if (FIR_ready) begin
                        SSE_queue.push_back(FIR_out);
                        FIR_queue.push_back(FIR_out);
                    end
                    
                    if (SSE_ready) begin
                        out_filt <= FIR_queue.pop_front();
                        ready <= 1;
                    end
                    else
                        ready <= 0;
                    
                    if (SSE_next && SSE_queue.size != 0) begin
                        SSE_pause <= 0;
                        SSE_in1 <= SSE_queue.pop_front();
                        SSE_in2 <= golden_queue.pop_front();
                    end
                    else if (SSE_next && SSE_queue.size == 0) begin
                        SSE_stop <= 1;
                    end
                end
            endcase
        end
    end    
endmodule
