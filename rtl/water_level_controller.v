// =============================================================
// Module      : water_level_controller
// Description : RTL-level water level controller for an automatic
//               pump/motor system. Uses three level sensors
//               (low, mid, high) with hysteresis to avoid motor
//               chatter, and an asynchronous active-low reset.
//
// FSM States  :
//   S_EMPTY   - water below LOW sensor          -> motor ON
//   S_FILLING - water between LOW and HIGH      -> motor ON
//   S_FULL    - water at/above HIGH sensor      -> motor OFF
//   S_DRAINING- water dropped below MID (from FULL) but above LOW
//               -> motor stays OFF until LOW is hit (hysteresis)
// =============================================================

module water_level_controller (
    input  wire clk,          // system clock
    input  wire rst_n,        // active-low asynchronous reset
    input  wire sensor_low,   // 1 = water at/above LOW sensor
    input  wire sensor_mid,   // 1 = water at/above MID sensor
    input  wire sensor_high,  // 1 = water at/above HIGH sensor
    output reg  motor_on,     // 1 = pump/motor running (filling)
    output reg [1:0] state_led // debug: current FSM state
);

    // ---------------------------------------------------------
    // FSM state encoding
    // ---------------------------------------------------------
    localparam [1:0] S_EMPTY    = 2'b00,
                      S_FILLING = 2'b01,
                      S_FULL    = 2'b10,
                      S_DRAINING= 2'b11;

    reg [1:0] state, next_state;

    // ---------------------------------------------------------
    // State register (asynchronous active-low reset)
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_EMPTY;
        else
            state <= next_state;
    end

    // ---------------------------------------------------------
    // Next-state logic (combinational)
    // ---------------------------------------------------------
    always @(*) begin
        next_state = state; // default: hold
        case (state)
            S_EMPTY: begin
                if (sensor_low)
                    next_state = S_FILLING;
            end

            S_FILLING: begin
                if (sensor_high)
                    next_state = S_FULL;
            end

            S_FULL: begin
                if (!sensor_mid)          // dropped below MID
                    next_state = S_DRAINING;
            end

            S_DRAINING: begin
                if (!sensor_low)          // dropped below LOW again
                    next_state = S_EMPTY;
                else if (sensor_high)     // refilled externally
                    next_state = S_FULL;
            end

            default: next_state = S_EMPTY;
        endcase
    end

    // ---------------------------------------------------------
    // Output logic (Moore outputs, registered to avoid glitches)
    // ---------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            motor_on  <= 1'b0;
            state_led <= S_EMPTY;
        end else begin
            state_led <= state;
            case (state)
                S_EMPTY:    motor_on <= 1'b1; // must fill
                S_FILLING:  motor_on <= 1'b1; // keep filling
                S_FULL:     motor_on <= 1'b0; // stop
                S_DRAINING: motor_on <= 1'b0; // wait for hysteresis
                default:    motor_on <= 1'b0;
            endcase
        end
    end

endmodule
