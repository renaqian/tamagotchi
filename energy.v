// energy decay + increase through interactions

// registers: energy, cnt, and sleeping_d

/* 

	if lights off and game running, state = sleep
	sleeping xor sleeping_d (state just changed on last clock edge),
	checks to make sure state changes at every new period
	pulse acts as synchronous clear
	
	period counter: modulo counter with enable
	counts to DECAY_TICKS-1 on cycles where tick is high (enable = tick & run)
	comparator checks whether cnt has reached DECAY_TICKS-1, then lowers energy
	same but with positive REGEN_TICKS when sleep
	
	energy register: 4-bit up/down counter with enable and saturation
	enable is step pulse
	if sleep, change in energy is +
	if !sleep, change in energy is -
	when energy == 0, cant count down anymore, happiness sees immediate decrease
	
	circuit runs each function in this order:
	1. async reset: energy loses ENERGY_DECAY or gains ENERGY_REGEN, count <= 0
	2. check for mode change: count <= 0
	3. tick & run: count increases, energy change if step pulse fires
	
*/ 

`define DECAY_TICKS 3
`define REGEN_TICKS 2
`define ENERGY_DECAY 1
`define ENERGY_REGEN 1
`define ENERGY_MAX 9
`define ENERGY_LOW 3

/*
	
	awake: loses ENERGY_DECAY points every DECAY_TICKS ticks (!SW[0])
	asleep: gains ENERGY_REGEN points every REGEN_TICKS ticks (SW[0])
	run = 0: game over or hasn't started

*/

module energy #(parameter DECAY_TICKS = `DECAY_TICKS,
					 parameter REGEN_TICKS = `REGEN_TICKS, 
					 parameter DECAY_AMT = `ENERGY_DECAY,
					 parameter REGEN_AMT = `ENERGY_REGEN,
					 parameter MAX_VAL = `ENERGY_MAX,
					 parameter LOW_THRESH = `ENERGY_LOW)
(
	input clk,
	input resetn,
	input tick,
	input RUN,
	input SW,
	output reg [3:0] energy,
	output sleeping,
	output energy_low,
	output energy_zero
);
		
	localparam [3:0] MAX4 = MAX_VAL;
	localparam [3:0] DEC4 = DECAY_AMT;
	localparam [3:0] REG4 = REGEN_AMT;
	localparam [3:0] LOW4 = LOW_THRESH;
	
	reg [7:0] cnt;
	reg sleeping_d;
	
	assign sleeping = SW & RUN;
	assign energy_low = (energy < 4'd4);
	assign energy_zero = (energy == 4'd0);
	
	wire [4:0] up_sum = {1'b0, energy} + {1'b0, REG4};
	wire [3:0] energy_up = (up_sum > {1'b0, MAX4}) ? MAX4 : up_sum[3:0];
	wire [3:0] energy_down = (energy > DEC4) ? (energy - DEC4) : 4'd0;
	
	always @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			energy <= MAX4;
			cnt <= 8'd0;
			sleeping_d <= 1'b0;
		end 
		else begin
			sleeping_d <= sleeping;
			
			if (sleeping != sleeping_d) begin
				cnt <= 8'd0;
			end
			else if (tick & RUN) begin
				if (sleeping) begin
					if (cnt >= REGEN_TICKS - 1) begin
						cnt <= 8'd0;
						energy <= energy_up;
					end else
						cnt <= cnt + 1'b1;
				end else begin
						if (cnt >= DECAY_TICKS - 1) begin
							cnt <= 8'd0;
							energy <= energy_down;
						end else
							cnt <= cnt + 1'b1;
				end 
			end
		end
	end

endmodule 

	