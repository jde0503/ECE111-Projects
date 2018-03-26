`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Class: UCSD ECE 111
// Engineer: Joshua Escobar, PID: A11606542
// 
// Create Date: 10/23/2017 01:19:03 PM
// Design Name: 32 bit binary Scientific Notation Converter
// Module Name: scientific
// Project Name: ECE 111 Project 2
// Description: Implementation of 32 bit binary Scientific Notation Converter
// 
// Dependencies: p_encoder_32_5.sv, decoder_5_32.sv, one_hot_32
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module scientific(in, mantissa, exponent);
    
    // Port declarations
    input logic [31:0] in;
    output logic [7:0] mantissa;
    output logic signed [4:0] exponent;
    
    // Internal variable declarations
	reg [31:0] subOut1;
	reg [4:0] subOut2;
    reg [31:0] oneHotCursor;
    reg [4:0] msbIndicator;
    
    // Module instantiations
    one_hot_32 oneHotEncoder(in, subOut1);
    p_encoder_32_5 msb(in, subOut2);
    
    // Computation
    always_comb begin
		oneHotCursor = subOut1;
		msbIndicator = subOut2;
        for (int i = 7; i >= 0; i = i - 1) begin
            if (|oneHotCursor) begin
                mantissa[i] = |(oneHotCursor & in);
                oneHotCursor = oneHotCursor >> 1;

				if (i == 0)
					exponent = msbIndicator - 5'd7;
            end
            else begin
                mantissa = mantissa >> 1;

				if (i == 0)
					exponent = 0;
			end
        end
    end
endmodule