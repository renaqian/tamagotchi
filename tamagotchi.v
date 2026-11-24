module tamagotchi (input wire CLOCK_50, input wire [3:0] KEY, input wire [9:0] SW,
    output wire [9:0] LEDR, output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
    output wire [7:0] VGA_R, VGA_G, VGA_B, output wire VGA_HS, VGA_VS, 
    output wire VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    // declare the wires for module
    wire resetn;
    wire tick;
    wire sleeping;
    wire feed_pulse, play_pulse, medicine_pulse;
    wire sick;
    wire [3:0] fullness, happiness, energy;
    wire [1:0] mood;
    wire dead;
    wire [2:0] stage;
    wire alive_run;

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

            if (!sick || (alive_run && medicine_pulse))
            sickness_leds <= 10'b1111111111;
            else if(alive_run && tick)
                sickness_leds <= {1'b0, sickness_leds[9:1]};

            buttons_sync1 <= KEY[3:1];
            buttons_sync2 <= buttons_sync1;
            buttons_previous <= buttons_sync2;

            sleep_sync1 <= SW[0];
            sleep_sync2 <= sleep_sync1;
        end
    end

    // instantiate the modules
    life_stage stages (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .go(SW[9]),
        .dead_in(dead),
        .stage(stage),
        .alive_run(alive_run)
    );

    energy pet_energy (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .RUN(alive_run),
        .SW(sleep_sync2),
        .play_pulse(play_pulse),
        .energy(energy),
        .sleeping(sleeping)
    );

    fullness_happiness needs (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .run(alive_run),
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
        .run(alive_run),
        .medicine(medicine_pulse),
        .sick(sick),
        .health(),
        .dead(dead),
        .health_low(),
        .sick_start()
    );

    // pet mood FSM
    mood_controller pet_mood (
        .clk(CLOCK_50),
        .resetn(resetn),
        .tick(tick),
        .run(alive_run),
        .energy(energy),
        .fullness(fullness),
        .happiness(happiness),
        .mood(mood)
    );

    // Assigning constant hexes
    assign HEX5 = 7'b0000110; // E
    assign HEX3 = 7'b0001110; // F
    assign HEX1 = 7'b0001001; // H

    hex_digit energy_digit (.digit(energy), .segments(HEX4));
    hex_digit fullness_digit (.digit(fullness), .segments(HEX2));
    hex_digit happiness_digit (.digit(happiness), .segments(HEX0));

    // vga demo: display happy picture when happiness >= 5, sad picture otherwise

    wire [8:0] vga_color;
    wire [8:0] vga_x;
    wire [7:0] vga_y;
    wire vga_write;

    // scans two stored pics into VGA adapter (one pixel per rising edge)

    pet_display face (
        .clk(CLOCK_50),
        .resetn(resetn),
        .stage(stage),
        .mood(mood),
        .sick(sick),
        .sleeping(sleeping),
        .color(vga_color),
        .x(vga_x),
        .y(vga_y),
        .write(vga_write)
    );

    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),
        .color(vga_color),
        .x(vga_x),
        .y(vga_y),
        .write(vga_write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));
    
    defparam VGA.RESOLUTION = "320x240";
    defparam VGA.COLOR_DEPTH = 9;
    defparam VGA.BACKGROUND_IMAGE = "./MIF/pet_80_9.mif";
    
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