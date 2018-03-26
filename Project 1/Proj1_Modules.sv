`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: ECE 111
// Engineer: Joshua Escobar, PID: A11606542
// 
// Create Date: 10/16/2017 12:47:59 PM
// Project Name: ECE 111 Project 1
// Module Name: Proj1_Modules
// Description: Includes modules for 8-3 encoder (0), 3-8 decoder (1), and 8-bit
//              adder/subtractor for 2s complement (2)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// 8-3 Encoder Defintion
module encoder_8_3(in, out);
    
    // Port declaration
    input [7:0] in;
    output [2:0] out;
    
    // Internal variable declaration
    reg [2:0] out;
    
    always @ (in)
    begin
        case (in)
            8'b00000001: out = 3'b000;
            8'b00000010: out = 3'b001;
            8'b00000100: out = 3'b010;
            8'b00001000: out = 3'b011;
            8'b00010000: out = 3'b100;
            8'b00100000: out = 3'b101;
            8'b01000000: out = 3'b110;
            8'b10000000: out = 3'b111;
        endcase
    end
endmodule

// 3-8 Decoder Defintion
module decoder_3_8(in, out);

    // Port declaration
    input [2:0] in;
    output [7:0] out;
    
    // Internal variable declaration
    reg [7:0] out;
    
    always @ (in)
    begin
        case (in)
            3'b000: out = 8'b00000001;
            3'b001: out = 8'b00000010;
            3'b010: out = 8'b00000100;
            3'b011: out = 8'b00001000;
            3'b100: out = 8'b00010000;
            3'b101: out = 8'b00100000;
            3'b110: out = 8'b01000000;
            3'b111: out = 8'b10000000;
        endcase
    end
endmodule

// Single CLA Block Defintion
module cla_1(in1, in2, carryIn, g, p, sum);
    
    // Port declarations
    input in1, in2, carryIn;
    output g,p, sum;
    
    // Generate
    assign g = in1 & in2;
    
    // Propagate
    assign p = in1 | in2;
    
    // Sum
    assign sum = ~in1  & ~in2  &  carryIn |
                 ~in1  &  in2  & ~carryIn |
                  in1  & ~in2  & ~carryIn |
                  in1  &  in2  &  carryIn;
endmodule

// 4-bit CLA Block Defintion
module cla_4(in1, in2, carryIn, gOut, pOut, sum);

    // Port declaration
    input [3:0] in1, in2;
    input carryIn;
    output [3:0] sum;
    output gOut, pOut;
    
    // Internal variable declaration
    wire [3:0] carry, p, g;
    
    // Computation
    assign carry[0] = carryIn;
    assign carry[1] = carryIn & p[0]
                    | g[0];
    assign carry[2] = carryIn & p[0] & p[1]
                    | g[0] & p[1] | g[1];
    assign carry[3] = carryIn & p[0] & p[1] & p[2]
                    | g[0] & p[1] & p[2]
                    | g[1] & p[2]
                    | g[2];
 
    assign gOut = g[0] & p[1] & p[2] & p[3]
                | g[1] & p[2] & p[3]
                | g[2] & p[3]
                | g[3];
 
    assign pOut = p[0] & p[1] & p[2] & p[3];
    
    cla_1 subAdder0(in1[0], in2[0], carry[0], g[0], p[0], sum[0]);
    cla_1 subAdder1(in1[1], in2[1], carry[1], g[1], p[1], sum[1]);
    cla_1 subAdder2(in1[2], in2[2], carry[2], g[2], p[2], sum[2]);
    cla_1 subAdder3(in1[3], in2[3], carry[3], g[3], p[3], sum[3]);
endmodule

// 8-bit Adder/Subtractor Defintion
module adder_8(in1, in2, op, out);

    // Port declaration
    input [7:0] in1, in2;
    input op;
    output [7:0] out;
    
    // Internal variable declaration
    wire [1:0] carry, p, g;
    
    // Computation
    assign      carry[0] = op;
 
    assign      carry[1] = g[0];
 
//    assign      carry[2] = g[0] & p[1]
//                         | g[1];
    
    cla_4 subAdder1(in1[3:0], in2[3:0] ^ op, carry[0], g[0], p[0], out[3:0]);
    cla_4 subAdder2(in1[7:4], in2[7:4] ^ op, carry[1], g[1], p[1], out[7:4]);
endmodule

// Top Module Defintion
// Necessary to combine all components of Project 1 in one source file
module Proj1_Modules(encoderInput, decoderInput, adderInput1, adderInput2, adderOp,
                     encoderOutput, decoderOutput, adderOutput);
    
    // Port declaration
    input [7:0] encoderInput, adderInput1, adderInput2;
    input [2:0] decoderInput;
    input adderOp;
    output [7:0] decoderOutput, adderOutput;
    output [2:0] encoderOutput;
    
    // Parameter declaration
    parameter TYPE = 0;
    
    // Conditionally instantiate either the encoder, decoder, or adder
    // depending on TYPE.
    generate
    begin
        if (TYPE == 0)
            encoder_8_3 encoder(encoderInput, encoderOutput);
        else if (TYPE == 1)
            decoder_3_8 decoder(decoderInput, decoderOutput);
        else if (TYPE == 2)
            adder_8 adder(adderInput1, adderInput2, adderOp, adderOutput);
    end
    endgenerate
endmodule