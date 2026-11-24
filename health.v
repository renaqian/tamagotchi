// health loss event + medicine-use interaction + death???

/*
	
	sickness is caused by random event:
		use linear feedback shift register to simulate random "sickness" event
	
	while sick: 
		health cannot exceed HEALTH_MAX
		health drops 1 every SICK_DECAY_TICKS ticks until medicine is given
		one-cycle pulse use of medicine (KEY0) cures sickness (ignored when not sick)
		if health is 0 at a c, pet dies
	
*/

`define HEALTH_MAX 9
`define HEALTH_ALERT 5
`define HEALTH_SICK_CHANCE 2
`define HEALTH_SICK_DECAY 5
`define HEALTH_HEAL 3
`define HEALTH_LFSR_SEED 16'hACE1

module health #(
    parameter        MAX_VAL          = `HEALTH_MAX,
    parameter        ALERT_BELOW      = `HEALTH_ALERT,
    parameter        SICK_CHANCE      = `HEALTH_SICK_CHANCE,   // out of 256
    parameter        SICK_DECAY_TICKS = `HEALTH_SICK_DECAY,
    parameter        HEAL_TICKS       = `HEALTH_HEAL,
    parameter [15:0] LFSR_SEED        = `HEALTH_LFSR_SEED
)
(
    input            clk,
    input            resetn,
    input            tick,
    input            run,
    input            medicine,
    output reg       sick,
    output reg [3:0] health,
    output           dead,
    output           health_low,
    output           sick_start
);
    localparam [3:0] MAX4   = MAX_VAL;
    localparam [3:0] ALERT4 = ALERT_BELOW;

	 reg [15:0] lfsr;
    initial lfsr = LFSR_SEED;

    wire lfsr_fb = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];

    always @(posedge clk) begin
        if (lfsr == 16'd0) lfsr <= LFSR_SEED;
        else               lfsr <= {lfsr[14:0], lfsr_fb};
    end

    wire random_hit = (lfsr[7:0] < SICK_CHANCE);

    reg [7:0] cnt;
    reg       sick_d;

    assign dead       = (health == 4'd0);
    assign health_low = (health < ALERT4);
    assign sick_start = sick & ~sick_d;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            sick   <= 1'b0;
            health <= MAX4;
            cnt    <= 8'd0;
            sick_d <= 1'b0;
        end else begin
            sick_d <= sick;

            if (medicine && sick && run) begin
                sick <= 1'b0;
                cnt  <= 8'd0;
            end else if (tick && run && health != 4'd0) begin
                if (sick) begin
                    if (cnt >= SICK_DECAY_TICKS - 1) begin
                        cnt    <= 8'd0;
                        health <= health - 1'b1;
                    end else
                        cnt <= cnt + 1'b1;
                end else begin
                    if (random_hit) begin
                        sick <= 1'b1;
                        cnt  <= 8'd0;
                    end else if (health < MAX4) begin
                        if (cnt >= HEAL_TICKS - 1) begin
                            cnt    <= 8'd0;
                            health <= health + 1'b1;
                        end else
                            cnt <= cnt + 1'b1;
                    end else
                        cnt <= 8'd0;
                end
            end
        end
    end
endmodule