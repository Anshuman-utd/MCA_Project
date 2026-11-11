# Phase I member work guide

Use the [interface contract](interfaces.md) for port names and behavior. Use the [agent prompts](team-prompts.md) to start implementation and the [Git commands](git-workflow.md) to publish each contribution.

| Member | Branch | Main deliverable | Screenshot to commit |
| --- | --- | --- | --- |
| 1 — Anshuman | `main` for the starter, `feature/integration` for later fixes | PC, instruction ROM, Harvard top, architecture and final integration | None required. The instruction-only waveform is for local checks. |
| 2 — Data path | `feature/data-path` | Address decoder, read/write control, data RAM and unit test | None required. Post the test result in the PR. |
| 3 — Controller and verification | `feature/controller-simulation` | Scripted controller, full Harvard test, state description | **`docs/harvard-waveform.png`** |
| 4 — Baseline and measurements | `feature/shared-memory` | Shared memory, matched comparison test, measurements and synthesis evidence | **`docs/comparison-waveform.png`** |
| 5 — Harvard edge-case tests and report handoff | `feature/harvard-directed-tests`, then `docs/report-demo` | Direct Harvard testbench, plus commit the report Anshuman prepares and add the video link | Use Members 3 and 4’s PNGs in the video. |

## Member 1 — Architecture and integration

1. Open `rtl/program_counter.v`, `rtl/instruction_memory.v`, and `rtl/harvard_top.v`. The starter already contains them. Be ready to explain the path from `fetch_enable` to `instruction_valid`, PC advance and the new ROM output.
2. Run `make -B test-instruction`. The test checks active-high synchronous reset, hold, all 16 ROM locations, wraparound and reset priority from a nonzero PC. Open `build/instruction_path.vcd` if you want to inspect the behavior before publishing.
3. Check the diagram in `docs/architecture.md`. The controller supplies requests in simulation. The PC drives only the ROM address. The data path receives its own address and control. Explain that a rising edge can accept a fetch and a data operation together.
4. Publish the starter and invite the other four collaborators. Give them their branch names and prompts. Ask each person to supply their actual name, PR link, test result, and two sentences explaining their design for the report.
5. Review Member 2's unit test before merging. On Member 3's branch check the four fetches, both valid bits, and write readback. On Member 4's branch check that the baseline has one address selection and a held fetch, and that the metric counts the same eight operations for each design. On Member 5’s branch, check that data-only writes leave the PC and ROM intact, and that rejected data requests do not stall a fetch.
6. After the feature branches land, run all five Make test targets from a fresh clone. Check the two screenshots against the VCDs, and confirm the five authors appear in the history. Prepare the IEEE report with the verified measurements, screenshots and actual contributions. Hand the final PDF and editable source to Member 5, then check that the report and video open for the evaluator.

## Member 2 — Data memory and unit test

1. In `rtl/address_decoder.v`, use the 5-bit word address. The upper bit selects whether it is in range, and the lower four bits select one of the 16 RAM words. Address 16 must never alias address 0, and address 31 must never alias address 15.
2. In `rtl/read_write_control.v`, qualify each request with address validity and `!reset`. Enable a read only when a read alone was requested. Enable a write only when a write alone was requested. Idle, reset, and both enables high must produce no operation.
3. In `rtl/data_memory.v`, use one 16-word array of 16-bit values. Initialize every location. Words 0, 1, 2, and 3 start at decimal 10, 20, 5, and 0. Set the remaining words to zero. Read the selected word combinationally when qualified. Return zero for a disabled read. Update a word only on a rising edge with a qualified write. Reset leaves memory contents intact.
4. In `rtl/data_path.v`, wire those modules together. Match the exact top-facing ports in `docs/interfaces.md`. Assert `data_valid` for a qualified read or write. During a write, `data_valid` is high and `read_data` is zero.
5. In `testbench/tb_data_path.v`, instantiate `data_path`, drive stimuli at falling edges, and sample after combinational settling. Verify a write by switching to a read after the committing edge. Use case inequality (`!==`) and `$fatal(1, ...)` so unexpected X/Z values fail the test.
6. Check the following before pushing. Run `make test-data` and report the final PASS line.

| Test | Expected |
| --- | --- |
| Read words 0, 1, 2, and 3 | `10`, `20`, `5`, `0` with valid high |
| Idle and legal write | Read data is zero. Valid is low during idle and high during the write. |
| Write a distinct value to word 15, then read it | New value appears after the write edge. |
| Invalid reads and writes at 16 and 31 | Valid low and read data zero. Read words 0 and 15 back to prove they kept their previous values. |
| Read and write enables high at a legal address | Both operations suppressed. A later read confirms the word kept its prior value. |
| Reset with a request asserted | No access is accepted. After reset, an earlier successful write is still present. |

## Member 3 — Controller, integrated test and Harvard screenshot

