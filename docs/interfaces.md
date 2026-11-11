# Phase I interface contract

Use Verilog-2005 RTL. All addresses are word addresses. Reads are combinational and sampled just before a rising edge. Writes commit on the rising edge. Keep inputs stable across that edge. `reset` is active high and synchronous for the PC and controller. Gate transaction valid/enable signals while reset is asserted. RAM contents persist across reset.

## Harvard top (Member 1)

`harvard_top` inputs: `clk`, `reset`, `fetch_enable`, `data_read_enable`, `data_write_enable`, `data_address[4:0]`, `write_data[15:0]`.

Outputs: `pc[3:0]`, `instruction[15:0]`, `instruction_valid`, `read_data[15:0]`, `data_valid`.

`instruction_valid = fetch_enable && !reset`. The PC resets to 0, increments on a valid fetch and wraps after 15. ROM addresses 0–3 contain hex 1002, 2001, 3003, F000. The other words return zero. Instruction output continuously reflects the PC. Use the valid bit to qualify it.

## Data path (Member 2)

`data_path` inputs: `clk`, `reset`, `read_enable`, `write_enable`, `address[4:0]`, `write_data[15:0]`. Outputs: `read_data[15:0]`, `data_valid`.

Accept exactly one enable when out of reset and address is 0–15. Bit 4 acts as the range check and bits 3:0 select the word. `data_valid` marks an accepted read or write. Return zero on idle, write or invalid requests. Ignore concurrent read/write and invalid addresses, including invalid writes. Initialize addresses 0–3 to decimal 10, 20, 5, 0 and the rest to zero. Use separate small modules for the address decoder, control qualification and RAM.

## Controller and verification (Member 3)

`controller` inputs: `clk`, `reset`, `start`. Outputs match the top-level request inputs `fetch_enable`, `data_read_enable`, `data_write_enable`, `data_address[4:0]`, `write_data[15:0]` plus `done`. Accept a one-cycle start pulse while idle. Issue four successive request cycles, then assert done for one cycle and return to idle. For the documented workload start from reset with freshly initialized memory. Instantiate the controller and Harvard top together in `tb_harvard`.

| Step | Fetch PC | Data operation | Expected read (decimal) |
| --- | --- | --- | --- |
| 1 | 0 | Read 2 | 5 |
| 2 | 1 | Write 10 to 3 | — |
| 3 | 2 | Read 1 | 20 |
| 4 | 3 | Read back 3 | 10 |

Use `tb_harvard` for the controller-driven sequence and dump `build/harvard.vcd`. Use `$fatal(1, ...)` in testbenches for failure.

## Direct Harvard checks (Member 5)

Instantiate `harvard_top` directly in `tb_harvard_directed` and drive requests without the controller. Verify fetch-only and data-only operation, instruction/data isolation at the same numerical address, fetch progress during a rejected data request, and reset with active requests. The [member work guide](member-work.md#member-5--harvard-edge-case-tests-and-report-handoff) lists the exact cases. Run `make test-harvard-directed` when Member 2's RTL is available. If you dump a waveform, use `build/harvard_directed.vcd` for local inspection.

## Shared-memory comparison (Member 4)

`shared_memory` inputs match the Harvard top inputs. Outputs match the Harvard top outputs. Here the valid bits are grants. If a legal data operation and fetch compete, grant data and hold the PC until the fetch is accepted. Invalid data requests consume no slot. The requester holds or retries any ungranted operation. Use one array with one selected address per cycle. Map PC to words 0–15 and data addresses 0–15 to words 16–31. Use the same initial words as Harvard.

In `tb_comparison`, present the same four rows to each DUT independently. Advance a row only after both its requests complete. Deassert each request after its grant so it is accepted exactly once. Check all returned values, including readback. Count rising edges from the first request to the last grant, excluding reset and setup. Expected under this workload: 8 operations, 4 Harvard cycles and 8 shared-memory cycles. Publish actual measured cycles, operations per cycle, and their ratio. Dump `build/comparison.vcd`.
