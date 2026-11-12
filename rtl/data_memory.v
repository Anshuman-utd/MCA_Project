`timescale 1ns/1ps

// 16-word x 16-bit data RAM. Reads are combinational and return zero unless a
// qualified read is active. Writes commit on the rising edge only for a qualified
// write. The array has no reset, so its contents persist through reset.
module data_memory (
    input wire clk,
    input wire read_accept,
    input wire write_accept,
    input wire [3:0] word_address,
    input wire [15:0] write_data,
    output wire [15:0] read_data
);
    reg [15:0] words [0:15];
    integer index;

    initial begin
        for (index = 0; index < 16; index = index + 1)
            words[index] = 16'd0;
        words[0] = 16'd10;
        words[1] = 16'd20;
        words[2] = 16'd5;
        words[3] = 16'd0;
    end

    always @(posedge clk) begin
        if (write_accept)
            words[word_address] <= write_data;
    end

    assign read_data = read_accept ? words[word_address] : 16'd0;
endmodule
