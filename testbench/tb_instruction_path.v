`timescale 1ns/1ps

module tb_instruction_path;
    reg clk = 0;
    reg reset = 1;
    reg enable = 1;
    wire [3:0] pc;
    wire [15:0] instruction;
    integer address;

    always #5 clk = ~clk;

    program_counter counter (.clk(clk), .reset(reset), .enable(enable), .pc(pc));
    instruction_memory rom (.address(pc), .instruction(instruction));

    task check_word;
        input [3:0] expected_pc;
        input [15:0] expected_instruction;
        begin
            if (pc !== expected_pc || instruction !== expected_instruction)
                $fatal(1, "Expected PC=%h word=%h, got PC=%h word=%h",
                       expected_pc, expected_instruction, pc, instruction);
        end
    endtask

    initial begin
        $dumpfile("build/instruction_path.vcd");
        $dumpvars(0, tb_instruction_path);
        @(negedge clk);
        check_word(4'd0, 16'h1002);
        reset = 0;
        enable = 0;
        @(negedge clk);
        check_word(4'd0, 16'h1002);
        enable = 1;

        @(negedge clk);
        check_word(4'd1, 16'h2001);
        @(negedge clk);
        check_word(4'd2, 16'h3003);
        @(negedge clk);
        check_word(4'd3, 16'hF000);
        for (address = 4; address < 16; address = address + 1) begin
            @(negedge clk);
            check_word(address[3:0], 16'h0000);
        end
        @(negedge clk);
        check_word(4'd0, 16'h1002);

        @(negedge clk);
        check_word(4'd1, 16'h2001);
        // Check that reset takes priority over a fetch from a nonzero PC.
        reset = 1;
        @(negedge clk);
        check_word(4'd0, 16'h1002);
        $display("PASS: PC reset priority, hold, all 16 ROM words and wraparound");
        $finish;
    end
endmodule
