// pet display (320x240, 9-bit colour)

/*

    pics are stored in on-chip ROMs (loaded from MIF files when board is programmed)
    scan counter (sx, sy) walks over every pixel position,
    one pixel per rising clock edge
    for each position the ROM outputs that pixel's colour
    the whole screen is rewritten every 320 * 240 = 76800 clock cycles (1.5ms at 50MHz)

    picture displayed depends on life stage and appearance (mood, sick, sleeping)

    pictures are oredered in the ROM:
        - 0: egg 
        - 1: dead 
        - 2-7: baby: happy, sad, mad, sleeping, sick, sick+sleeping 
        - 8-13: kid (same 6)
        - 14-19: adult (same 6)
        - 20-25: elder (same 6)

*/

module pet_display #(
    parameter W = 320,
    parameter H = 240
)

// added life stage, mood, sick, sleeping input
(
    input clk,
    input resetn,
    input [2:0] stage,
    input [1:0] mood,
    input sick,
    input sleeping,
    output reg [8:0] color,
    output reg [8:0] x,
    output reg [7:0] y,
    output write
);

    // life stages (same numbers as life_stage.v)
    localparam EGG   = 3'd0;
    localparam BABY  = 3'd1;
    localparam KID   = 3'd2;
    localparam ADULT = 3'd3;
    localparam ELDER = 3'd4;
    localparam DEAD  = 3'd5;

    // parameters for mood FSM / events
    localparam HAPPY    = 3'd0;
    localparam SAD      = 3'd1;
    localparam MAD      = 3'd2;
    localparam SLEEPING = 3'd3;
    localparam SICK     = 3'd4;
    localparam SICK_SLEEPING = 3'd5;

    reg [2:0] appearance;

    // changing images based on mood FSM. sick + sleeping -> sick -> sleeping -> mood
    always @* begin
        // sick and sleeping
        if (sick && sleeping)
            appearance = SICK_SLEEPING;
        // else sick
        else if (sick)
            appearance = SICK;
        // else sleeping
        else if (sleeping)
            appearance = SLEEPING;
        else begin
            // cases for mood
            case (mood)
                2'b00: appearance = HAPPY;
                2'b01: appearance = SAD;
                2'b10: appearance = MAD;
                default: appearance = HAPPY;
            endcase
        end
    end

    // rena add the images pls each image should be 80x60 and u can change the filenames or wtv

    reg [4:0] picture;

    always @* begin
        case (stage)
            EGG: picture = 5'd0;
            BABY: picture = 5'd2;
            KID: picture = 5'd8 + appearance;
            ADULT: picture = 5'd14 + appearance;
            ELDER: picture = 5'd20 + appearance;
            default: picture = 5'd1;
        endcase 
    end

    // 80x60 pixels per picture, 26 pictures
    // Quartus loads these ROMs from MIF files during compilation.

    localparam NUM_PICS = 26;
    localparam [12:0] IMG_SIZE = 13'd4800; // 80*60

    (* ram_init_file = "MIF/pet_80_9.mif" *)

    reg [8:0] rom [0:NUM_PICS*4800-1];

    reg [8:0] sx;
    reg [7:0] sy;
    reg [4:0] selected; // pic num for this frame

    always @(posedge clk) begin
        if (!resetn) begin
            sx <= 9'd0;
            sy <= 8'd0;
            selected <= 5'd0;

        end else if (sx == W - 1) begin
            sx <= 9'd0;
            if (sy == H - 1) begin
                sy <= 8'd0;
                selected <= picture;
            end else
                sy <= sy + 1'b1;
        end else 
            sx <= sx + 1'b1;
    end

     // Dropping two low bits divides each coordinate by four.
    // Each source pixel becomes a 4x4 block on screen.
    wire [6:0] image_x;
    wire [5:0] image_y;
    wire [12:0] addr;

    assign image_x = sx[8:2];
    assign image_y = sy[7:2];

    // Address = image_y * 80 + image_x.
    // 80 = 64 + 16.
    assign addr = {1'b0, image_y, 6'b0} +
                  {3'b0, image_y, 4'b0} +
                  {6'b0, image_x};

    wire [16:0] rom_addr = selected * IMG_SIZE + addr;

    reg [8:0] pixel;
    reg [8:0] x1;
    reg [7:0] y1;
    reg valid1;
    reg valid2;

    always @(posedge clk) begin
        pixel <= rom[rom_addr];

        x1 <= sx;
        y1 <= sy;

        if (!resetn)
            valid1 <= 1'b0;
        else
            valid1 <= 1'b1;
    end

    // show the pixel + coords
    always @(posedge clk) begin
        color <= pixel;
        x <= x1;
        y <= y1;

        if (!resetn)
            valid2 <= 1'b0;
        else
            valid2 <= valid1;

    end

    // write every cycle: the scan rewrites every pixel
    assign write = resetn && valid2;
endmodule