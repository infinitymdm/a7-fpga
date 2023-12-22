module top
	(
		input logic [3:0] sw,
		output logic [15:0] led
	);

	assign led[0] = sw[0] & sw[1];
	assign led[4] = sw[2] | sw[3];

endmodule
