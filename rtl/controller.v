// controller.v  –  Member 3  –  Verilog-2005
// FSM: idle → s1 → s2 → s3 → s4 → done → idle
// Each sN state issues one fetch + one data request; done lasts one cycle.
`timescale 1ns/1ps

module controller (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    // request outputs – match harvard_top input ports exactly
    output reg         fetch_enable,
    output reg         data_read_enable,
    output reg         data_write_enable,
    output reg  [4:0]  data_address,
    output reg  [15:0] write_data,
    output reg         done
);

    // -----------------------------------------------------------------
    // State encoding
    // -----------------------------------------------------------------
    localparam [2:0]
        IDLE = 3'd0,
        S1   = 3'd1,   // fetch PC0 + read  word 2  → expect 5
        S2   = 3'd2,   // fetch PC1 + write 10 to word 3
        S3   = 3'd3,   // fetch PC2 + read  word 1  → expect 20
        S4   = 3'd4,   // fetch PC3 + read  word 3  → expect 10
        DONE = 3'd5;

    reg [2:0] state, next_state;

    // -----------------------------------------------------------------
    // State register  (synchronous reset, nonblocking)
    // -----------------------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -----------------------------------------------------------------
    // Next-state logic  (combinational)
    // -----------------------------------------------------------------
    always @(*) begin
        case (state)
            IDLE: next_state = start ? S1   : IDLE;
            S1:   next_state = S2;
            S2:   next_state = S3;
            S3:   next_state = S4;
            S4:   next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------------
    // Output logic  (combinational, fully-specified defaults first)
    // reset suppresses all request outputs regardless of state.
    // -----------------------------------------------------------------
    always @(*) begin
        // Safe defaults
        fetch_enable      = 1'b0;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b0;
        data_address      = 5'd0;
        write_data        = 16'd0;
        done              = 1'b0;

        if (!reset) begin
            case (state)
                S1: begin
                    fetch_enable     = 1'b1;
                    data_read_enable = 1'b1;
                    data_address     = 5'd2;   // read word 2 → 5
                end
                S2: begin
                    fetch_enable      = 1'b1;
                    data_write_enable = 1'b1;
                    data_address      = 5'd3;  // write word 3 ← 10
                    write_data        = 16'd10;
                end
                S3: begin
                    fetch_enable     = 1'b1;
                    data_read_enable = 1'b1;
                    data_address     = 5'd1;   // read word 1 → 20
                end
                S4: begin
                    fetch_enable     = 1'b1;
                    data_read_enable = 1'b1;
                    data_address     = 5'd3;   // read back word 3 → 10
                end
                DONE: begin
                    done = 1'b1;
                end
                default: ; // IDLE and others: defaults already set
            endcase
        end
    end

endmodule