1. In `rtl/controller.v`, use states for idle, four request steps, and done. Reset returns the state to idle and suppresses request outputs. In idle, latch the transition when `start` is sampled high. Assert `done` for one cycle after step 4, then return to idle. Set combinational defaults for every output to keep idle outputs defined.
2. Set the outputs in the table below. Each step asserts `fetch_enable` and exactly one data enable. Use zero for unused address or write-data outputs in idle and done. `start` is a one-cycle pulse applied in idle. Begin the demo after a PC reset.

| Step | Fetch PC | ROM word in hex | Data request | Expected read in decimal |
| --- | --- | --- | --- | --- |
| 1 | 0 | `1002` | Read word 2 | 5 |
| 2 | 1 | `2001` | Write 10 to word 3 | 0 on the read output during write |
| 3 | 2 | `3003` | Read word 1 | 20 |
| 4 | 3 | `F000` | Read word 3 | 10 |

3. In `testbench/tb_harvard.v`, connect `controller` to `harvard_top`. Pulse start from a falling edge, wait for the controller to enter step 1, and inspect each active request before its committing rising edge. Verify PC, instruction, request type, address, write data where applicable, `instruction_valid`, `data_valid`, and read results. Confirm that the write is visible on step 4, the PC reaches 4 after the fourth accepted fetch, and the PC holds while idle. Verify reset returns the PC and controller to their initial states. Use `$fatal(1, ...)` on mismatches and add a timeout so a stuck controller fails.
4. Use `$dumpfile("build/harvard.vcd");` and `$dumpvars(0, tb_harvard);` in the testbench. Run `iverilog -g2005 -Wall -tnull -s controller rtl/controller.v` while waiting for the data path. Once Member 2's branch is merged into yours, run `make test-harvard`.
5. Capture and commit **`docs/harvard-waveform.png`** using the steps below. In `docs/controller.md`, add a short state transition list, the test command and PASS result, and identify the clock edges in the screenshot that show overlap and readback. Share the PR and screenshot with Anshuman for the report and Member 5 for the video.

## Member 4 — Shared port, comparison, synthesis and screenshot

1. In `rtl/shared_memory.v`, expose the same input and output ports as `harvard_top`. Reuse `program_counter` and increment it only on an instruction grant. Use one 32-word array, one selected word address and one array read expression for the shared port. Place the ROM words in physical words 0–15 and the initial data words in physical words 16–31. Initialize unused words to zero.
2. A legal data request is out of reset, has address 0–15, and asserts exactly one data enable. Grant legal data first. If it is granted, select the data region and leave `instruction_valid` low. Otherwise grant a pending fetch out of reset and select the instruction region. Perform a data write only when granted, at the rising edge. Drive the instruction and data outputs from the selected word when their corresponding read is granted. Tests should sample instructions only when `instruction_valid` is high. Check that reset suppresses grants and preserves the array.
3. In `testbench/tb_comparison.v`, instantiate the Harvard top and shared baseline. Give both the four request pairs from the controller table. Use independent row and pending flags for each DUT. After each rising edge, drop only the requests that were granted. Present the next row only when both operations in the current row have completed. This lets Harvard advance every cycle and lets the shared design finish the held fetch without repeating a write. Keep the workload continuous and exclude reset and setup from the count.
4. Assert the expected instructions, read values and grant totals. For a contested fetch, verify the shared PC holds and advances when the fetch is granted. After the measured run, separately check that an invalid data request does not block a fetch. Use the same initial contents and timing for both designs. Dump `build/comparison.vcd` with both DUTs visible.
5. While waiting for Member 2, compile your baseline with `iverilog -g2005 -Wall -tnull -s shared_memory rtl/program_counter.v rtl/shared_memory.v`. After Member 2's merge, run `make test-comparison`. Record actual grant totals and cycles in `docs/comparison.md`. Expected results are eight accepted operations in each design, four cycles for Harvard and eight for shared memory. Compute operations per cycle as accepted operations divided by counted cycles. Report the throughput ratio for this workload. Record any unexpected count and resolve the cause before claiming the result.
6. Capture and commit **`docs/comparison-waveform.png`** using the steps below. In `docs/comparison.md`, explain which edge shows the contested request and which edge completes the held fetch.
7. Run the same synthesis flow on both tops. With Yosys installed, use the commands below after the data RTL is available. In `synthesis/results.md`, record tool version, commands, each top's actual resource counts, and any warnings that affect interpretation. Generic counts describe the synthesized design. For FPGA utilization or maximum clock frequency, name the device and timing flow, and use the implemented design's timing report. Record timing as pending if the team lacks a target or timing tools.

```sh
yosys -V
yosys -p 'read_verilog rtl/program_counter.v rtl/instruction_memory.v rtl/address_decoder.v rtl/read_write_control.v rtl/data_memory.v rtl/data_path.v rtl/harvard_top.v; synth -top harvard_top; stat'
yosys -p 'read_verilog rtl/program_counter.v rtl/shared_memory.v; synth -top shared_memory; stat'
```

