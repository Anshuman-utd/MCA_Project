`timescale 1ns/1ps

// tb_harvard_directed.v  –  Member 5  –  Verilog-2005
// Direct Harvard edge-case and isolation tests.
// Instantiates harvard_top directly and drives requests without controller.
//
// Test coverage:
//   1. Fetch-only cycle at PC 0 (advances PC to 1).
//   2. Data-only access at the same numerical address (write 42 to RAM word 1,
//      verify ROM word 1 stays intact, read back 42 from RAM word 1).
//   3. Rejected data request during fetch (write 99 to invalid address 17;
//      fetch proceeds to PC 2, write rejected, RAM word 1 unchanged).
//   4. Reset with both paths requesting access (fetch + write 123 to word 1;
//      valides suppressed, PC resets to 0, RAM word 1 survives intact as 42).

module tb_harvard_directed;

    // ----------------------------------------------------------------
    // Clock (10 ns period: posedge at t=5, 15, 25, ...)
    // ----------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------------
    // Request inputs
    // ----------------------------------------------------------------
    reg        reset;
    reg        fetch_enable;
    reg        data_read_enable;
    reg        data_write_enable;
    reg  [4:0] data_address;
    reg [15:0] write_data;

    // ----------------------------------------------------------------
    // DUT outputs
    // ----------------------------------------------------------------
    wire  [3:0] pc;
    wire [15:0] instruction;
    wire        instruction_valid;
    wire [15:0] read_data;
    wire        data_valid;

    // ----------------------------------------------------------------
    // Instantiate harvard_top directly with named ports
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
    // VCD waveform dump
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("build/harvard_directed.vcd");
        $dumpvars(0, tb_harvard_directed);
    end

    // ----------------------------------------------------------------
    // Timeout watchdog
    // ----------------------------------------------------------------
    initial begin
        #500;
        $fatal(1, "TIMEOUT: simulation exceeded 500 ns");
    end

    // ----------------------------------------------------------------
    // Main test stimulus
    // ----------------------------------------------------------------
    initial begin
        // ============================================================
        // Case 0: Reset cycle
        // ============================================================
        reset             = 1'b1;
        fetch_enable      = 1'b0;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b0;
        data_address      = 5'd0;
        write_data        = 16'd0;

        @(negedge clk);
        #1;
        if (instruction_valid !== 1'b0) $fatal(1, "FAIL Case 0 (reset): expected instruction_valid=0, got %b", instruction_valid);
        if (data_valid        !== 1'b0) $fatal(1, "FAIL Case 0 (reset): expected data_valid=0, got %b", data_valid);
        if (read_data         !== 16'd0) $fatal(1, "FAIL Case 0 (reset): expected read_data=0, got %h", read_data);

        @(posedge clk); // Reset edge – PC latches 0
        #1;
        if (pc !== 4'd0) $fatal(1, "FAIL Case 0 (reset): expected PC=0, got %0d", pc);

        // Deassert reset at falling edge
        @(negedge clk);
        reset = 1'b0;

        // ============================================================
        // Case 1: Fetch only at PC 0
        //   With PC at 0 and both data enables low, assert fetch.
        //   Before edge: instruction 16'h1002, instruction_valid=1,
        //   data_valid=0, read_data=0.
        //   After edge: PC advances to 1.
        // ============================================================
        fetch_enable      = 1'b1;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b0;
        data_address      = 5'd0;
        write_data        = 16'd0;

        #1;
        if (pc                !== 4'd0)     $fatal(1, "FAIL Case 1: expected PC=0, got %0d", pc);
        if (instruction       !== 16'h1002) $fatal(1, "FAIL Case 1: expected instruction=16'h1002, got %h", instruction);
        if (instruction_valid !== 1'b1)     $fatal(1, "FAIL Case 1: expected instruction_valid=1, got %b", instruction_valid);
        if (data_valid        !== 1'b0)     $fatal(1, "FAIL Case 1: expected data_valid=0, got %b", data_valid);
        if (read_data         !== 16'h0000) $fatal(1, "FAIL Case 1: expected read_data=0, got %h", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd1) $fatal(1, "FAIL Case 1: expected PC=1 after fetch, got %0d", pc);

        // ============================================================
        // Case 2: Data-only access at the same numerical address
        //   Disable fetch. With PC held at 1, write decimal 42 to RAM word 1.
        //   Before edge: ROM[1]=16'h2001, instruction_valid=0, data_valid=1, read_data=0.
        //   After edge: PC stays 1, ROM[1] remains 16'h2001.
        //   Then read back RAM word 1 -> returns 42.
        // ============================================================
        @(negedge clk);
        fetch_enable      = 1'b0;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b1;
        data_address      = 5'd1;
        write_data        = 16'd42;

        #1;
        if (pc                !== 4'd1)     $fatal(1, "FAIL Case 2 (write): expected PC=1, got %0d", pc);
        if (instruction       !== 16'h2001) $fatal(1, "FAIL Case 2 (write): expected ROM[1]=16'h2001, got %h", instruction);
        if (instruction_valid !== 1'b0)     $fatal(1, "FAIL Case 2 (write): expected instruction_valid=0, got %b", instruction_valid);
        if (data_valid        !== 1'b1)     $fatal(1, "FAIL Case 2 (write): expected data_valid=1, got %b", data_valid);
        if (read_data         !== 16'h0000) $fatal(1, "FAIL Case 2 (write): expected read_data=0 during write, got %h", read_data);

        @(posedge clk);
        #1;
        if (pc                !== 4'd1)     $fatal(1, "FAIL Case 2 (after write edge): expected PC=1, got %0d", pc);
        if (instruction       !== 16'h2001) $fatal(1, "FAIL Case 2 (after write edge): expected ROM[1]=16'h2001, got %h", instruction);
        if (instruction_valid !== 1'b0)     $fatal(1, "FAIL Case 2 (after write edge): expected instruction_valid=0, got %b", instruction_valid);

        // Read RAM word 1 back
        @(negedge clk);
        data_write_enable = 1'b0;
        data_read_enable  = 1'b1;
        data_address      = 5'd1;

        #1;
        if (pc                !== 4'd1)     $fatal(1, "FAIL Case 2 (readback): expected PC=1, got %0d", pc);
        if (instruction       !== 16'h2001) $fatal(1, "FAIL Case 2 (readback): expected ROM[1]=16'h2001 intact, got %h", instruction);
        if (instruction_valid !== 1'b0)     $fatal(1, "FAIL Case 2 (readback): expected instruction_valid=0, got %b", instruction_valid);
        if (data_valid        !== 1'b1)     $fatal(1, "FAIL Case 2 (readback): expected data_valid=1, got %b", data_valid);
        if (read_data         !== 16'd42)   $fatal(1, "FAIL Case 2 (readback): expected RAM[1]=42, got %0d", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd1) $fatal(1, "FAIL Case 2 (after read posedge): expected PC=1, got %0d", pc);

        // ============================================================
        // Case 3: Rejected data request during fetch
        //   At PC 1, enable fetch and request write of 99 to invalid address 17.
        //   Before edge: instruction_valid=1, data_valid=0 (bit 4 high rejects).
        //   After edge: PC advances to 2.
        //   Then read legal RAM word 1 back to confirm it was not aliased.
        // ============================================================
        @(negedge clk);
        fetch_enable      = 1'b1;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b1;
        data_address      = 5'd17;
        write_data        = 16'd99;

        #1;
        if (pc                !== 4'd1)     $fatal(1, "FAIL Case 3 (rejected write): expected PC=1, got %0d", pc);
        if (instruction       !== 16'h2001) $fatal(1, "FAIL Case 3 (rejected write): expected instruction=16'h2001, got %h", instruction);
        if (instruction_valid !== 1'b1)     $fatal(1, "FAIL Case 3 (rejected write): expected instruction_valid=1, got %b", instruction_valid);
        if (data_valid        !== 1'b0)     $fatal(1, "FAIL Case 3 (rejected write): expected data_valid=0 (rejected), got %b", data_valid);
        if (read_data         !== 16'h0000) $fatal(1, "FAIL Case 3 (rejected write): expected read_data=0, got %h", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd2) $fatal(1, "FAIL Case 3: expected PC=2 after fetch posedge, got %0d", pc);

        // Read legal RAM word 1 back to verify 42 is unchanged (no aliasing)
        @(negedge clk);
        fetch_enable      = 1'b0;
        data_write_enable = 1'b0;
        data_read_enable  = 1'b1;
        data_address      = 5'd1;

        #1;
        if (data_valid !== 1'b1)   $fatal(1, "FAIL Case 3 (readback 1): expected data_valid=1, got %b", data_valid);
        if (read_data  !== 16'd42) $fatal(1, "FAIL Case 3 (readback 1): expected RAM[1]=42 unchanged, got %0d", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd2) $fatal(1, "FAIL Case 3: expected PC=2, got %0d", pc);

        // ============================================================
        // Case 4: Reset with both paths requesting access
        //   At nonzero PC (PC=2), assert reset with fetch and write 123 to word 1.
        //   Before edge: instruction_valid=0, data_valid=0 (gated by reset).
        //   After edge: PC resets to 0.
        //   After releasing reset: read word 1 to verify 42 survived intact.
        // ============================================================
        @(negedge clk);
        reset             = 1'b1;
        fetch_enable      = 1'b1;
        data_read_enable  = 1'b0;
        data_write_enable = 1'b1;
        data_address      = 5'd1;
        write_data        = 16'd123;

        #1;
        if (instruction_valid !== 1'b0)     $fatal(1, "FAIL Case 4 (reset with requests): expected instruction_valid=0, got %b", instruction_valid);
        if (data_valid        !== 1'b0)     $fatal(1, "FAIL Case 4 (reset with requests): expected data_valid=0, got %b", data_valid);
        if (read_data         !== 16'h0000) $fatal(1, "FAIL Case 4 (reset with requests): expected read_data=0, got %h", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd0) $fatal(1, "FAIL Case 4 (after reset posedge): expected PC=0, got %0d", pc);

        // Release reset and read word 1 back
        @(negedge clk);
        reset             = 1'b0;
        fetch_enable      = 1'b0;
        data_write_enable = 1'b0;
        data_read_enable  = 1'b1;
        data_address      = 5'd1;

        #1;
        if (instruction_valid !== 1'b0)   $fatal(1, "FAIL Case 4 (readback): expected instruction_valid=0, got %b", instruction_valid);
        if (data_valid        !== 1'b1)   $fatal(1, "FAIL Case 4 (readback): expected data_valid=1, got %b", data_valid);
        if (read_data         !== 16'd42) $fatal(1, "FAIL Case 4 (readback): expected RAM[1]=42 survived reset, got %0d", read_data);

        @(posedge clk);
        #1;
        if (pc !== 4'd0) $fatal(1, "FAIL Case 4: expected PC=0, got %0d", pc);

        // ============================================================
        // All checks passed
        // ============================================================
        $display("PASS: Direct Harvard edge-case, isolation, rejected write, and reset tests passed");
        $finish;
    end

endmodule
