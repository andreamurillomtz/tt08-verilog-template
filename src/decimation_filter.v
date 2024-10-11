/*
 * Copyright (c) 2024 Andrea Murillo Martinez & Jaeden Chang
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule

module tt_um_murmann_group #(
  // Decimation Factor
  parameter OUTPUT_BITS = 16;
  // Decimation Factor
  parameter M = 4;)
  ( input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
  );
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ena,1'b0};

    assign X = ui_in[0];
    
    wire [15:0] decimation_output;  // Output of the decimation filter (Z in decimation_filter module)

    // Enable the all uio pins for output
    assign uio_oe = 8'b11111111;
    
    // Assign most significant 8 bits to the dedicated output pins
    assign uo_out = decimation_output[15:8];

    // Assign less significant 8 bits to the general-purpose IO pins
    assign uio_out = decimation_output[7:0];

    
    decimation_filter my_decimation_filter(.clk(clk),
                                           .reset(~rst_n),
                                           .X(X),
                                           .Z(decimation_output)
                                          );
    
endmodule

module decimation_filter 
  #(parameter OUTPUT_BITS = 16, // Bit-width of output
    parameter M = 4             // Decimation factor
   )(
    input wire clk,             // Clock
    input wire reset,           // Reset
    input wire X,  				// Input data from ADC
    output reg [WIDTH-1:0] Z 	// Decimated output data
  );

    // Integrator stage
  	reg [OUTPUT_BITS-1:0] input_accumulator;
  	reg [OUTPUT_BITS-1:0] Y;

    // Comb stage register
  	reg signed [ OUTPUT_BITS-1:0] comb_1;
    reg signed [OUTPUT_BITS-1:0] comb_2;

    // Decimation counter
    reg [OUTPUT_BITS-1:0] decimation_count;

    always @(posedge clk or posedge reset) begin
      	// Reset everything to zero
        if (reset) begin
            input_accumulator <= 0;
            Y <= 0;
            comb_1 <= 0;
            comb_2 <= 0;
            decimation_count <= 0;
            Z <= 0;
        end else begin
            // Integrator stage (accumulate input samples)
            input_accumulator <= input_accumulator + X;
            Y <= Y + input_accumulator;

            // Decimation control
          	if (decimation_count == M - 1) begin
              	// Comb stage (only every M cycles)
                comb_1 <= Y; 			 // Delay previous Y output
                comb_2 <= comb_1;        // Delay previous comb_1 output

                // Difference between the two delayed comb values
                Z <= comb_1 - comb_2;

                // Reset decimation counter
                decimation_count <= 0;
            end else begin
                // Increment decimation counter
                decimation_count <= decimation_count + 1;
            end
        end
    end
endmodule

