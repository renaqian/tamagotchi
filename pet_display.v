// pet display (320x240, 9-bit colour)

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

// added mood, sick, sleeping input
(
    input clk,
    input resetn,
    input [1:0] mood,
    input sick,
    input sleeping,
    output reg [8:0] color,
    output reg [8:0] x,
    output reg [7:0] y,
    output write
);

    
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

    // Quartus loads these ROMs from MIF files during compilation.
   // (* ram_init_file = "MIF/happy_80_9.mif" *)
    reg [8:0] rom_happy [0:4799];

    // (* ram_init_file = "MIF/sad_80_9.mif" *)
    reg [8:0] rom_sad [0:4799];

    // (* ram_init_file = "MIF/mad_80_9.mif" *)
    reg [8:0] rom_mad [0:4799];

    // (* ram_init_file = "MIF/sleeping_80_9.mif" *)
    reg [8:0] rom_sleeping [0:4799];

    // (* ram_init_file = "MIF/sick_80_9.mif" *)
    reg [8:0] rom_sick [0:4799];

    // (* ram_init_file = "MIF/sick_sleeping_80_9.mif" *)
    reg [8:0] rom_sick_sleeping [0:4799];

    reg [8:0] sx;
    reg [7:0] sy;
    reg [2:0] selected;

    always @(posedge clk) begin
        if (!resetn) begin
            sx <= 9'd0;
            sy <= 8'd0;
            selected <= HAPPY;

        end else if (sx == W - 1) begin
            sx <= 9'd0;
            if (sy == H - 1) begin
                sy <= 8'd0;
                selected <= appearance;
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

    reg [8:0] pixel;
    reg [8:0] x1;
    reg [7:0] y1;
    reg valid1;
    reg valid2;

    always @(posedge clk) begin
        case (selected)
            HAPPY:         pixel <= rom_happy[addr];
            SAD:           pixel <= rom_sad[addr];
            MAD:           pixel <= rom_mad[addr];
            SLEEPING:      pixel <= rom_sleeping[addr];
            SICK:          pixel <= rom_sick[addr];
            SICK_SLEEPING: pixel <= rom_sick_sleeping[addr];
            default:  pixel <= rom_happy[addr];
        endcase

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