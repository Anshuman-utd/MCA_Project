`timescale 1ns/1ps

module tb_comparison;
    reg clk = 0;
    reg reset = 1;

    // Harvard DUT signals
    reg h_fetch_enable = 0;
    reg h_data_read_enable = 0;
    reg h_data_write_enable = 0;
    reg [4:0] h_data_address = 0;
    reg [15:0] h_write_data = 0;
    wire [3:0] h_pc;
    wire [15:0] h_instruction;
    wire h_instruction_valid;
    wire [15:0] h_read_data;
    wire h_data_valid;

    // Shared Memory DUT signals
    reg s_fetch_enable = 0;
    reg s_data_read_enable = 0;
    reg s_data_write_enable = 0;
    reg [4:0] s_data_address = 0;
    reg [15:0] s_write_data = 0;
    wire [3:0] s_pc;
    wire [15:0] s_instruction;
    wire s_instruction_valid;
    wire [15:0] s_read_data;
    wire s_data_valid;

    // Instantiate Harvard architecture DUT
    harvard_top u_harvard (
        .clk(clk),
        .reset(reset),
        .fetch_enable(h_fetch_enable),
        .data_read_enable(h_data_read_enable),
        .data_write_enable(h_data_write_enable),
        .data_address(h_data_address),
        .write_data(h_write_data),
        .pc(h_pc),
        .instruction(h_instruction),
        .instruction_valid(h_instruction_valid),
        .read_data(h_read_data),
        .data_valid(h_data_valid)
    );

    // Instantiate Shared-Memory baseline DUT
    shared_memory u_shared (
        .clk(clk),
        .reset(reset),
        .fetch_enable(s_fetch_enable),
        .data_read_enable(s_data_read_enable),
        .data_write_enable(s_data_write_enable),
        .data_address(s_data_address),
        .write_data(s_write_data),
        .pc(s_pc),
        .instruction(s_instruction),
        .instruction_valid(s_instruction_valid),
        .read_data(s_read_data),
        .data_valid(s_data_valid)
    );

    // Clock generator (10ns period: #5 low, #5 high)
    always #5 clk = ~clk;

    // Workload definitions: 4 rows of (fetch + data operation)
    // Row 0: Fetch PC 0 (1002h) + Read Data 2 (expected 5)
    // Row 1: Fetch PC 1 (2001h) + Write Data 3 with 10
    // Row 2: Fetch PC 2 (3003h) + Read Data 1 (expected 20)
    // Row 3: Fetch PC 3 (F000h) + Readback Data 3 (expected 10)
    reg [3:0] expected_fetch_pc [0:3];
    reg [15:0] expected_instruction [0:3];
    reg [4:0] req_data_address [0:3];
    reg req_data_is_write [0:3];
    reg [15:0] req_write_data [0:3];
    reg [15:0] expected_read_data [0:3];

    initial begin
        expected_fetch_pc[0]   = 4'd0;
        expected_instruction[0]= 16'h1002;
        req_data_address[0]    = 5'd2;
        req_data_is_write[0]   = 1'b0;
        req_write_data[0]      = 16'd0;
        expected_read_data[0]  = 16'd5;

        expected_fetch_pc[1]   = 4'd1;
        expected_instruction[1]= 16'h2001;
        req_data_address[1]    = 5'd3;
        req_data_is_write[1]   = 1'b1;
        req_write_data[1]      = 16'd10;
        expected_read_data[1]  = 16'd0;

        expected_fetch_pc[2]   = 4'd2;
        expected_instruction[2]= 16'h3003;
        req_data_address[2]    = 5'd1;
        req_data_is_write[2]   = 1'b0;
        req_write_data[2]      = 16'd0;
        expected_read_data[2]  = 16'd20;

        expected_fetch_pc[3]   = 4'd3;
        expected_instruction[3]= 16'hF000;
        req_data_address[3]    = 5'd3;
        req_data_is_write[3]   = 1'b0;
        req_write_data[3]      = 16'd0;
        expected_read_data[3]  = 16'd10;
    end

    // Independent execution state for each DUT
    integer h_row = 0;
    reg h_fetch_pending = 0;
    reg h_data_pending = 0;
    integer h_cycles = 0;
    integer h_grants = 0;
    reg h_done = 0;

    integer s_row = 0;
    reg s_fetch_pending = 0;
    reg s_data_pending = 0;
    integer s_cycles = 0;
    integer s_grants = 0;
    reg s_done = 0;

    // Timeout watchdog
    initial begin
        #5000;
        $fatal(1, "ERROR: tb_comparison timed out!");
    end

    reg [3:0] prev_s_pc;

    initial begin
        $dumpfile("build/comparison.vcd");
        $dumpvars(0, tb_comparison);

        // Reset sequence across posedge clk
        reset = 1;
        h_fetch_enable = 0;
        h_data_read_enable = 0;
        h_data_write_enable = 0;
        s_fetch_enable = 0;
        s_data_read_enable = 0;
        s_data_write_enable = 0;

        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Initialize state for row 0 on both DUTs
        h_row = 0;
        h_fetch_pending = 1;
        h_data_pending = 1;
        h_done = 0;
        h_cycles = 0;
        h_grants = 0;

        s_row = 0;
        s_fetch_pending = 1;
        s_data_pending = 1;
        s_done = 0;
        s_cycles = 0;
        s_grants = 0;

        // Main cycle-by-cycle comparison loop
        // Each iteration runs one full clock cycle:
        // Starts at negedge clk, checks settled signals before posedge clk,
        // commits at posedge clk, and finishes at the next negedge clk.
        while (!h_done || !s_done) begin
            // -------------------------------------------------------------
            // 1. Drive stimulus at negedge clk (away from rising edge)
            // -------------------------------------------------------------
            // Harvard DUT stimulus
            if (!h_done) begin
                h_fetch_enable = h_fetch_pending;
                if (h_data_pending) begin
                    h_data_address = req_data_address[h_row];
                    if (req_data_is_write[h_row]) begin
                        h_data_write_enable = 1;
                        h_data_read_enable = 0;
                        h_write_data = req_write_data[h_row];
                    end else begin
                        h_data_write_enable = 0;
                        h_data_read_enable = 1;
                        h_write_data = 0;
                    end
                end else begin
                    h_data_read_enable = 0;
                    h_data_write_enable = 0;
                    h_data_address = 0;
                    h_write_data = 0;
                end
            end else begin
                h_fetch_enable = 0;
                h_data_read_enable = 0;
                h_data_write_enable = 0;
                h_data_address = 0;
                h_write_data = 0;
            end

            // Shared-memory DUT stimulus
            if (!s_done) begin
                s_fetch_enable = s_fetch_pending;
                if (s_data_pending) begin
                    s_data_address = req_data_address[s_row];
                    if (req_data_is_write[s_row]) begin
                        s_data_write_enable = 1;
                        s_data_read_enable = 0;
                        s_write_data = req_write_data[s_row];
                    end else begin
                        s_data_write_enable = 0;
                        s_data_read_enable = 1;
                        s_write_data = 0;
                    end
                end else begin
                    s_data_read_enable = 0;
                    s_data_write_enable = 0;
                    s_data_address = 0;
                    s_write_data = 0;
                end
            end else begin
                s_fetch_enable = 0;
                s_data_read_enable = 0;
                s_data_write_enable = 0;
                s_data_address = 0;
                s_write_data = 0;
            end

            // -------------------------------------------------------------
            // 2. Sample settled combinational values just before rising edge
            // -------------------------------------------------------------
            #4; // 1ns before posedge clk

            // Harvard DUT checks
            if (!h_done) begin
                if (h_fetch_pending) begin
                    if (h_instruction_valid !== 1'b1)
                        $fatal(1, "Harvard fetch_valid expected 1, got %b", h_instruction_valid);
                    if (h_pc !== expected_fetch_pc[h_row])
                        $fatal(1, "Harvard expected PC %h, got %h", expected_fetch_pc[h_row], h_pc);
                    if (h_instruction !== expected_instruction[h_row])
                        $fatal(1, "Harvard expected instr %h, got %h", expected_instruction[h_row], h_instruction);
                end
                if (h_data_pending) begin
                    if (h_data_valid !== 1'b1)
                        $fatal(1, "Harvard data_valid expected 1, got %b", h_data_valid);
                    if (!req_data_is_write[h_row] && h_read_data !== expected_read_data[h_row])
                        $fatal(1, "Harvard expected read_data %0d, got %0d", expected_read_data[h_row], h_read_data);
                    if (req_data_is_write[h_row] && h_read_data !== 16'h0000)
                        $fatal(1, "Harvard expected 0 read_data during write, got %h", h_read_data);
                end
            end

            // Shared memory DUT checks
            if (!s_done) begin
                if (s_data_pending) begin
                    // Contention: data MUST win, fetch MUST be held
                    if (s_data_valid !== 1'b1)
                        $fatal(1, "Shared memory data_valid expected 1, got %b", s_data_valid);
                    if (s_instruction_valid !== 1'b0)
                        $fatal(1, "Shared memory instruction_valid expected 0 during contention, got %b", s_instruction_valid);
                    if (!req_data_is_write[s_row] && s_read_data !== expected_read_data[s_row])
                        $fatal(1, "Shared memory expected read_data %0d, got %0d", expected_read_data[s_row], s_read_data);
                    if (req_data_is_write[s_row] && s_read_data !== 16'h0000)
                        $fatal(1, "Shared memory expected 0 read_data during write, got %h", s_read_data);
                end else if (s_fetch_pending) begin
                    // Held fetch now proceeds
                    if (s_instruction_valid !== 1'b1)
                        $fatal(1, "Shared memory held fetch instruction_valid expected 1, got %b", s_instruction_valid);
                    if (s_data_valid !== 1'b0)
                        $fatal(1, "Shared memory data_valid expected 0 during fetch, got %b", s_data_valid);
                    if (s_pc !== expected_fetch_pc[s_row])
                        $fatal(1, "Shared memory expected PC %h, got %h", expected_fetch_pc[s_row], s_pc);
                    if (s_instruction !== expected_instruction[s_row])
                        $fatal(1, "Shared memory expected instr %h, got %h", expected_instruction[s_row], s_instruction);
                end
            end

            prev_s_pc = s_pc;

            // -------------------------------------------------------------
            // 3. Committing rising edge
            // -------------------------------------------------------------
            @(posedge clk);
            #1; // Sample immediately after registered updates

            // Harvard accounting
            if (!h_done) begin
                h_cycles = h_cycles + 1;
                if (h_instruction_valid) begin
                    h_grants = h_grants + 1;
                    h_fetch_pending = 0;
                end
                if (h_data_valid) begin
                    h_grants = h_grants + 1;
                    h_data_pending = 0;
                end

                if (!h_fetch_pending && !h_data_pending) begin
                    h_row = h_row + 1;
                    if (h_row == 4) begin
                        h_done = 1;
                    end else begin
                        h_fetch_pending = 1;
                        h_data_pending = 1;
                    end
                end
            end

            // Shared-memory accounting
            if (!s_done) begin
                s_cycles = s_cycles + 1;
                if (s_data_valid) begin
                    s_grants = s_grants + 1;
                    s_data_pending = 0; // Data completed, fetch remains pending
                    // Verify PC held during contention
                    if (s_pc !== prev_s_pc)
                        $fatal(1, "Shared PC changed during contention! Expected %h, got %h", prev_s_pc, s_pc);
                end else if (s_instruction_valid) begin
                    s_grants = s_grants + 1;
                    s_fetch_pending = 0; // Held fetch completed
                end

                if (!s_fetch_pending && !s_data_pending) begin
                    s_row = s_row + 1;
                    if (s_row == 4) begin
                        s_done = 1;
                    end else begin
                        s_fetch_pending = 1;
                        s_data_pending = 1;
                    end
                end
            end

            // -------------------------------------------------------------
            // 4. Move to next falling edge for next iteration
            // -------------------------------------------------------------
            @(negedge clk);
        end

        // -----------------------------------------------------------------
        // Workload completion validation
        // -----------------------------------------------------------------
        $display("------------------------------------------------------------");
        $display("Workload Complete");
        $display("Harvard DUT:       Cycles = %0d, Grants = %0d, Ops/Cycle = %0.2f",
                 h_cycles, h_grants, (h_grants * 1.0) / h_cycles);
        $display("Shared-Memory DUT: Cycles = %0d, Grants = %0d, Ops/Cycle = %0.2f",
                 s_cycles, s_grants, (s_grants * 1.0) / s_cycles);
        $display("Speedup Ratio:     %0.2fx", (h_grants * 1.0 / h_cycles) / ((s_grants * 1.0) / s_cycles));
        $display("------------------------------------------------------------");

        if (h_grants !== 8)
            $fatal(1, "FAIL: Harvard total grants expected 8, got %0d", h_grants);
        if (s_grants !== 8)
            $fatal(1, "FAIL: Shared memory total grants expected 8, got %0d", s_grants);
        if (h_cycles !== 4)
            $fatal(1, "FAIL: Harvard cycles expected 4, got %0d", h_cycles);
        if (s_cycles !== 8)
            $fatal(1, "FAIL: Shared memory cycles expected 8, got %0d", s_cycles);

        // -----------------------------------------------------------------
        // Corner-case test: Invalid data request does NOT consume fetch slot
        // -----------------------------------------------------------------
        // Case 1: Out-of-range data address (bit 4 = 1, address 17)
        s_fetch_enable = 1;
        s_data_write_enable = 1;
        s_data_read_enable = 0;
        s_data_address = 5'd17;
        s_write_data = 16'hDEAD;

        #4;
        if (s_data_valid !== 1'b0)
            $fatal(1, "FAIL: Invalid data address (17) asserted data_valid!");
        if (s_instruction_valid !== 1'b1)
            $fatal(1, "FAIL: Fetch was blocked by invalid data address!");
        @(posedge clk);
        #1;

        @(negedge clk);
        // Case 2: Concurrent read and write enable (conflicting control)
        s_fetch_enable = 1;
        s_data_read_enable = 1;
        s_data_write_enable = 1;
        s_data_address = 5'd1;

        #4;
        if (s_data_valid !== 1'b0)
            $fatal(1, "FAIL: Concurrent read/write asserted data_valid!");
        if (s_instruction_valid !== 1'b1)
            $fatal(1, "FAIL: Fetch was blocked by conflicting data enables!");
        @(posedge clk);
        #1;

        @(negedge clk);
        // Verify word 1 was untouched
        s_fetch_enable = 0;
        s_data_read_enable = 1;
        s_data_write_enable = 0;
        s_data_address = 5'd1;

        #4;
        if (s_read_data !== 16'd20)
            $fatal(1, "FAIL: Word 1 corrupted by rejected operations! Expected 20, got %0d", s_read_data);

        $display("PASS: All comparison checks and corner-case tests passed successfully!");
        $finish;
    end
endmodule
