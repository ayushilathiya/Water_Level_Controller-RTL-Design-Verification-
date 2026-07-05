# Smart Water Level Controller — RTL Design & Verification

## Files
- `water_level_controller.v` — Synthesizable RTL (Verilog). 4-state FSM (EMPTY, FILLING,
  FULL, DRAINING) with sensor-based hysteresis and asynchronous active-low reset.
- `water_level_controller_tb.v` — Self-checking testbench, 8 automated checks covering
  fill cycle, hysteresis, and async reset (mid-operation and at startup).

## How to run (Icarus Verilog — free, ~2 min install)
```bash
# Install (Ubuntu/Debian)
sudo apt-get install iverilog

# Compile and simulate
iverilog -o sim.out water_level_controller.v water_level_controller_tb.v
vvp sim.out

# View waveform (optional, needs GTKWave)
gtkwave water_level_controller_tb.vcd
```

**Verified result:** all 8 self-checks pass (confirmed in this session — see console
output showing `[PASS]` on each check and `==== ALL TESTS PASSED ====`).

## Design notes
- **Hysteresis** is real, not cosmetic: once FULL, the motor stays off until the level
  drops all the way back below the LOW sensor (not just below HIGH), preventing motor
  chatter near the threshold — this is the kind of design decision worth explaining if
  asked about it in an interview.
- **Async reset** is tested at two points: at simulation start, and mid-operation while
  the tank is filling — both confirm the FSM returns cleanly to `S_EMPTY`.
- Outputs are registered (Moore-style) to avoid combinational glitches feeding the motor
  driver.

## What this project does NOT yet claim
This is RTL + verification only — it has not been run through synthesis or
place-and-route, so it is not (yet) a true RTL-to-GDSII flow. If you want to extend it
into one (e.g. via the open-source OpenROAD/OpenLane flow on the SKY130 PDK), that's a
separate, doable next step — ask me when you're ready and I'll set it up.

## Resume bullets that are now fully defensible
Use these in place of the current project bullets:

> **Smart Water Level Controller (RTL Design & Verification)** | Verilog, FSM, Testbench, Icarus Verilog
> - Designed a 4-state FSM in Verilog RTL to control a water pump motor from three level
>   sensors, implementing hysteresis logic to prevent motor chatter near thresholds.
> - Built a self-checking testbench (8 automated assertions) verifying FSM transitions,
>   hysteresis behavior, and asynchronous reset handling at both startup and mid-operation.
> - Simulated and functionally verified the design using Icarus Verilog, confirming
>   correct motor control logic across the full fill/drain cycle.

Every noun in those three lines is now backed by a file you can open, run, and explain.
