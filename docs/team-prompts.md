# Copy-paste coding agent prompts

Send each teammate the **Common prompt** and their own **Member prompt**. They should open their own clone in the coding agent and paste both blocks. The [member work guide](member-work.md) gives the detailed sequence and screenshot instructions. The [Git guide](git-workflow.md) gives the human-run commit and push commands.

## Common prompt

```text
Help me finish only my assigned part of our MCA Phase I Harvard memory project. Start by reading README.md, docs/interfaces.md, docs/member-work.md, and Makefile. Treat the interface contract as the source of truth for module names, port names, widths, reset, timing, and workload. Check git status and my current branch before editing. Keep the RTL small and in Verilog-2005. Use named port connections and clear signal names. Keep the existing file layout and Make targets. Coordinate any required interface change with its owner.

Use nonblocking assignments for clocked RTL and defined defaults for combinational control. In a testbench, drive requests away from the rising edge, sample settled read/grant outputs before the committing edge, and check registered changes after it. Use self-checking assertions with $fatal(1, ...) for failed checks. Keep simulator outputs in build/. Report actual test results and mark dependency-blocked tests as pending. End with changed files, commands run, evidence, and anything I must finish manually. Give me the Git commands from docs/git-workflow.md for my role so I can review and push my own commits.
```

## Member 1 — Architecture and integration

```text
I am Member 1. My initial work is on main. Use feature/integration for follow-up fixes after the starter is published. My files include rtl/program_counter.v, rtl/instruction_memory.v, rtl/harvard_top.v, testbench/tb_instruction_path.v, the architecture and interface docs, and the starter Makefile.

Review the existing implementation. Trace fetch_enable and reset into instruction_valid and PC enable. Confirm the PC starts at 0 on a reset edge, holds when disabled, advances only on a valid fetch and wraps from 15 to 0. Verify the ROM outputs hex 1002, 2001, 3003, F000 at addresses 0–3 and zero elsewhere. Check the Harvard top's named port connections against the data_path contract. Run make -B test-instruction and check that build/instruction_path.vcd exists. Explain in plain language what the test demonstrates and how to inspect it. No instruction-only screenshot is required in the submission.

Once teammate PRs exist, review Member 2's test and check for invalid address aliasing and reset side effects. Review Member 3's four controller steps and its proof of simultaneous fetch/read, fetch/write and later readback. Review Member 4's single array and address selection, grant accounting, fair workload and measured cycle count. Review Member 5’s direct Harvard tests for same-address isolation, independent fetch during a rejected write, and reset preserving data. Give feedback tied to the relevant file or waveform edge. Fix issues in my integration files and hand each other issue back to its owner.

After dependencies land, run make test-instruction, make test-data, make test-harvard, make test-harvard-directed and make test-comparison from a fresh clone. Prepare the final IEEE report using the verified evidence, then hand the PDF and editable source to Member 5 to commit. Review docs/harvard-waveform.png and docs/comparison-waveform.png against the regenerated traces. Check the five Git authors, the final report PDF and the video link. Give me a short list of any blockers before I submit the GitHub link.
```

## Member 2 — Data path

```text
I am Member 2 on feature/data-path. Implement rtl/address_decoder.v, rtl/read_write_control.v, rtl/data_memory.v, rtl/data_path.v, and testbench/tb_data_path.v. Keep data_path's public ports exactly as specified in docs/interfaces.md.

Design the decoder to split address[4:0] into a valid-range signal and address[3:0]. Bit 4 must reject accesses to words 16–31. In read_write_control, generate qualified read and write signals from the raw enables, address validity and !reset. When both raw enables are high, suppress both operations. In data_memory, use a single 16 by 16 array. Set initial words 0–3 to decimal 10, 20, 5, 0 and all other words to zero. Make reads combinational and gated by the qualified read. Commit writes on the rising edge only when the qualified write is high. Preserve array contents through reset. Wire the modules together and set data_valid when either qualified enable is active. Ensure read_data is zero when no read is accepted, including a legal write.

Create an independent testbench named tb_data_path. Read the initialized words and check validity. Write a distinct value to address 15 and read it back. Try reads and writes at 16 and 31 and assert that validity and read data are zero. Then check words 0 and 15 again to catch alias corruption. Try simultaneous read and write at a legal address, verify no operation is accepted, then read back the previous value. Test idle and test reset with a write requested. Verify contents survive reset and the blocked write left no side effect. Have the test print PASS only after every check succeeds.

Run make test-data. Summarize the files, the exact PASS output and the edge on which a write commits. My evidence is the unit test and its result in the PR. Member 3 owns the integrated Harvard screenshot.
```

## Member 3 — Controller and Harvard waveform

```text
I am Member 3 on feature/controller-simulation. Implement rtl/controller.v, testbench/tb_harvard.v and docs/controller.md. I am responsible for capturing and committing docs/harvard-waveform.png after my integrated test passes.

Use a small FSM with idle, four request states and done. Reset returns to idle and suppresses request outputs. Accept a one-cycle start pulse in idle. Each request state lasts one cycle and asserts fetch_enable. In step 1 read data word 2. In step 2 write decimal 10 to data word 3. In step 3 read data word 1. In step 4 read data word 3. Assert done for one cycle after step 4 and go back to idle. Set defined defaults on every combinational output. Keep the output ports exactly as listed in the interface contract.

In tb_harvard, connect the controller and Harvard top with named ports. Reset, pulse start away from the rising edge and verify idle outputs before the workload. At each active cycle check the PC (0, 1, 2, 3), ROM output (1002, 2001, 3003, F000 in hex), both valid flags, data address and the single intended data enable. Check read data of decimal 5, 20, and 10 on the read steps. Check write_data is 10 and read_data is zero during the write. Verify PC reaches 4 after the last edge, done lasts one cycle and PC holds when idle. Include reset coverage and a finite timeout. Write build/harvard.vcd with $dumpfile and $dumpvars. Name the testbench tb_harvard so the Makefile target works.

While waiting for Member 2, compile controller.v independently with the command in docs/member-work.md. After merging the data dependency, run make test-harvard and inspect the generated VCD in Surfer or GTKWave. Help me select the signal rows and zoom to the four requests. I will capture the real waveform with names and values visible and save it at docs/harvard-waveform.png. Explain which edges show fetch/read and fetch/write, and point out the later readback. Put the state sequence, PASS result and screenshot interpretation in docs/controller.md. If the GUI is unavailable, give me the exact local steps and leave the image pending until I can capture it.
```

