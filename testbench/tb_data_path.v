`timescale 1ns/1ps

// Self-checking unit test for the Harvard data path.
// Inputs change on falling edges. Combinational outputs are checked after they
// settle and before the committing rising edge. Writes are checked after that edge.
module tb_data_path;
    reg clk = 0;
    reg reset = 1;
    reg reset_next = 1;  // applied with the next request on a falling edge
    reg read_enable = 0;
    reg write_enable = 0;
    reg [4:0] address = 5'd0;
    reg [15:0] write_data = 16'd0;
    wire [15:0] read_data;
    wire data_valid;

    always #5 clk = ~clk;

    data_path dut (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .data_valid(data_valid)
    );

    // Apply a request on the falling edge and let combinational outputs settle.
    task request;
        input do_read;
        input do_write;
        input [4:0] request_address;
        input [15:0] request_data;
        begin
            @(negedge clk);
            reset = reset_next;
            read_enable = do_read;
            write_enable = do_write;
            address = request_address;
            write_data = request_data;
            #1;
        end
    endtask

    task expect_outputs;
        input expected_valid;
        input [15:0] expected_data;
        input [8*48-1:0] label;
        begin
            if (data_valid !== expected_valid || read_data !== expected_data)
                $fatal(1, "%0s: expected valid=%b data=%0d, got valid=%b data=%0d",
                       label, expected_valid, expected_data, data_valid, read_data);
        end
    endtask

    // Accepted read of a legal word, checked before the next rising edge.
    task expect_read;
        input [4:0] read_address;
        input [15:0] expected_data;
        begin
            request(1'b1, 1'b0, read_address, 16'd0);
            if (data_valid !== 1'b1 || read_data !== expected_data)
                $fatal(1, "read word %0d: expected valid=1 data=%0d, got valid=%b data=%0d",
                       read_address, expected_data, data_valid, read_data);
        end
    endtask

    initial begin
        $dumpfile("build/data_path.vcd");
        $dumpvars(0, tb_data_path);

        // Reset with no request.
        request(1'b0, 1'b0, 5'd0, 16'd0);
        expect_outputs(1'b0, 16'd0, "reset idle");
        reset_next = 0;

        // 1. Initialized words 0-3.
        expect_read(5'd0, 16'd10);
        expect_read(5'd1, 16'd20);
        expect_read(5'd2, 16'd5);
        expect_read(5'd3, 16'd0);
        expect_read(5'd15, 16'd0);

        // 2. Idle cycle.
        request(1'b0, 1'b0, 5'd2, 16'd0);
        expect_outputs(1'b0, 16'd0, "idle");

        // 3. Legal write to word 15: valid high, read_data zero, commit on the rising edge.
        request(1'b0, 1'b1, 5'd15, 16'hBEEF);
        expect_outputs(1'b1, 16'd0, "legal write to 15");
        if (dut.memory.words[15] !== 16'd0)
            $fatal(1, "word 15 changed before the rising edge");
        @(posedge clk);
        #1;
        if (dut.memory.words[15] !== 16'hBEEF)
            $fatal(1, "word 15 not written on the rising edge, got %h", dut.memory.words[15]);
        expect_read(5'd15, 16'hBEEF);
        // Write to a word that already holds a nonzero value: read_data must stay zero.
        request(1'b0, 1'b1, 5'd0, 16'd10);
        expect_outputs(1'b1, 16'd0, "legal write to nonzero word 0");

        // 4. Invalid reads and writes at 16 and 31.
        request(1'b1, 1'b0, 5'd16, 16'd0);
        expect_outputs(1'b0, 16'd0, "invalid read 16");
        request(1'b1, 1'b0, 5'd31, 16'd0);
        expect_outputs(1'b0, 16'd0, "invalid read 31");
        request(1'b0, 1'b1, 5'd16, 16'h1111);
        expect_outputs(1'b0, 16'd0, "invalid write 16");
        request(1'b0, 1'b1, 5'd31, 16'h2222);
        expect_outputs(1'b0, 16'd0, "invalid write 31");
        // Words 0 and 15 must not be aliased by 16 and 31.
        expect_read(5'd0, 16'd10);
        expect_read(5'd15, 16'hBEEF);

        // 5. Read and write together at a legal address: both suppressed.
        request(1'b1, 1'b1, 5'd2, 16'h7777);
        expect_outputs(1'b0, 16'd0, "simultaneous read and write");
        expect_read(5'd2, 16'd5);

        // 6. Reset with a write and then a read requested.
        reset_next = 1;
        request(1'b0, 1'b1, 5'd15, 16'h3333);
        expect_outputs(1'b0, 16'd0, "write during reset");
        request(1'b1, 1'b0, 5'd15, 16'd0);
        expect_outputs(1'b0, 16'd0, "read during reset");
        reset_next = 0;
        // Earlier write survives reset and the blocked write had no effect.
        expect_read(5'd15, 16'hBEEF);
        expect_read(5'd0, 16'd10);
        expect_read(5'd1, 16'd20);
        expect_read(5'd2, 16'd5);
        expect_read(5'd3, 16'd0);

        request(1'b0, 1'b0, 5'd0, 16'd0);
        expect_outputs(1'b0, 16'd0, "final idle");
        $display("PASS: data path init, read/write, range check, no aliasing, conflict suppression and reset");
        $finish;
    end
endmodule
