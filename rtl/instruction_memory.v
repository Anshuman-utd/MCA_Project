`timescale 1ns/1ps

module instruction_memory (
    input wire [3:0] address,
    output reg [15:0] instruction
);
    always @* begin
        case (address)
            4'd0: instruction = 16'h1002;
            4'd1: instruction = 16'h2001;
            4'd2: instruction = 16'h3003;
            4'd3: instruction = 16'hF000;
            default: instruction = 16'h0000;
        endcase
    end
endmodule
