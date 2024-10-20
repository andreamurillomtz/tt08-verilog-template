/*
 * Copyright (c) 2024 Andrea Murillo Martinez & Jaeden Chang
 * SPDX-License-Identifier: Apache-2.0
 */

module tt_um_murmann_group ( input  wire [7:0] ui_in,    // Dedicated inputs
                            output wire [7:0] uo_out,   // Dedicated outputs
                            input  wire [7:0] uio_in,   // IOs: Input path
                            output wire [7:0] uio_out,  // IOs: Output path
                            output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
                            input  wire       ena,      // will go high when the design is enabled
                            input  wire       clk,      // clock
                            input  wire       rst_n     // reset_n - low to reset
                           );
    
    // List all unused inputs to prevent warnings
    wire _unused = &{ui_in[7:1],ena,1'b0};

    assign X = ui_in[0];

    // Output of the decimation filter (Z in decimation_filter module)
    wire [15:0] decimation_output; 

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
    parameter M = 8             // Decimation factor
   )(
    input wire clk,             // Clock
    input wire reset,           // Reset
    input wire X,  				// Input data from ADC
      output reg [OUTPUT_BITS-1:0] Z 	// Decimated output data
  );

    // Integrator stage register
  	reg [OUTPUT_BITS-1:0] input_accumulator;
  	reg [OUTPUT_BITS-1:0] Y;

    // Comb stage register
  	reg [OUTPUT_BITS-1:0] comb_1;
    reg [OUTPUT_BITS-1:0] comb_2;

    // Decimation counter register
    reg [OUTPUT_BITS-1:0] decimation_count;

    always @(posedge clk or posedge reset) begin
      $display("reset = %b", reset);
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
            $display("X = %b", X);
            input_accumulator <= input_accumulator + X;
            Y <= Y + input_accumulator;
          $display("input_accumulator = %d, Y = %d, decimation_count = %d", input_accumulator, Y,decimation_count);

            // Decimation control
          	if (decimation_count == M - 1) begin
              	// Comb stage (only every M cycles)
              	input_accumulator <= 0;
            	Y <= 0;
                comb_1 <= Y; 			 // Delay previous Y output
                comb_2 <= comb_1;        // Delay previous comb_1 output
              $display("comb_1 = %b, comb_2 = %b", comb_1, comb_2);
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
