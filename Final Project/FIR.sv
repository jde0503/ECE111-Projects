`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineers: Joshua Escobar, PID: A11606542
//            Daniel Yeung,   PID: A14195251
// 
// Create Date: 11/19/2017 06:54:19 PM
// Design Name: FIR Filter
// Project Name: ECE 111 Project 6
// Target Devices: ZYNQ-7 ZC702 Evaluation Board
// Description: Contains module for implementing band-pass FIR filter
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Macro defination
`define NUM_COEFF 40        // Total number of coefficients before folding
`define HALF_NUM_COEFF 20   // NUM_COEFF/2
`define NUM_LEAVES 20       // Next biggest power of 2 from HALF_NUM_COEFF
                            // If HALf_NUM_COEFF isn't divisible by 2. Otherwise
                            // they're the same


module delayLine(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] in,
    output logic ready,
    output logic [31:0] out [1:`NUM_COEFF]
    );
    
    // Parameter declaration
    parameter s0 = 1'b0, s1 = 1'b1;
    
    // Internal variables and registers
    int i;
    logic state;
    
    always_ff @ (posedge clk) begin
        // rst fills output register with zeros
        if (rst) begin
            for (i = 1; i <= `NUM_COEFF; i = i + 1) begin
                out[i]<= 0;
            end
            ready <= 0;
            state <= s0;
        end
        else begin
            case (state)
                s0: begin
                ready <= 0;
                    if (start) begin 
						for (i = 2; i <= `NUM_COEFF; i = i + 1) begin
							out[i] <= out[i - 1];
						end
						out[1] <= in;
                        state <= s1;
                    end
                    else
						state <= s0;
                end
                
                s1: begin
                    ready <= 1;
                    state <= s0;
                end
                
                default: begin
                    ready <= 0;
                    state <= s0;
                end
            endcase
        end
    end
endmodule


module FIR_Unit(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] coeff,
    input logic [31:0] A,
    input logic [31:0] B,
    output logic ready,
    output logic [31:0] Y
    );
    
    // Internal variables and registers
    logic add_ready,  mult_ready;
    logic [31:0] add_out, mult_out;
    
    // Instantiate internal modules
    adder_fp add(.clk(clk), .start(start), .op(1'b0), .A(A), .B(B),
                  .busy(), .ready(add_ready), .Y(add_out));
    multiplier_fp mult(.clk(clk), .start(add_ready), .A(coeff), .B(add_out),
                        .busy(), .ready(mult_ready), .Y(mult_out));
         
    
    always_ff @ (posedge clk) begin
        // Reset
        if (rst) begin
            ready <= 0;
            Y <= 0;
        end
        
        // Check if starting work on new input
        else if (start) begin
            ready <= 0;
        end
        
        // Check if output is ready.
        // Ready bit stays 1 until next input is given.
        else if (mult_ready) begin
            Y <= mult_out;
            ready <= 1;
        end
    end
endmodule


module addTree(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [31:0] in [1:`HALF_NUM_COEFF],
    output logic ready,
    output logic [31:0] out
    );
    
    // Paramater declaration
    parameter NUM_ADDERS = `NUM_LEAVES >> 1,
              s0 = 2'd0, s1 = 2'd1, s2 = 2'd2, s3 = 2'd3;
    
    // Internal variables and registers
    logic add_start;
    logic [1:NUM_ADDERS] add_ready;
    logic [31:0] pipe_in [1:`NUM_LEAVES];
    logic [31:0] pipe_out [1:NUM_ADDERS];
    logic [1:NUM_ADDERS] readiness;
    logic [1:0] state;
    genvar i;
    int j, k;
    
    // Instantiate internal modules
    generate
        for (i = 1; i <= NUM_ADDERS; i = i + 1) begin: addChain
            adder_fp link(.clk(clk), .start(add_start), .op(1'b0),
                          .A(pipe_in[(2*i) - 1]), .B(pipe_in[2*i]),
                          .ready(add_ready[i]), .busy(), .Y(pipe_out[i]));
        end  
    endgenerate
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            add_start <= 0;
            ready <= 0;
            readiness <= 0;
            for (j = 1; j <= `NUM_LEAVES; j = j + 1) begin
                pipe_in[j] <= 0;
            end
            state <= s0;
        end
        else begin
            case (state)
                s0: begin
                    if (start) begin
                        pipe_in[1:`HALF_NUM_COEFF] <= in[1:`HALF_NUM_COEFF];
                        add_start <= 1;
                        ready <= 0;
                        readiness <= 0;
                        state <= s1;
                    end
                    else
                        state <= s0;
                end
                
                s1: begin
                    add_start <= 0;
                    
                    for (j = 1; j <= NUM_ADDERS; j = j + 1) begin
                        if (add_ready[j])
                            readiness[j] <= 1;
                    end
                    
                    if (&readiness) begin
                        if (pipe_out[2] != 0)
                            state <= s2;
                        else
                            state <= s3;
                    end
                    else
                        state <= s1;
                end
                
                s2: begin
                    pipe_in[1:NUM_ADDERS] <= pipe_out[1:NUM_ADDERS];
                    for (j = (NUM_ADDERS + 1); j <= `NUM_LEAVES; j = j + 1) begin
                        pipe_in[j] <= 0;
                    end
                    add_start <= 1;
                    state <= s1;
                end
                
                s3: begin
                    out <= pipe_out[1];
                    ready <= 1;
                    state <= s0;
                end
                
                default: begin
                    ready <= 0;
                    state <= s0;
                end
            endcase
        end
    end
endmodule


module FIR(
    input logic clk,
    input logic rst,
    input logic stop,
    input logic [31:0] in,
    output logic next,
    output logic ready,
    output logic [31:0] out
    );
    
    // Internal variables and registers
    logic start;
    logic [1:0] countFromStart;
    logic [1:0] countFromStop;
    logic stopped;
    
    genvar i;
    logic delay_ready;
    logic [31:0] delay_out [1:`NUM_COEFF];
    logic [1:`HALF_NUM_COEFF] FIR_ready;
    logic [31:0] FIR_out [1:`HALF_NUM_COEFF];
    logic addTree_ready;
    logic [31:0] coeff [1:`HALF_NUM_COEFF] = 
        '{32'hbc906d51,
        32'hbc7aad59,
        32'h3c8402c0,
        32'hbab3ec1d,
        32'h3c50d808,
        32'h3c8b37b0,
        32'h3b9e9e7c,
        32'h3d079fac,
        32'hbb6dfa01,
        32'h3cd83271,
        32'hbb176a96,
        32'hbc823128,
        32'h3be253ad,
        32'hbd9f3038,
        32'hb8fea3ab,
        32'hbde8ee5c,
        32'hbd7b72fe,
        32'hbd787840,
        32'hbe823a08,
        32'h3f01ab97};
        
    // Instantiate internal modules
    delayLine inputLine(.clk(clk), .rst(rst), .start(start), .in(in),
                        .ready(delay_ready), .out(delay_out));
                        
    generate
        for (i = 1; i <= `HALF_NUM_COEFF; i = i + 1) begin: FIR_Chain
            FIR_Unit link(.clk(clk), .rst(rst), .start(delay_ready),
                          .coeff(coeff[i]), .A(delay_out[(2*i) - 1]),
                          .B(delay_out[2*i]), .ready(FIR_ready[i]),
                          .Y(FIR_out[i]));
        end
    endgenerate
    
    addTree finalSummation(.clk(clk), .rst(rst), .start(start), .in(FIR_out),
                .ready(addTree_ready), .out(out));
    
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            ready <= 0;
            next <= 1;
            start <= 0;
            countFromStart <= 2'd0;
            countFromStop <= 2'd0;
            stopped <= 0;
            out <= 0;
        end
        else begin
            if (stop)
                stopped <= 1;
                
            if ((stop || stopped) && (&FIR_ready) && (addTree_ready)
               && (countFromStop < 2'd1)) begin
                ready <= 0;
                start <= 1;
                countFromStop <= countFromStop + 2'd1;
            end
            
            else if (next && ~stopped) begin
                next <= 0;
                ready <= 0;
                start <= 1;
                if (countFromStart < 2'd2)
                    countFromStart <= countFromStart + 2'd1;
            end
            
            else begin
                if ((&FIR_ready) && (addTree_ready) && (~stopped)) begin
                    next <= 1;
                end
                
                if (addTree_ready) begin
                    if ((~stopped) && (countFromStart > 2'd1)) begin
                        ready <= 1;
                    end
                    else if ((stopped) && (countFromStop < 2'd1)) begin
                        ready <= 1;
                    end
                end
                else
                    ready <= 0;
            end
        end
    end        
endmodule