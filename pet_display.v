// pet display (320x240, 9-bit colour)

// happy = 1, display happy
// happy = 0, display sad

/*

    pics are stored in on-chip ROMs (loaded from MIF files when board is programmed)
    scan counter (sx, sy) walks over every pixel position,
    one pixel per rising clock edge
    for each position the ROM outputs that pixel's colour
    the whole screen is rewritten every 320 * 240 = 76800 clock cycles (1.5ms at 50MHz)

*/

module pet_display #(
    parameter W = 320,
    parameter H = 240
)

(
    input clk,
    input resetn,
    input happy,
    output reg [8:0] color,
    output reg [8:0] x,
    ouput reg [7:0] y,
    output write
);

    reg [8:0] sx;
    reg [7:0] sy;
    reg sel;

    always @(posedge clk) begin
        if (!resetn) begin
            sx <= 9'd0;
            sy <= 8'd0;
            sel <= happy;

        end else if (sx == W - 1) begin
            sx <= 9'd0;
            if (sy == H - 1) begin
                sy <= 8'd0;
                sel <= happy;
            end else
                sy <= sy + 1'b1;
        end else 
            sx <= sx + 1'b1;
    end

    wire [16:0] addr = {sy, 8'b0} + {sy, 6'b0} + xs;

    reg [8:0] q_happy, q_sad;
    reg [8:0] x1;
    reg [7:0] y1;
    reg sel1;

    always @(posedge clk) begin
        q_happy <= rom_happy[addr];
        q_sad <= rom_sad[addr];
        x1 <= sx;
        y1 <= sy;
        sel1 <= sel;
    end

    always @(posedge clk) begin
        color <= sel1 ? q_happy : q_mad;
        x <= x1;
        y <= y1;
    end

    // write every cycle: the scan rewrites every pixel
    assign write = 1'b1;
endmodule