`timescale 1ns/1ps

// Splits a 5-bit data word address into a range check and a RAM word index.
// Bit 4 high means words 16-31, which are outside the 16-word RAM and are rejected,
// so 16 never aliases word 0 and 31 never aliases word 15.
module address_decoder (
    input wire [4:0] address,
    output wire address_valid,
    output wire [3:0] word_address
);
    assign address_valid = !address[4];
    assign word_address = address[3:0];
endmodule
