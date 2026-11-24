/*

life stage file

egg -> baby -> kid -> adult -> elder -> dead

one number sets the length of the whole game: GAME_SECONDS
the five living stages each last an equal share of it 

    stage length = GAME_SECONDS / 5 (modifiable for testing)

each tick is 1 second. if GAME_SECONDS is not a multiple of 5, remainder is dropped 
pet dies at the end of ELDER (old age) or earlier if dead_in goes high
DEAD stays until reset (KEY0)

alive_run is the "run" signal for every other module, high only while game is switched on (go)
during egg stage and after death, all stats freeze

*/

`define GAME_SECONDS 60

module life_stage #(
    parameter GAME_SECONDS = `GAME_SECONDS

)
(
    input clk,
    input resetn,
    input tick, 
    input go,
    input dead_in,
    output reg[2:0] stage, // goes from 0-5 (3 bits) for each life stage
    output alive_run // if go AND the pet is baby - elder
);

    localparam [2:0] EGG = 3'd0, BABY = 3'd1, KID = 3'd2, ADULT = 3'd3, ELDER = 3'd4, DEAD = 3'd5;

    localparam STAGE_TICKS = GAME_SECONDS / 5;
	 localparam EGG_TICKS = 5;
	 
	 wire [15:0] stage_limit = (stage == EGG) ? EGG_TICKS - 1 : STAGE_TICKS - 1;

    reg [15:0] timer;

    wire alive = (stage >= BABY) && (stage <= ELDER);
    assign alive_run = go & alive;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            stage <= EGG;
            timer <= 16'd0;
        end else if (stage != DEAD) begin
            if (dead_in && alive) begin
                stage <= DEAD;
            end else if (go && tick) begin 
                if (timer >= stage_limit) begin 
                    timer <= 16'd0;
                    stage <= stage + 1'b1;
                end else
                    timer <= timer + 1'b1;
            end 
        end 
    end 
endmodule 