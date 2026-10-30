// Testbench for counter_fsm (DLCD Level-2, Problem 2)
// Checks: count rises while run=1, freezes while run=0,
//         wraps 1111 -> 0000, reset clears it, seg matches count
// PES2UG25CS085 Arnav Yadav

module tb;

reg clk, reset, run;

wire [3:0] count;
wire [6:0] seg;

counter_fsm counter_fsm_0 (clk, reset, run, count, seg);


initial begin
    $dumpfile("tb_counter_fsm.vcd");
    $dumpvars(0, tb);
end


initial clk = 1'b0;
always #5 clk = ~clk;


// -------------------------------------------------------------
// Reference 7-segment patterns. Written out a second time here
// on purpose: checking the decoder against its own table would
// pass even if the table itself were wrong.
// -------------------------------------------------------------
function [6:0] seg_ref;
    input [3:0] h;
    begin
        case (h)
            4'h0:    seg_ref = 7'h3F;
            4'h1:    seg_ref = 7'h06;
            4'h2:    seg_ref = 7'h5B;
            4'h3:    seg_ref = 7'h4F;
            4'h4:    seg_ref = 7'h66;
            4'h5:    seg_ref = 7'h6D;
            4'h6:    seg_ref = 7'h7D;
            4'h7:    seg_ref = 7'h07;
            4'h8:    seg_ref = 7'h7F;
            4'h9:    seg_ref = 7'h6F;
            4'hA:    seg_ref = 7'h77;
            4'hB:    seg_ref = 7'h7C;
            4'hC:    seg_ref = 7'h39;
            4'hD:    seg_ref = 7'h5E;
            4'hE:    seg_ref = 7'h79;
            4'hF:    seg_ref = 7'h71;
            default: seg_ref = 7'h00;
        endcase
    end
endfunction


// -------------------------------------------------------------
// Checker, on the falling edge: half a cycle after the rising
// edge that did the work, so everything has settled. prev_state
// is the FSM state that was in force at that rising edge, which
// is what decides whether count should have moved or held.
// -------------------------------------------------------------
reg [3:0] prev_count;
reg       prev_state;
reg       started;

wire [3:0] expected_inc = prev_count + 4'd1;

integer errors  = 0;
integer inc_ok  = 0;
integer hold_ok = 0;
integer wrap_ok = 0;

initial started = 1'b0;

always @(negedge clk) begin
    $display("Time = %0t | reset = %b | run = %b | state = %s | count = %b (%h) | seg = %b",
             $time, reset, run, (counter_fsm_0.state ? "RUN " : "HOLD"),
             count, count, seg);

    if (reset) begin
        if (count !== 4'b0000) begin
            errors = errors + 1;
            $display("  ERROR: count should be 0000 while reset is high, got %b", count);
        end
        started = 1'b1;
    end
    else if (started) begin
        if (prev_state == 1'b1) begin                   // was in RUN
            if (count !== expected_inc) begin
                errors = errors + 1;
                $display("  ERROR: RUN should have counted to %h, got %h", expected_inc, count);
            end
            else begin
                inc_ok = inc_ok + 1;
                if (prev_count == 4'hF && count == 4'h0) begin
                    wrap_ok = wrap_ok + 1;
                    $display("  PASS: wrapped 1111 -> 0000");
                end
            end
        end
        else begin                                     // was in HOLD
            if (count !== prev_count) begin
                errors = errors + 1;
                $display("  ERROR: HOLD should have kept %h, got %h", prev_count, count);
            end
            else
                hold_ok = hold_ok + 1;
        end
    end

    if (seg !== seg_ref(count)) begin
        errors = errors + 1;
        $display("  ERROR: seg wrong for %h: got %b, expected %b",
                 count, seg, seg_ref(count));
    end

    prev_count = count;
    prev_state = counter_fsm_0.state;
end


// -------------------------------------------------------------
// Stimulus. Inputs move 1 ns after a falling edge so that every
// value they take covers a whole rising edge cleanly.
// -------------------------------------------------------------
initial begin
    reset = 1'b1; run = 1'b0;

    #11 reset = 1'b0; run = 1'b1;
    $display("---- RUN: counting up ----");

    #60 run = 1'b0;
    $display("---- HOLD: count frozen ----");

    #50 run = 1'b1;
    $display("---- RUN: on through the wrap-around ----");

    #200 run = 1'b0;
    $display("---- HOLD ----");

    #30 reset = 1'b1; run = 1'b1;
    $display("---- RESET asserted mid-count ----");

    #10 reset = 1'b0;
    $display("---- RUN: counting up from 0 again ----");

    #30;
    $display("=========================================");
    $display(" Increment checks passed : %0d", inc_ok);
    $display(" Hold checks passed      : %0d", hold_ok);
    $display(" Wrap-arounds seen       : %0d", wrap_ok);
    $display(" Errors                  : %0d", errors);
    if (errors == 0 && inc_ok > 0 && hold_ok > 0 && wrap_ok > 0)
        $display(" RESULT: ALL TESTS PASSED");
    else
        $display(" RESULT: TEST FAILED");
    $display("=========================================");
    $finish;
end

endmodule
