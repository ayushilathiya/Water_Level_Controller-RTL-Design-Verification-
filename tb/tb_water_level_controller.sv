// =============================================================
// Testbench   : water_level_controller_tb
// Description : Self-checking testbench for water_level_controller.
//               Exercises the full fill/drain cycle, hysteresis
//               behavior, and asynchronous reset, with automatic
//               pass/fail checks on the motor_on output.
// =============================================================
`timescale 1ns/1ps

module water_level_controller_tb;

    reg clk;
    reg rst_n;
    reg sensor_low, sensor_mid, sensor_high;
    wire motor_on;
    wire [1:0] state_led;

    integer errors = 0;

    // ---------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------
    water_level_controller dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .sensor_low (sensor_low),
        .sensor_mid (sensor_mid),
        .sensor_high(sensor_high),
        .motor_on   (motor_on),
        .state_led  (state_led)
    );

    // ---------------------------------------------------------
    // Clock generation: 10ns period (100 MHz)
    // ---------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // Task: check motor_on against expected value
    // ---------------------------------------------------------
    task check_motor(input expected, input [127:0] label);
        begin
            if (motor_on !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %s : expected motor_on=%b, got=%b at time=%0t",
                          label, expected, motor_on, $time);
            end else begin
                $display("[PASS] %s : motor_on=%b at time=%0t",
                          label, motor_on, $time);
            end
        end
    endtask

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    initial begin
        // Init
        rst_n       = 1'b1;
        sensor_low  = 1'b0;
        sensor_mid  = 1'b0;
        sensor_high = 1'b0;

        // NOTE: checks are sampled #1 after a posedge so we read
        // settled (post-NBA-update) values, avoiding a clock-edge
        // race between the testbench and the DUT's registered outputs.

        // ---- Test 1: Asynchronous reset ----
        #3  rst_n = 1'b0;   // assert reset mid-cycle (async)
        #7  rst_n = 1'b1;
        @(posedge clk); #1;
        check_motor(1'b1, "After reset, tank empty -> motor should be ON");

        // ---- Test 2: Empty -> Filling ----
        sensor_low = 1'b1;
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b1, "Water passed LOW sensor -> still filling");

        // ---- Test 3: Filling -> Full ----
        sensor_mid  = 1'b1;
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b1, "Water passed MID sensor -> still filling");

        sensor_high = 1'b1;
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b0, "Water reached HIGH sensor -> motor should turn OFF");

        // ---- Test 4: Hysteresis - small drop should NOT restart motor ----
        sensor_high = 1'b0;   // dropped just below HIGH
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b0, "Slight drop below HIGH (still above MID) -> motor stays OFF");

        // ---- Test 5: Drop below MID moves to draining, still OFF ----
        sensor_mid = 1'b0;
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b0, "Dropped below MID -> draining state, motor still OFF");

        // ---- Test 6: Drop below LOW -> motor restarts ----
        sensor_low = 1'b0;
        @(posedge clk); @(posedge clk); #1;
        check_motor(1'b1, "Dropped below LOW -> motor should turn back ON");

        // ---- Test 7: Asynchronous reset mid-operation ----
        #2 rst_n = 1'b0;      // async reset asserted between clock edges
        #1 rst_n = 1'b1;
        @(posedge clk); #1;
        check_motor(1'b1, "Async reset mid-fill -> back to EMPTY state, motor ON");

        // ---- Summary ----
        if (errors == 0)
            $display("\n==== ALL TESTS PASSED ====\n");
        else
            $display("\n==== %0d TEST(S) FAILED ====\n", errors);

        $finish;
    end

    // ---------------------------------------------------------
    // Waveform dump (for GTKWave / Vivado simulator)
    // ---------------------------------------------------------
    initial begin
        $dumpfile("water_level_controller_tb.vcd");
        $dumpvars(0, water_level_controller_tb);
    end

endmodule
