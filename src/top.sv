module arty_top
	(
		input logic [3:0] sw,
		output logic [15:0] led
	);

	always_comb begin
		{led[12], led[8], led[4], led[0]} = sw;
	end

endmodule
