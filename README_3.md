# DLCD Level-2, Problem 2
## 4-Bit Counter FSM with Run/Hold Control and 7-Segment Output

**Team:** <Member 1>, <Member 2>, <Member 3>, <Member 4>
**Section / Instructor:** <fill in>

---

## 1. Overview

A 4-bit counter controlled by a 2-state Moore FSM (`RUN` / `HOLD`), with the count shown on a common-cathode 7-segment display (hex digits 0 to F).

- `run = 1`: FSM is in RUN, count increases by 1 each clock edge and wraps from `1111` to `0000`.
- `run = 0`: FSM is in HOLD, count keeps its value.
- `seg` is generated combinationally from `count`.

### Interface

| Signal      | Dir    | Width | Description                                         |
|-------------|--------|-------|-----------------------------------------------------|
| `clk`       | input  | 1     | Clock, rising-edge triggered                        |
| `reset`     | input  | 1     | Synchronous, active high (clears count, goes to HOLD) |
| `run`       | input  | 1     | 1 = count, 0 = hold                                 |
| `count`     | output | 4     | Current counter value                               |
| `seg`       | output | 7     | `{g,f,e,d,c,b,a}`, common cathode, active high      |

---

## 2. Files

| File           | Purpose                                                   |
|----------------|-----------------------------------------------------------|
| `design.v`     | `counter_fsm` (top) and `seg7_decoder` modules            |
| `testbench.v`  | Self-checking testbench `tb_counter_fsm`                  |
| `README.md`    | This document                                             |

---

## 3. Task 1: State Diagram

State encoding: `HOLD = 0`, `RUN = 1`.

```
                run = 0                          run = 1
               +-------+                        +-------+
               |       v                        |       v
               |   +--------+   run = 1    +--------+   |
               +---|  HOLD  |------------->|  RUN   |---+
                   |        |<-------------|        |
                   +--------+   run = 0    +--------+
                       ^
                       | reset (any state)
```

| Current state | Condition | Next state |
|---------------|-----------|------------|
| HOLD          | run = 0   | HOLD (self-loop) |
| HOLD          | run = 1   | RUN        |
| RUN           | run = 1   | RUN (self-loop)  |
| RUN           | run = 0   | HOLD       |

Next-state equation: `next_state = run`.

---

## 4. Task 2: Next-Count Logic and MUX

| State | Next count          |
|-------|---------------------|
| RUN   | `count + 1` (mod 16) |
| HOLD  | `count`             |

A 2-to-1 MUX picks between `count + 1` and `count`, with the FSM state as the select line. Its output feeds the D inputs of the four flip-flops.

```
              +-----------+
 count ------>| 0         |
              |    MUX    |--- next_count[3:0] ---> D inputs of 4 FFs ---> count[3:0]
 count + 1 -->| 1  2:1    |                                 ^   |
              +-----------+                                 |   |
                    ^ select = state (RUN=1)                clk |
                    |                                           |
                  state                    count fed back ------+
```

The adder is 4 bits wide, so `1111 + 1` drops the carry and wraps to `0000`.

---

## 5. Task 3: 7-Segment Decoder

Segment layout:

```
     a
    ---
 f |   | b
    -g-
 e |   | c
    ---
     d
```

Bit order `seg[6:0] = {g,f,e,d,c,b,a}`, active high (1 = segment ON).

| Hex | count | g f e d c b a | seg (hex) |
|-----|-------|---------------|-----------|
| 0   | 0000  | 0 1 1 1 1 1 1 | 3F |
| 1   | 0001  | 0 0 0 0 1 1 0 | 06 |
| 2   | 0010  | 1 0 1 1 0 1 1 | 5B |
| 3   | 0011  | 1 0 0 1 1 1 1 | 4F |
| 4   | 0100  | 1 1 0 0 1 1 0 | 66 |
| 5   | 0101  | 1 1 0 1 1 0 1 | 6D |
| 6   | 0110  | 1 1 1 1 1 0 1 | 7D |
| 7   | 0111  | 0 0 0 0 1 1 1 | 07 |
| 8   | 1000  | 1 1 1 1 1 1 1 | 7F |
| 9   | 1001  | 1 1 0 1 1 1 1 | 6F |
| A   | 1010  | 1 1 1 0 1 1 1 | 77 |
| b   | 1011  | 1 1 1 1 1 0 0 | 7C |
| C   | 1100  | 0 1 1 1 0 0 1 | 39 |
| d   | 1101  | 1 0 1 1 1 1 0 | 5E |
| E   | 1110  | 1 1 1 1 0 0 1 | 79 |
| F   | 1111  | 1 1 1 0 0 0 1 | 71 |

---

## 6. Task 4: Verilog Implementation

`design.v` contains two modules:

- **`counter_fsm`**: 1-bit state register (HOLD/RUN), the 2:1 MUX for next count, the 4-bit count register, and an instance of the decoder.
- **`seg7_decoder`**: combinational `case` on `count`, one row per hex digit.

Key lines:

```verilog
assign next_state = run ? RUN : HOLD;                         // FSM
assign next_count = (state == RUN) ? (count + 4'd1) : count;  // MUX
```

### Testbench

`testbench.v` generates a 10 ns clock and drives this sequence:

1. Reset
2. RUN for 6 clocks (count increases)
3. HOLD for 5 clocks (count frozen)
4. RUN for 20 clocks (passes `1111` and wraps to `0000`)
5. HOLD for 3 clocks
6. Reset in the middle of operation, then a few clocks

It checks automatically that:

- count increases by 1 while in RUN
- count holds while in HOLD
- count wraps from `1111` to `0000`
- reset clears count
- `seg` matches the expected pattern for every count value

It prints a pass/fail summary at the end.

---

## 7. How to Run

**EDA Playground (easiest):**
1. Open edaplayground.com and log in.
2. Paste `design.v` in the right pane and `testbench.v` in the left pane.
3. Simulator: **Icarus Verilog**. Tick **Open EPWave after run**.
4. Click **Run**.

**Local Icarus Verilog:**
```bash
iverilog -o sim design.v testbench.v
vvp sim
gtkwave dump.vcd
```

A passing run ends with `RESULT: ALL TESTS PASSED`.

---

## 8. Simulation Output

_Paste the console log here after running._

```
<console output>
```

_Insert the waveform screenshot here (clk, reset, run, state, count, seg)._

---

## 9. Design Notes

- **Moore FSM:** the state is registered, so the counter reacts one clock **after** `run` changes. If `run` goes high before an edge, the state becomes RUN at that edge, and the count starts incrementing on the next edge.
- **Synchronous reset:** reset is only sampled on the rising clock edge. It clears `count` to `0000` and puts the FSM in HOLD.
- **Wrap-around:** no special logic is needed. The 4-bit add discards the carry out.
- **Decoder:** purely combinational, so `seg` updates as soon as `count` changes.
