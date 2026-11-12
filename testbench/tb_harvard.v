// tb_harvard.v  –  Member 3  –  Verilog-2005
// Controller-driven Harvard integration testbench.
//
// Timing discipline
//   Drive stimulus at falling edges (mid-period, away from posedge).
//   Sample combinational outputs after a 1 ns settle, BEFORE the
//   committing posedge.
//   Check registered results (PC, stored data) AFTER the posedge + 1 ns.
//
// Self-checking: every mismatch calls $fatal(1,...).
// VCD written to build/harvard.vcd.
`timescale 1ns/1ps

module tb_harvard;

    // ----------------------------------------------------------------
    // Clock  (10 ns period: posedge at t=5,15,25,...)
    // ----------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Signals
    // ----------------------------------------------------------------
    reg  reset;
    reg  start;

    // Controller outputs / Harvard top inputs
    wire        fetch_enable;
    wire        data_read_enable;
    wire        data_write_enable;
    wire [4:0]  data_address;
    wire [15:0] write_data;
    wire        done;

    // Harvard top outputs
    wire [3:0]  pc;
    wire [15:0] instruction;
    wire        instruction_valid;
    wire [15:0] read_data;
    wire        data_valid;

    // ----------------------------------------------------------------
    // Instantiate controller  (named ports)
    // ----------------------------------------------------------------
    controller u_ctrl (
        .clk               (clk),
        .reset             (reset),
        .start             (start),
        .fetch_enable      (fetch_enable),
        .data_read_enable  (data_read_enable),
        .data_write_enable (data_write_enable),
        .data_address      (data_address),
        .write_data        (write_data),
        .done              (done)
    );

    // ----------------------------------------------------------------
    // Instantiate harvard_top  (named ports)
    // ----------------------------------------------------------------
    harvard_top u_top (
        .clk               (clk),
        .reset             (reset),
        .fetch_enable      (fetch_enable),
        .data_read_enable  (data_read_enable),
        .data_write_enable (data_write_enable),
        .data_address      (data_address),
        .write_data        (write_data),
        .pc                (pc),
        .instruction       (instruction),
        .instruction_valid (instruction_valid),
        .read_data         (read_data),
        .data_valid        (data_valid)
    );

    // ----------------------------------------------------------------
    // VCD dump
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("build/harvard.vcd");
        $dumpvars(0, tb_harvard);
    end

    // ----------------------------------------------------------------
    // Timeout watchdog
    // ----------------------------------------------------------------
    initial begin
        #600;
        $fatal(1, "TIMEOUT: simulation exceeded 600 ns – controller may be stuck");
    end

    // ----------------------------------------------------------------
    // Shadow register to track "PC before this edge"
    // ----------------------------------------------------------------
    reg [3:0] pc_before;

    // ----------------------------------------------------------------
    // Main stimulus
    // ----------------------------------------------------------------
    initial begin
        // ============================================================
        // Reset coverage: assert reset for two cycles
        // ============================================================
        reset = 1'b1;
        start = 1'b0;

        @(negedge clk); // t=5 (first negedge)
        // During reset: combinational outputs must be suppressed
        #1;
        if (fetch_enable      !== 1'b0) $fatal(1, "FAIL reset: fetch_enable=%b", fetch_enable);
        if (data_read_enable  !== 1'b0) $fatal(1, "FAIL reset: data_read_enable=%b", data_read_enable);
        if (data_write_enable !== 1'b0) $fatal(1, "FAIL reset: data_write_enable=%b", data_write_enable);
        if (instruction_valid !== 1'b0) $fatal(1, "FAIL reset: instruction_valid=%b", instruction_valid);
        if (data_valid        !== 1'b0) $fatal(1, "FAIL reset: data_valid=%b", data_valid);
        if (done              !== 1'b0) $fatal(1, "FAIL reset: done=%b", done);

        @(posedge clk); // edge 1 – PC latches 0 (already 0)
        @(negedge clk); // t=15
        #1;
        // Still in reset: same checks
        if (fetch_enable      !== 1'b0) $fatal(1, "FAIL reset(2): fetch_enable=%b", fetch_enable);
        if (instruction_valid !== 1'b0) $fatal(1, "FAIL reset(2): instruction_valid=%b", instruction_valid);

        // ============================================================
        // Release reset at a falling edge (away from posedge)
        // ============================================================
        reset = 1'b0;
        start = 1'b0;
        #1;
        // After reset deasserts: still IDLE, no requests
        if (fetch_enable !== 1'b0) $fatal(1, "FAIL idle: fetch_enable should be 0 after reset release");

        @(posedge clk); // edge 2 – first posedge out of reset; IDLE, start=0
        #1;
        if (pc !== 4'd0) $fatal(1, "FAIL post-reset PC: expected 0, got %0d", pc);
        if (fetch_enable !== 1'b0) $fatal(1, "FAIL idle: unexpected fetch_enable");
        if (done         !== 1'b0) $fatal(1, "FAIL idle: unexpected done");

        // ============================================================
        // Pulse start at a falling edge (mid-period)
        // On the next posedge the state machine will transition IDLE→S1
        // ============================================================
        @(negedge clk); // t=25
        start = 1'b1;   // pulse start high for one cycle, away from posedge
        #1;

        // Before the committing edge of S1 arrives, sample combinationals.
        // The controller outputs for S1 are already up (state→S1 on the
        // *next* posedge, so currently still IDLE; outputs come up after
        // that posedge).  We sample per-step AFTER each posedge below.

        // ============================================================
        // Step 1 commit edge:  IDLE→S1
        //   Before edge: PC=0, controller will drive S1 outputs after edge
        // ============================================================
        @(posedge clk); // edge 3 – state transitions IDLE→S1; PC still 0 until this edge
        start = 1'b0;   // deassert start (nonblocking after posedge: safe)
        // After this posedge state=S1, but PC has NOT advanced yet (fetch_enable
        // was 0 in IDLE; instruction_valid was 0 on this edge).
        // PC remains 0. S1 outputs are now combinationally active.
        #1;
        // ----- Sample S1 combinational outputs (settled 1 ns after posedge) -----
        if (pc !== 4'd0)
            $fatal(1, "FAIL S1: PC expected 0, got %0d", pc);
        if (instruction !== 16'h1002)
            $fatal(1, "FAIL S1: instruction expected 1002h, got %04h", instruction);
        if (instruction_valid !== 1'b1)
            $fatal(1, "FAIL S1: instruction_valid expected 1, got %b", instruction_valid);
        if (data_read_enable !== 1'b1)
            $fatal(1, "FAIL S1: data_read_enable expected 1, got %b", data_read_enable);
        if (data_write_enable !== 1'b0)
            $fatal(1, "FAIL S1: data_write_enable expected 0, got %b", data_write_enable);
        if (data_address !== 5'd2)
            $fatal(1, "FAIL S1: data_address expected 2, got %0d", data_address);
        if (data_valid !== 1'b1)
            $fatal(1, "FAIL S1: data_valid expected 1 (read accepted), got %b", data_valid);
        if (read_data !== 16'd5)
            $fatal(1, "FAIL S1: read_data expected 5, got %0d", read_data);

        // ============================================================
        // Step 1 → Step 2 commit edge:  S1→S2
        //   On this posedge: PC advances (0→1), write to word 3 commits
        // ============================================================
        @(posedge clk); // edge 4 – S1→S2; PC 0→1; word-3 write commits (10)
        #1;
        // Post-edge: PC=1 (advanced by S1 fetch), state=S2 outputs active
        if (pc !== 4'd1)
            $fatal(1, "FAIL S2: PC expected 1, got %0d", pc);
        if (instruction !== 16'h2001)
            $fatal(1, "FAIL S2: instruction expected 2001h, got %04h", instruction);
        if (instruction_valid !== 1'b1)
            $fatal(1, "FAIL S2: instruction_valid expected 1, got %b", instruction_valid);
        if (data_write_enable !== 1'b1)
            $fatal(1, "FAIL S2: data_write_enable expected 1, got %b", data_write_enable);
        if (data_read_enable !== 1'b0)
            $fatal(1, "FAIL S2: data_read_enable expected 0 during write, got %b", data_read_enable);
        if (data_address !== 5'd3)
            $fatal(1, "FAIL S2: data_address expected 3, got %0d", data_address);
        if (write_data !== 16'd10)
            $fatal(1, "FAIL S2: write_data expected 10, got %0d", write_data);
        if (data_valid !== 1'b1)
            $fatal(1, "FAIL S2: data_valid expected 1 (write accepted), got %b", data_valid);
        if (read_data !== 16'd0)
            $fatal(1, "FAIL S2: read_data expected 0 during write, got %0d", read_data);

        // ============================================================
        // Step 2 → Step 3 commit edge:  S2→S3
        //   On this posedge: PC advances (1→2)
        // ============================================================
        @(posedge clk); // edge 5 – S2→S3; PC 1→2
        #1;
        if (pc !== 4'd2)
            $fatal(1, "FAIL S3: PC expected 2, got %0d", pc);
        if (instruction !== 16'h3003)
            $fatal(1, "FAIL S3: instruction expected 3003h, got %04h", instruction);
        if (instruction_valid !== 1'b1)
            $fatal(1, "FAIL S3: instruction_valid expected 1, got %b", instruction_valid);
        if (data_read_enable !== 1'b1)
            $fatal(1, "FAIL S3: data_read_enable expected 1, got %b", data_read_enable);
        if (data_write_enable !== 1'b0)
            $fatal(1, "FAIL S3: data_write_enable expected 0, got %b", data_write_enable);
        if (data_address !== 5'd1)
            $fatal(1, "FAIL S3: data_address expected 1, got %0d", data_address);
        if (data_valid !== 1'b1)
            $fatal(1, "FAIL S3: data_valid expected 1 (read accepted), got %b", data_valid);
        if (read_data !== 16'd20)
            $fatal(1, "FAIL S3: read_data expected 20, got %0d", read_data);

        // ============================================================
        // Step 3 → Step 4 commit edge:  S3→S4
        //   On this posedge: PC advances (2→3)
        // ============================================================
        @(posedge clk); // edge 6 – S3→S4; PC 2→3
        #1;
        if (pc !== 4'd3)
            $fatal(1, "FAIL S4: PC expected 3, got %0d", pc);
        if (instruction !== 16'hF000)
            $fatal(1, "FAIL S4: instruction expected F000h, got %04h", instruction);
        if (instruction_valid !== 1'b1)
            $fatal(1, "FAIL S4: instruction_valid expected 1, got %b", instruction_valid);
        if (data_read_enable !== 1'b1)
            $fatal(1, "FAIL S4: data_read_enable expected 1 (readback), got %b", data_read_enable);
        if (data_write_enable !== 1'b0)
            $fatal(1, "FAIL S4: data_write_enable expected 0, got %b", data_write_enable);
        if (data_address !== 5'd3)
            $fatal(1, "FAIL S4: data_address expected 3 (readback), got %0d", data_address);
        if (data_valid !== 1'b1)
            $fatal(1, "FAIL S4: data_valid expected 1 (read accepted), got %b", data_valid);
        if (read_data !== 16'd10)
            $fatal(1, "FAIL S4: read_data expected 10 (written in S2), got %0d", read_data);

        // ============================================================
        // Step 4 → DONE commit edge:  S4→DONE
        //   On this posedge: PC advances (3→4), done asserted for one cycle
        // ============================================================
        @(posedge clk); // edge 7 – S4→DONE; PC 3→4
        #1;
        if (pc !== 4'd4)
            $fatal(1, "FAIL DONE: PC expected 4, got %0d", pc);
        if (done !== 1'b1)
            $fatal(1, "FAIL DONE: done expected 1, got %b", done);
        if (fetch_enable !== 1'b0)
            $fatal(1, "FAIL DONE: fetch_enable should be 0 in done, got %b", fetch_enable);
        if (data_read_enable !== 1'b0)
            $fatal(1, "FAIL DONE: data_read_enable should be 0 in done, got %b", data_read_enable);
        if (data_write_enable !== 1'b0)
            $fatal(1, "FAIL DONE: data_write_enable should be 0 in done, got %b", data_write_enable);

        // ============================================================
        // DONE → IDLE commit edge:  done lasts exactly one cycle
        // ============================================================
        @(posedge clk); // edge 8 – DONE→IDLE
        #1;
        if (done !== 1'b0)
            $fatal(1, "FAIL idle: done should be 0 (not sticky), got %b", done);
        if (fetch_enable !== 1'b0)
            $fatal(1, "FAIL idle: fetch_enable should be 0, got %b", fetch_enable);
        // PC holds when idle (no fetch_enable)
        if (pc !== 4'd4)
            $fatal(1, "FAIL idle: PC should hold at 4, got %0d", pc);

        // One more idle cycle to confirm PC holds
        @(posedge clk); // edge 9
        #1;
        if (pc !== 4'd4)
            $fatal(1, "FAIL idle hold: PC should still be 4, got %0d", pc);
        if (done !== 1'b0)
            $fatal(1, "FAIL idle hold: done should be 0, got %b", done);

        // ============================================================
        // All checks passed
        // ============================================================
        $display("PASS: tb_harvard – all Harvard integration checks passed.");
        #10;
        $finish;
    end

endmodule
