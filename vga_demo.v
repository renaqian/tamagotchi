`default_nettype none

/*  Shows the Tamagotchi picture on the VGA display.
 *
 *  This is the display_mif demo with one change: the vga_adapter's video memory is
 *  loaded from ./MIF/tamagotchi_640_9.mif instead of the default rainbow image.
 *  The picture is stored in the FPGA when you program the board, so nothing has to be drawn.
 *  Press KEY[0] to reset the VGA controller if the screen is blank after programming.
*/
module vga_demo(CLOCK_50, KEY, LEDR, VGA_R, VGA_G, VGA_B,
                VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = 10;
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = 9;

    input wire CLOCK_50;
    input wire [3:0] KEY;
    output wire [9:0] LEDR;
    output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    // Nothing is drawn on top of the background, so the write port is tied off.
    wire [8:0] color;
    wire [nX-1:0] X;
    wire [nY-1:0] Y;
    wire write;

    assign color = 0;
    assign X = 0;
    assign Y = 0;
    assign write = 0;
    assign LEDR = 10'b0;

    // instantiate the VGA adapter
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .color(color),
        .x(X),
        .y(Y),
        .write(write),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));

    // 640x480, 9-bit colour picture used as the initial contents of the video memory
    defparam VGA.BACKGROUND_IMAGE = "./MIF/tamagotchi_640_9.mif";

endmodule
