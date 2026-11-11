`timescale 1ns/1ps

module harvard_top (
    input wire clk,
    input wire reset,
    input wire fetch_enable,
    input wire data_read_enable,
    input wire data_write_enable,
    input wire [4:0] data_address,
    input wire [15:0] write_data,
    output wire [3:0] pc,
    output wire [15:0] instruction,
    output wire instruction_valid,
    output wire [15:0] read_data,
    output wire data_valid
);
    assign instruction_valid = fetch_enable && !reset;

    program_counter counter (
        .clk(clk),
        .reset(reset),
        .enable(instruction_valid),
        .pc(pc)
    );

    instruction_memory rom (
        .address(pc),
        .instruction(instruction)
    );

    data_path data (
        .clk(clk),
        .reset(reset),
        .read_enable(data_read_enable),
        .write_enable(data_write_enable),
        .address(data_address),
        .write_data(write_data),
        .read_data(read_data),
        .data_valid(data_valid)
    );
endmodule
