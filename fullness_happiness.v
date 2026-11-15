module fullness_happiness (
    input wire clk, input wire resetn, input wire tick, input wire run,
    input wire sleeping, input wire feed_pulse, input wire play_pulse,
    output reg [3:0] fullness, output reg [3:0] happiness);


    // stat registers, decay counters, update logic

    // declare input/output
    reg [2:0] fullness_clk;
    reg [2:0] happiness_clk;
    wire fullness_decay, happiness_decay;
    reg[3:0] fullness_next, happiness_next;

    // fullness and happiness decay logic (if their timers = 3 or 1 depending on sleeping)
    assign fullness_decay = run && tick && ((!sleeping && fullness_clk >= 3'd3) || (sleeping && fullness_clk >= 3'd1));
    assign happiness_decay = run && tick && (happiness_clk >= 3'd4);

    // update logic always
    always @* begin
        fullness_next = fullness;

        // decay fullness if fullness_decay is true and fullness > 0
        if (fullness_decay && fullness_next > 4'd0)
            fullness_next = fullness - 4'd1;

        // add to fullness (+2) if feed_pulse is true fullness < 9
        if (run && feed_pulse) begin
            if (fullness_next >= 4'd8)
                fullness_next = 4'd9;
            else
                fullness_next = fullness_next + 4'd2;
        end
        
        // decay fullness if play_pulse is true and fullness > 0
        else if (run && play_pulse) begin
            if (fullness_next > 4'd0)
                fullness_next = fullness_next - 4'd1;
        end

        happiness_next = happiness;

        // decay happiness if happiness decay is true and happiness > 0
        if (happiness_decay && happiness_next > 4'd0)
            happiness_next = happiness - 4'd1;

        // add to happiness (+2) if play_pulse is true and happiness < 9
        if (run && play_pulse && !feed_pulse) begin
            if (happiness_next >= 4'd8)
                happiness_next = 4'd9;
            else
                happiness_next = happiness_next + 4'd2;
        end
    end

    // only at clk edge, or at reset
    always @(posedge clk or negedge resetn) begin
        // if they press resetn then it should restart theg ame
        if (!resetn) begin
            fullness <= 4'd9;
            happiness <= 4'd9;
            fullness_clk <= 3'd0;
            happiness_clk <= 3'd0;
        end else begin
            fullness <= fullness_next;
            happiness <= happiness_next;

            if (run && tick) begin
                // resetting happiness_clk or incrementing
                if (happiness_decay)
                    happiness_clk <= 3'd0;
                else
                    happiness_clk <= happiness_clk + 3'd1;

                // resetting fullness_clk or incrementing
                if (fullness_decay)
                    fullness_clk <= 3'd0;
                else
                    fullness_clk <= fullness_clk + 3'd1;
            end
        end
    end


endmodule