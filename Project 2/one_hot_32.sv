`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineer: Joshua Escobar, PID: A11606542
// 
// Create Date: 10/23/2017 01:19:03 PM
// Design Name: 32 bit One Hot Encoder
// Module Name: one_hot_32
// Project Name: ECE 111 Project 2
// Description: Implementation of 32 bit One Hot Encoder
// 
// Dependencies: p_encoder_32_5.sv, decoder_5_32.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module one_hot_32(in, out);

    // Port declarations
    input logic [31:0] in;
    output logic [31:0] out;
    
    // Internal variable declarations
    wire [4:0] encoderOut_decoderIn;
    
    // Module Instantiation
    p_encoder_32_5 pEncoder(in, encoderOut_decoderIn);
    decoder_5_32 decoder(encoderOut_decoderIn, out);
    
endmodule
