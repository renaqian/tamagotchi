module tamagotchi (input wire CLOCK_50, input wire [3:0] KEY, input wire [9:0] SW,
    output wire [9:0] LEDR, output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

    // declare the wires for module
    wire resetn;
    wire tick;
    wire sleeping;
    wire feed_pulse, play_pulse, medicine_pulse;
    wire sick;
    wire [3:0] fullness, happiness, energy;

    reg [25:0] tick_count;
    reg [2:0] buttons_sync1, buttons_sync2;
    reg [2:0] buttons_previous;
    reg sleep_sync1;
    reg sleep_sync2;

    reg [9:0] sickness_leds;
    assign LEDR = sickness_leds;

    // KEY0 resets the whole game. actie low buttons
    assign resetn = KEY[0];

    // One tick per sec from 50 MHz clock
    assign tick = (tick_count == 26'd49_999_999);

    // KEY1 feeds, KEY2 plays, KEY3 gives medicine (flipflops of KEYS 0-3)
    assign feed_pulse = !sleeping && buttons_previous[0] && !buttons_sync2[0];
    assign play_pulse = !sleeping && buttons_previous[1] && !buttons_sync2[1] && !feed_pulse;
    assign medicine_pulse = buttons_previous[2] && !buttons_sync2[2];

    // clock
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            tick_count <= 26'd0;
            buttons_sync1 <= 3'b111;
            buttons_sync2 <= 3'b111;
            buttons_previous <= 3'b111;
            sleep_sync1 <= 1'b0;
            sleep_sync2 <= 1'b0;
            sickness_leds <= 10'b1111111111;

        end else begin
            if (tick)
                tick_count <= 26'd0;
            else
                tick_count <= tick_count + 26'd1;

            if (!sick || (SW[9] && medicine_pulse))
            sickness_leds <= 10'b1111111111;
            else if(SW[9] && tick)
                sickness_leds <= {1'b0, sickness_leds[9:1]};

            buttons_sync1 <= KEY[3:1];
            buttons_sync2 <= buttons_sync1;
            buttons_previous <= buttons_sync2;

            sleep_sync1 <= SW[0];
            sleep_sync2 <= sleep_sync1;
        end
    end

    // instantiate the modules
    energy pet_energy (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .RUN(SW[9]),
        .SW(sleep_sync2),
        .play_pulse(play_pulse),
        .energy(energy),
        .sleeping(sleeping)
    );

    fullness_happiness needs (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .run(SW[9]),
        .sleeping(sleeping),
        .feed_pulse(feed_pulse),
        .play_pulse(play_pulse),
        .fullness(fullness),
        .happiness(happiness)
    );

    health sickness_test (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .run(SW[9]),
        .medicine(medicine_pulse),
        .sick(sick),
        .health(),
        .dead(),
        .health_low(),
        .sick_start()
    );

    // Assigning constant hexes
    assign HEX5 = 7'b0000110; // E
    assign HEX3 = 7'b0001110; // F
    assign HEX1 = 7'b0001001; // H

    hex_digit energy_digit (.digit(energy), .segments(HEX4));
    hex_digit fullness_digit (.digit(fullness), .segments(HEX2));
    hex_digit happiness_digit (.digit(happiness), .segments(HEX0));
endmodule

module hex_digit (input wire [3:0] digit, output reg [6:0] segments);

	// assigning number values (hardcoded cases)
	always @* begin
		case (digit)
			4'd0: segments = 7'b1000000;
			4'd1: segments = 7'b1111001;
			4'd2: segments = 7'b0100100;
			4'd3: segments = 7'b0110000;
			4'd4: segments = 7'b0011001;
			4'd5: segments = 7'b0010010;
			4'd6: segments = 7'b0000010;
			4'd7: segments = 7'b1111000;
			4'd8: segments = 7'b0000000;
			4'd9: segments = 7'b0010000;
			default: segments = 7'b1111111;
		endcase
	end
endmodule