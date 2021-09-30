`timescale 1ns/1ps

module strobe #(
	parameter WIDTH = 1,
	parameter DELAY = 2 // 2 for metastability, larger for testing
	) (
	input clk_in,
	input clk_out,
	input strobe_in,
	output strobe_out,
	input [WIDTH-1:0] data_in,
	output [WIDTH-1:0] data_out
);


`define CLOCK_CROSS
`ifdef CLOCK_CROSS
	reg flag;
	reg [DELAY:0] sync;
	reg [WIDTH-1:0] data;
	reg data_valid_sync;
	reg reg_strobe_out;
	reg [WIDTH-1:0] reg_data_out;

	initial begin
		flag = 0;
		sync[DELAY:0] = 0;
		data[WIDTH-1:0] = 0;
		reg_data_out[WIDTH-1:0] = 0;
		reg_strobe_out = 0; 
		data_valid_sync = 0; 
	end

	// flip the flag and clock in the data when strobe is high
	always @(posedge clk_in) begin
		flag <= flag ^ strobe_in;

		if (strobe_in)
			data <= data_in;

	end

	// shift through a chain of flipflop to ensure stability
	always @(posedge clk_out) begin
		sync <= { sync[DELAY-1:0], flag };
		data_valid_sync <= sync[DELAY] ^ sync[DELAY-1];
		reg_strobe_out <= data_valid_sync;
		if (data_valid_sync)
			reg_data_out <= data;
		
	end
	assign strobe_out = reg_strobe_out;
	assign data_out = reg_data_out;
`else
	assign strobe_out = strobe_in;
	assign data_out = data_in;
`endif
endmodule



module dflip(
	input clk,
	input in,
	output out
);
	reg [2:0] d;
	initial begin
		d[2:0] = 0;
	end
	always @(posedge clk)
		d <= { d[1:0], in };
	assign out = d[2];
endmodule
