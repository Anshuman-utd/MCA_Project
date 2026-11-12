`timescale 1ns/1ps

// Harvard data path: address decoder, request qualification and data RAM.
// data_valid marks an accepted read or write. read_data is zero on idle,
// write, rejected and reset cycles.
module data_path (
    input wire clk,
    input wire reset,
    input wire read_enable,
    input wire write_enable,
    input wire [4:0] address,
    input wire [15:0] write_data,
    output wire [15:0] read_data,
    output wire data_valid
);
    wire address_valid;
    wire [3:0] word_address;
    wire read_accept;
    wire write_accept;

    address_decoder decoder (
        .address(address),
        .address_valid(address_valid),
        .word_address(word_address)
    );

    read_write_control control (
        .reset(reset),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address_valid(address_valid),
        .read_accept(read_accept),
        .write_accept(write_accept)
    );

    data_memory memory (
        .clk(clk),
        .read_accept(read_accept),
        .write_accept(write_accept),
        .word_address(word_address),
        .write_data(write_data),
        .read_data(read_data)
    );

    assign data_valid = read_accept || write_accept;
endmodule
