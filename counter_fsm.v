// DLCD Level-2, Problem 2
// 4-bit counter FSM with Run/Hold control and 7-segment output
// PES2UG25CS085 Arnav Yadav


// -------------------------------------------------------------
// inc4: 4-bit incrementer, o = i + 1, wrapping 1111 -> 0000
//
// The constant 1 being added is fed in as the carry into bit 0,
// so every stage only ever adds the carry coming from below and
// a half adder is enough. cout is the wrap-around carry.
// -------------------------------------------------------------
module inc4(input wire [3:0] i, output wire [3:0] o, output wire cout);

wire [3:0] c;

ha ha_b0(i[0], 1'b1, o[0], c[0]);
ha ha_b1(i[1], c[0],  o[1], c[1]);
ha ha_b2(i[2], c[1],  o[2], c[2]);
ha ha_b3(i[3], c[2],  o[3], c[3]);

assign cout = c[3];

endmodule


// -------------------------------------------------------------
// dfrl_4: the four count flip-flops.
//
// dfrl already is "2-to-1 MUX feeding a D flip-flop": load picks
// between in (count + 1) and out (the held value), which is
// exactly the next-count MUX asked for in task 2.
// -------------------------------------------------------------
module dfrl_4(
    input wire clk, reset, load,
    input wire [3:0] in,
    output wire [3:0] out
);

dfrl dfrl_f0(clk, reset, load, in[0], out[0]);
dfrl dfrl_f1(clk, reset, load, in[1], out[1]);
dfrl dfrl_f2(clk, reset, load, in[2], out[2]);
dfrl dfrl_f3(clk, reset, load, in[3], out[3]);

endmodule


// -------------------------------------------------------------
// seg7_decoder: hex digit 0-F -> 7-segment pattern (task 3)
// Common cathode, active high, seg[6:0] = {g,f,e,d,c,b,a}
//
//      a
//     ---
//  f |   | b
//     -g-
//  e |   | c
//     ---
//      d
// -------------------------------------------------------------
module seg7_decoder(input wire [3:0] hex, output reg [6:0] seg);

always @(*) begin
    case (hex)                    //  gfedcba      hex
        4'h0:    seg = 7'b0111111;    // 3F
        4'h1:    seg = 7'b0000110;    // 06
        4'h2:    seg = 7'b1011011;    // 5B
        4'h3:    seg = 7'b1001111;    // 4F
        4'h4:    seg = 7'b1100110;    // 66
        4'h5:    seg = 7'b1101101;    // 6D
        4'h6:    seg = 7'b1111101;    // 7D
        4'h7:    seg = 7'b0000111;    // 07
        4'h8:    seg = 7'b1111111;    // 7F
        4'h9:    seg = 7'b1101111;    // 6F
        4'hA:    seg = 7'b1110111;    // 77  (A)
        4'hB:    seg = 7'b1111100;    // 7C  (b)
        4'hC:    seg = 7'b0111001;    // 39  (C)
        4'hD:    seg = 7'b1011110;    // 5E  (d)
        4'hE:    seg = 7'b1111001;    // 79  (E)
        4'hF:    seg = 7'b1110001;    // 71  (F)
        default: seg = 7'b0000000;
    endcase
end

endmodule


// -------------------------------------------------------------
// counter_fsm: the 2-state Moore FSM plus the counter it drives
//
//      run=0                           run=1
//     +-----+                         +-----+
//     |     v                         |     v
//   +--------+       run=1        +--------+
//   |  HOLD  | ------------------>|  RUN   |
//   | state=0|<------------------ | state=1|
//   +--------+       run=0        +--------+
//        ^
//        | reset
//
// state is the whole FSM output: being in RUN enables the load
// on the count register, so the output depends on the state only
// and never directly on run -- i.e. a Moore machine. The cost of
// that is one clock of latency: run going high takes effect on
// the edge after the one that moved the FSM into RUN.
// -------------------------------------------------------------
module counter_fsm(
    input wire clk, reset, run,
    output wire [3:0] count,
    output wire [6:0] seg
);

// state encoding: HOLD = 0, RUN = 1
wire state;
wire next_state;

wire [3:0] next_count;
wire wrap;

// next-state logic: HOLD -> RUN on run=1, RUN -> HOLD on run=0,
// self-loops otherwise, so the next state is just run itself
assign next_state = run;

// state register: one flip-flop, synchronous reset back to HOLD
dfr dfr_state(clk, reset, next_state, state);

// next-count logic
inc4 inc4_0(count, next_count, wrap);

// four count flip-flops, MUXed between next_count and count by
// the FSM output, cleared synchronously by reset
dfrl_4 dfrl_4_0(clk, reset, state, next_count, count);

// combinational 7-segment decoder on the current count
seg7_decoder seg7_decoder_0(count, seg);

endmodule