## Member 5 — Harvard edge-case tests and report handoff

### First PR · Direct Harvard tests

1. Start `feature/harvard-directed-tests` and create `testbench/tb_harvard_directed.v`. Instantiate `harvard_top` with named ports and drive its request inputs yourself. The Make target is ready. Your testbench is independent of Member 3’s controller and can run as soon as Member 2’s data path is available.
2. Start with a reset cycle. Drive requests on falling edges, check read and valid outputs after they settle, and check PC or stored values after the corresponding rising edge. Use `!==` and `$fatal(1, ...)` so incorrect values and unknowns fail. Keep the checks in one short directed sequence with descriptive failure messages.
3. Cover these cases. Use decimal 42 as a distinctive write value.

| Case | Setup and expected result |
| --- | --- |
| Fetch only | With PC at 0 and both data enables low, assert fetch. Before the edge, see instruction `1002` in hex, instruction valid high, data valid low, and read data zero. After the edge, PC is 1. |
| Data-only access at the same numerical address | Disable fetch. With PC held at 1, write 42 to data word 1, then read it back. The write is accepted and the later read returns 42. Throughout, the PC stays 1, the ROM output stays hex `2001`, and instruction valid stays low. This checks that the RAM write at address 1 leaves ROM address 1 intact. |
| Rejected data request during fetch | At PC 1, enable fetch and request a write of 99 to invalid address 17. Instruction valid stays high, data valid stays low, and the PC advances to 2. Read legal data word 1 afterward to check the rejected write did not alias it. |
| Reset with both paths requesting access | At a nonzero PC, assert reset together with fetch and a write of 123 to data word 1. Both valid flags go low and the reset edge sets PC to 0. After releasing reset, read word 1 and verify that 42 survived and the attempted write had no effect. |

4. Run `make test-harvard-directed`. Print a single clear PASS message after the last check. If you need a waveform for debugging, dump it to `build/harvard_directed.vcd`. The PASS result and testbench are your code evidence. Members 3 and 4 own the submission screenshots.
5. Commit the testbench and open its PR. Include the test command, PASS result, and a short explanation of how the test proves that RAM writes leave the instruction path intact. Send this evidence to Anshuman for the report.

### Second PR · Commit the report and link the video

1. Anshuman prepares the final IEEE report after the evidence is ready. Send Anshuman your test result, PR link, and a description of your actual contribution. Help collect the other members’ names, PR links and verified results.
2. After Anshuman hands you the PDF and editable source, create `docs/report-demo` from updated `main`. Add the supplied PDF as `docs/IEEE_Project_Report.pdf` and its editable source under `docs/report/`. Open the PDF and check that the figures, captions and names render correctly. Ask Anshuman to fix any content issues before committing.
3. Coordinate the video using [the demo handoff](demo.md). In your speaking turn, show what the direct Harvard test proves. Use the two PNGs captured by Members 3 and 4. After upload, add the working URL to the README and verify playback with the evaluator’s expected access.
4. Open the report and video PR. The contribution record should credit Anshuman for report preparation and Member 5 for the directed tests, report commit and video work actually completed.

## How to capture and commit the two screenshots

Icarus Verilog writes the VCD when the testbench runs. Start the viewer after the test passes. On macOS, install Surfer with `brew install surfer`. GTKWave also opens these VCDs, for example `gtkwave build/harvard.vcd`. [Surfer user guide](https://docs.surfer-project.org/book/) · [GTKWave documentation](https://gtkwave.github.io/gtkwave/)

| Owner | Generate and open | Signals and proof to capture |
| --- | --- | --- |
| **Member 3** | `make test-harvard`, then `surfer build/harvard.vcd` | Add `clk`, `pc`, `instruction`, `instruction_valid`, `data_valid`, `data_read_enable`, `data_write_enable`, `data_address`, `read_data`, and `write_data`. Zoom to the four request steps. Show the same-edge fetch/read of 5, the fetch/write of 10, and the later readback of 10. Save as **`docs/harvard-waveform.png`**. |
| **Member 4** | `make test-comparison`, then `surfer build/comparison.vcd` | Add clock and each DUT's fetch request, data request enables, `instruction_valid`, `data_valid`, and PC. Group signals by DUT. Show Harvard granting both requests on one edge while the shared port grants data only, holds the PC, and grants the held fetch later. Save as **`docs/comparison-waveform.png`**. |

In the viewer, expand the testbench and DUT scopes to find signals. Use hex for instruction words and decimal for data if available. Keep signal names, values, time scale, and rising edges visible. Place the cursor near the relevant edge and leave the neighboring cycles in frame. Capture the viewer region with your OS screenshot tool. On Mac, use Shift–Command–4, then move or rename the PNG to its exact path above. Open the saved PNG and confirm it stays legible at normal size. Each owner stages their own PNG with the matching verification files. The raw VCDs stay in the ignored `build/` directory and can be regenerated with Make.
