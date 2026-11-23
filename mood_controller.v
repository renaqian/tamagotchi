module mood_controller (input wire clk, input wire resetn, input wire tick, input wire run,
input wire [3:0] energy, input wire [3:0] fullness, input wire [3:0] happiness, output wire [1:0] mood);

    // mood values
    localparam HAPPY = 2'b00;
    localparam SAD = 2'b01;
    localparam MAD = 2'b10;

    // stores current state, next state, and R
    reg [1:0] state;
    reg [1:0] next_state;
    reg [1:0] recovery_count;

    wire all_good;
    wire multiple_low;
    wire recovery_allowed;

    // only all good if all fo them are at least 5
    assign all_good = (energy >= 4'd5) && (fullness >= 4'd5) && (happiness >= 4'd5);

    // checking if any TWO stats are low
    assign multiple_low = ((energy <4'd5) && (fullness < 4'd5)) || ((energy < 4'd5) && (happiness < 4'd5))
        || ((fullness < 4'd5) && (happiness < 4'd5));

    // recovery allowed only if state is SAD or MAD
    assign recovery_allowed = ((state == SAD) && all_good) || ((state == MAD) && !multiple_low);

    // choosing next mood (FSM)
    always @* begin
        next_state = state;

        case (state)
            HAPPY: begin
                if (multiple_low)
                    next_state = MAD;
                else if (!all_good)
                    next_state = SAD;
            end

            SAD: begin
                if (multiple_low)
                    next_state = MAD;
                else if (all_good && tick && recovery_count == 2'd2)
                    next_state = HAPPY;
            end

            MAD: begin
                if (!multiple_low && tick && recovery_count == 2'd2)
                    next_state = SAD;
            end

            default: next_state = HAPPY;
        endcase
    end

    always @(posedge clk or negedge resetn) begin
        // reset
        if (!resetn) begin
            state <= HAPPY;
            recovery_count <= 2'd0;
        // updating state
        end else if (run) begin
            state <= next_state;

            // resetting state counter if state has changed or in happy state
            if (next_state != state)
                recovery_count <= 2'd0;
            else if (!recovery_allowed)
                recovery_count <= 2'd0;
            // otherwise start counting towards changing state
            else if (tick)
                recovery_count <= recovery_count + 2'd1;
        end
    end

    assign mood = state;

endmodule