## Member 4 — Shared-memory baseline, comparison and synthesis

```text
I am Member 4 on feature/shared-memory. Implement rtl/shared_memory.v, testbench/tb_comparison.v, docs/comparison.md and synthesis/results.md. I capture and commit docs/comparison-waveform.png.

Give shared_memory the same ports as harvard_top. Reuse program_counter. Use one 32 by 16 array and one selected word address, with one shared array read expression. Map PC to physical addresses 0–15 and a legal data address to 16–31. Match both architectures' initial values. Grant data first when exactly one data enable is set, the data address is legal and reset is low. If data wins, hold the PC and keep instruction_valid low. If data does not win and fetch is requested out of reset, grant the fetch and advance the PC on its rising edge. Grant signals must represent accepted operations. Only an accepted write updates memory. Preserve memory through reset. Gate read outputs using their corresponding grant and request type.

In tb_comparison, instantiate both DUTs and give each the same four fetch and data request pairs from the interface contract. Use separate row counters and pending bits for each DUT so one cannot stall the other. On each rising edge, count grants and complete only the requests that were granted. Keep a denied fetch pending. After both requests in a row complete, present the next pair. Check each granted instruction, the expected read data and the final readback. Assert eight grants per DUT. Check the shared PC holds during contention and advances when the held fetch completes. After the measured run, separately check that invalid data does not consume the fetch slot. Use a timeout and dump build/comparison.vcd.

Compile the shared baseline independently while Member 2 is working. Once Member 2's data path is available, run make test-comparison. Count cycles from the first request edge to the final grant, including contention cycles and excluding reset and setup. Expected values are four cycles for Harvard and eight for shared memory under this workload. Record observed counts and calculate operations per cycle and their ratio. Explain any discrepancy from expected counts before using the numbers in the report.

Use a waveform viewer to show both DUTs on the same time scale. Include both fetch requests, data enables, both grant signals for each DUT, PC and clock. Identify the edge where Harvard grants both and the baseline grants data only, plus the later edge completing the baseline fetch. Give me the capture steps so I can save the real image as docs/comparison-waveform.png.

Run the matched Yosys synthesis commands in docs/member-work.md if the tool is available. Record the tool version, commands, counts and relevant warnings in synthesis/results.md. If a named FPGA target and timing tools are available, use implementation timing for the target's Fmax. Record unfinished synthesis or timing work as pending. Give Anshuman the measured results, conditions, waveform and PR for the report. Give Member 5 the waveform for the video.
```

## Member 5 — Direct Harvard tests, report commit and demo

```text
I am Member 5. My technical branch is feature/harvard-directed-tests. Implement testbench/tb_harvard_directed.v. Read docs/interfaces.md and the Member 5 test table in docs/member-work.md. The Makefile already has test-harvard-directed. Instantiate harvard_top directly with named ports and drive its request inputs from the testbench. Member 2’s data path is the only teammate RTL dependency. Keep the controller demo, baseline RTL and other members’ testbenches in their owners’ files.

Start with reset, then check a fetch-only cycle at PC 0. With fetch enabled and both data enables low, check instruction 1002 in hex, instruction_valid high, data_valid low and read_data zero. Check that PC advances to 1. Then disable fetch and write decimal 42 to RAM word 1 while PC is 1. Check the accepted write and zero read output, read the word back, and confirm PC stays 1, instruction output stays hex 2001 and instruction_valid stays low. This case tests that a RAM write at the same numerical address does not change the ROM word.

Next, request fetch and a write of 99 to invalid data address 17. Check that the fetch proceeds and advances PC to 2 while the write is rejected. Read RAM word 1 back to check it still contains 42. Finally assert reset with fetch and a write of 123 to legal RAM word 1. Verify both valid flags go low and the PC resets to 0 on the clock edge. After releasing reset, read RAM word 1 and verify it still contains 42.

Drive inputs at falling edges, check settled grants and combinational values before the accepting edge, and check PC and committed data afterward. Use case inequality and $fatal(1, ...) with specific messages. Print PASS once all cases complete. If a debug VCD helps, save it to build/harvard_directed.vcd. Run make test-harvard-directed once Member 2’s data path is in my branch. Give me the commands to commit the testbench and open the PR with the actual test result. I will send Anshuman my PR link and a short explanation for the report. Members 3 and 4 own the two submission screenshots.

For the final handoff, Anshuman prepares the report and gives me the PDF and editable source. After I receive them, help me create docs/report-demo from current main, verify the supplied PDF opens and its figures and names are legible, and stage it as docs/IEEE_Project_Report.pdf with the source under docs/report/. Flag content issues for Anshuman. Help me coordinate the prototype video using docs/demo.md, including my explanation of the direct test. I will arrange recording and upload. Add the working video URL to README.md and give me the Git commands to commit and push the report and video PR from my own account.
```
