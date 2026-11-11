`timescale 1ns/1ps

module program_counter (
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [3:0] pc
);
    always @(posedge clk) begin
        if (reset)
            pc <= 4'd0;
        else if (enable)
            pc <= pc + 4'd1;
    end
endmodule
