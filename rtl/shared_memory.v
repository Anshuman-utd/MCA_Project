`timescale 1ns/1ps

module shared_memory (
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
    // 32-word x 16-bit unified memory
    reg [15:0] memory [0:31];

    // Data request validity check:
    // Legal data request requires: out of reset, address 0-15 (bit 4 == 0),
    // and exactly one of read_enable or write_enable asserted.
    wire legal_data_address = (data_address[4] == 1'b0);
    wire single_data_enable = (data_read_enable ^ data_write_enable);
    wire legal_data_request = !reset && legal_data_address && single_data_enable;

    // Arbitration: data has strict priority over instruction fetch
    wire data_grant = legal_data_request;
    wire fetch_grant = !legal_data_request && fetch_enable && !reset;

    assign data_valid = data_grant;
    assign instruction_valid = fetch_grant;

    // Program counter advances only when instruction fetch is granted
    program_counter counter (
        .clk(clk),
        .reset(reset),
        .enable(fetch_grant),
        .pc(pc)
    );

    // Single shared address selection:
    // Data accesses map to physical addresses 16-31.
    // Instruction fetches map to physical addresses 0-15.
    reg [4:0] selected_address;
    always @* begin
        if (data_grant)
            selected_address = {1'b1, data_address[3:0]};
        else
            selected_address = {1'b0, pc};
    end

    // Single shared array read expression
    wire [15:0] shared_read_word = memory[selected_address];

    // Read outputs gated by grant and request type
    assign instruction = fetch_grant ? shared_read_word : 16'h0000;
    assign read_data = (data_grant && data_read_enable) ? shared_read_word : 16'h0000;

    // Memory write: only an accepted write commits at rising edge
    always @(posedge clk) begin
        if (data_grant && data_write_enable) begin
            memory[selected_address] <= write_data;
        end
    end

    // Initial memory values matching both architectures
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            memory[i] = 16'h0000;
        end
        // Physical addresses 0-3: Instruction ROM contents
        memory[0] = 16'h1002;
        memory[1] = 16'h2001;
        memory[2] = 16'h3003;
        memory[3] = 16'hF000;

        // Physical addresses 16-19: Data RAM initial contents (words 0-3)
        memory[16] = 16'd10;
        memory[17] = 16'd20;
        memory[18] = 16'd5;
        memory[19] = 16'd0;
    end
endmodule
