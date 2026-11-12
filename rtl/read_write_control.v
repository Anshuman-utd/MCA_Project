`timescale 1ns/1ps

// Qualifies raw read/write requests. An operation is accepted only when it is the
// single requested enable, the address is in range and reset is low. Idle, reset,
// an invalid address or both enables high produce no operation.
module read_write_control (
    input wire reset,
    input wire read_enable,
    input wire write_enable,
    input wire address_valid,
    output wire read_accept,
    output wire write_accept
);
    wire request_allowed = address_valid && !reset;

    assign read_accept = request_allowed && read_enable && !write_enable;
    assign write_accept = request_allowed && write_enable && !read_enable;
endmodule
