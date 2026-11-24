// how demanding the pet is in each stage of life

/*

    each need has one number per stage
    fullness, happiness, energy: ticks per point lost (awake):
        smaller = loses stat more frequently (fewer ticks)

    sickness: chance per tick out of 256
        larger = more frequent sickness 

    1 tick = 1 second 
        ex. FULLNESS_BABY 2 means baby loses 1 fullness every 2 seconds 
    asleep: same rule (double rate of loss)

*/

`define NEEDS_FULLNESS_BABY 2
`define NEEDS_FULLNESS_KID 3
`define NEEDS_FULLNESS_ADULT 4
`define NEEDS_FULLNESS_ELDER 6

`define NEEDS_HAPPINESS_BABY 3
`define NEEDS_HAPPINESS_KID 4
`define NEEDS_HAPPINESS_ADULT 5
`define NEEDS_HAPPINESS_ELDER 5

`define NEEDS_ENERGY_BABY 3
`define NEEDS_ENERGY_KID 3
`define NEEDS_ENERGY_ADULT 4
`define NEEDS_ENERGY_ELDER 2

`define NEEDS_SICK_BABY 2
`define NEEDS_SICK_KID 2
`define NEEDS_SICK_ADULT 2
`define NEEDS_SICK_ELDER 6

module stage_needs #(
    parameter FULLNESS_BABY = `NEEDS_FULLNESS_BABY,
    parameter FULLNESS_KID = `NEEDS_FULLNESS_KID,
    parameter FULLNESS_ADULT = `NEEDS_FULLNESS_ADULT,
    parameter FULLNESS_ELDER = `NEEDS_FULLNESS_ELDER,

    parameter HAPPINESS_BABY = `NEEDS_HAPPINESS_BABY,
    parameter HAPPINESS_KID = `NEEDS_HAPPINESS_KID,
    parameter HAPPINESS_ADULT = `NEEDS_HAPPINESS_ADULT,
    parameter HAPPINESS_ELDER = `NEEDS_HAPPINESS_ELDER,
    
    parameter ENERGY_BABY = `NEEDS_ENERGY_BABY,
    parameter ENERGY_KID = `NEEDS_ENERGY_KID,
    parameter ENERGY_ADULT = `NEEDS_ENERGY_ADULT,
    parameter ENERGY_ELDER = `NEEDS_ENERGY_ELDER,
    
    parameter SICK_BABY = `NEEDS_SICK_BABY,
    parameter SICK_KID = `NEEDS_SICK_KID,
    parameter SICK_ADULT = `NEEDS_SICK_ADULT,
    parameter SICK_ELDER = `NEEDS_SICK_ELDER
    
)
(
    input [2:0] stage,
    output [7:0] fullness_ticks,
    output [7:0] happiness_ticks,
    output [7:0] energy_ticks,
    output[7:0] sick_chance 
);

    wire baby = (stage == 3'd1);
    wire kid = (stage == 3'd2);
    wire elder = (stage == 3'd4);

    // leave adult as default (egg/dead stages use adult row but nothing runs)

    assign fullness_ticks = baby ? FULLNESS_BABY : kid ? FULLNESS_KID : elder ? FULLNESS_ELDER : FULLNESS_ADULT;
    assign happiness_ticks = baby ? HAPPINESS_BABY : kid ? HAPPINESS_KID : elder ? HAPPINESS_ELDER : HAPPINESS_ADULT;
    assign energy_ticks = baby ? ENERGY_BABY : kid ? ENERGY_KID : elder ? ENERGY_ELDER : ENERGY_ADULT;
    assign sick_chance = baby ? SICK_BABY : kid ? SICK_KID : elder ? SICK_ELDER : SICK_ADULT;

endmodule