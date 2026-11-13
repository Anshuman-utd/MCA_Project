# Phase I report and video

## Report handoff

Anshuman prepares the final report from the team’s verified evidence and gives the editable source and exported PDF to Member 5. Member 5 verifies the files and commits the source under `docs/report/` and the PDF as `docs/IEEE_Project_Report.pdf`. Use the [IEEE conference template](https://www.ieee.org/conferences/publishing/templates.html). Include the five required sections:

- Abstract with the design objective and the prototype's verified scope.
- Literature Review with numbered citations from sources the team has actually read.
- Proposed Solution with the block diagram, ROM and RAM organization, controller state sequence, clock-edge timing, and shared-port arbitration. Add available measured results and the conditions under which they were obtained.
- Individual Contributions with all five names and each person's actual work. Each teammate supplies the relevant files, pull request and a short technical explanation. Credit Anshuman for the FPGA timing run and report preparation. Credit Member 4 for the shared-memory benchmark and generic synthesis. Credit Member 5 for the direct Harvard tests, report commit and completed video work.
- References in IEEE order of first citation. Verify edition and publication details for any textbook used.

Use Member 3's `docs/harvard-waveform.png` and Member 4's `docs/comparison-waveform-surfer.png` for the prototype evidence. Use the measured Harvard and baseline grant counts to compute operations per cycle. Include the ECP5 device, post-route Fmax, resource counts, and I/O assumptions from the [synthesis and timing results](../synthesis/results.md).

## Prototype video script

**Target runtime is 4:40. The submission limit is 5:00.** Anshuman opens, then Rudraksh, Vridhi, Bineet, and Shrijan speak in that order. Anshuman introduces the entire team in the opening. Each person says their own name when their segment begins. Read the blockquotes aloud and use the other lines as screen directions.

| Video time | Speaker | What the evaluator sees |
| --- | --- | --- |
| 0:00–0:55 | Anshuman Mehta | Project title, five names, block diagram, PC and instruction ROM |
| 0:55–1:38 | Rudraksh | Address decoder, read/write control, RAM, and passing data-path test |
| 1:38–2:49 | Vridhi Chaudhary | Controller states, integrated test, and fetch/read, fetch/write, and readback on the waveform |
| 2:49–3:51 | Bineet Keshari | Shared-port arbiter, held fetch, and measured comparison |
| 3:51–4:40 | Shrijan Sanidhya | Directed test, ECP5 timing table, report, and close |

### Set up before recording

1. Use the same project revision for all clips. Open the terminal in the repo root and rehearse the commands below. Use `make -B` for each recorded test so the terminal shows the actual compile and run.
2. Open the [report PDF](IEEE_Project_Report.pdf) to the title and block diagram. Open each RTL or testbench file at the lines the speaker will point to. Have the [timing table](../synthesis/results.md#ecp5-post-route-timing-and-utilization) ready in a browser or editor preview.
3. Pre-open the [Harvard waveform](harvard-waveform.png) and [comparison waveform](comparison-waveform-surfer.png). Both images are ready to show. If using a viewer, generate `build/harvard.vcd` and `build/comparison.vcd` in rehearsal and arrange the signal rows before recording. Zoom so the request signals, valid flags, values, and edge labels are readable on video.
4. Record five clips in landscape, ideally at 1080p, using a readable terminal and editor font. Use a short on-screen name label at each handoff. Cut after each handoff sentence and start the next clip with the next person's name. Use the timestamps as editing targets. Rehearse the full sequence once and time the final export.

### 0:00–0:55 · Anshuman Mehta · Opening and architecture

**0:00–0:23.** Show the report title and author line. Keep all five names visible while reading them.

> Hello, I’m Anshuman Mehta. This is our MCA Phase One project, Instruction and Data Memory Hierarchy. Our team is Anshuman Mehta, Rudraksh, Vridhi Chaudhary, Bineet Keshari, and Shrijan Sanidhya. We built a Verilog prototype to see how separate instruction and data paths handle simultaneous requests.

**0:23–0:55.** Zoom into the block diagram. Trace the PC arrow into the ROM, then point to the independent data path. Briefly show `rtl/harvard_top.v` with the PC, ROM, and data path instances in view.

> I designed the architecture, built the program counter and instruction ROM, and integrated the Harvard top. The four-bit counter selects one of sixteen ROM words and advances on each accepted fetch. A separate sixteen-word RAM handles data. Both memories use sixteen-bit words. The two paths can accept requests on the same rising edge. Rudraksh will show how we qualify data accesses.

### 0:55–1:38 · Rudraksh · Data path

**0:55–1:18.** Start on `rtl/address_decoder.v`, pointing to the upper address bit check. Switch to `rtl/read_write_control.v` and point to the mutually exclusive enables. Show the clocked write in `rtl/data_memory.v`.

> I’m Rudraksh. I implemented the address decoder, read and write control, and data RAM. The lower four address bits select a word. The upper bit rejects addresses outside zero to fifteen. We accept exactly one of read or write while reset is low. Reads return data combinationally. Writes update RAM on the rising edge, and reset preserves stored values.

**1:18–1:38.** Run the command and leave the PASS line visible.

```sh
make -B test-data
```

> This unit test checks write and readback, invalid addresses, conflicting enables, and reset. The PASS line confirms that those checks succeeded. Vridhi will now run the full Harvard prototype.

### 1:38–2:49 · Vridhi Chaudhary · Controller and Harvard waveform

**1:38–1:56.** Show the state transitions in `rtl/controller.v`. Point from `IDLE` through the four active states to `DONE`.

> I’m Vridhi Chaudhary. I wrote the controller and the Harvard integration test. A start pulse triggers four request states. Each state issues a fetch alongside one data operation. After the fourth pair, the controller raises done for one cycle.

**1:56–2:08.** Run the test. Pause briefly on the PASS line and the path to the generated VCD.

```sh
make -B test-harvard
```

> The test passes and generates this waveform. I’ll use three rising edges to show the overlap and confirm the write.

**2:08–2:49.** Show `docs/harvard-waveform.png` or the equivalent live VCD. Point first to `clk`, `instruction_valid`, and `data_valid`, then to the read/write enable and data rows. The screenshot labels time in **picoseconds**. Use **45,000**, **55,000**, and **75,000 ps** when moving the cursor. Point just to the left of each edge for the values accepted there.

> At forty-five nanoseconds, both valid signals are high. The instruction fetch completes while RAM word two returns five. At fifty-five nanoseconds, the next fetch overlaps a write of ten to RAM word three. At seventy-five nanoseconds, the final fetch overlaps a read of word three. The value is ten, so we can see that the write took effect. The program counter reaches four and done rises. Bineet will compare this with a single shared port.

### 2:49–3:51 · Bineet Keshari · Shared-memory baseline and comparison

**2:49–3:07.** Show `rtl/shared_memory.v` at the grant logic and address selection. Point out that the instruction and data requests share one selected address.

> I’m Bineet Keshari. I implemented the shared-memory baseline and the comparison test. The baseline stores instructions and data in two regions of one array. When both requests arrive together, a valid data request gets the port and the program counter holds until the fetch is granted.

**3:07–3:31.** Show `docs/comparison-waveform-surfer.png`. The Surfer time axis is in picoseconds. Point at both sets of grant rows at **25,000 ps (25 ns)**, then at the shared fetch grant and PC transition at **35,000 ps (35 ns)**.

> At twenty-five nanoseconds, Harvard grants both requests. The shared design grants only data and its program counter stays at zero. At thirty-five nanoseconds, the shared port grants the waiting fetch and its program counter advances.

**3:31–3:51.** Run the benchmark. Keep both result lines visible side by side or in the same terminal view.

```sh
make -B test-comparison
```

> Both designs complete the same eight operations. Harvard takes four cycles and shared memory takes eight. That’s two versus one operation per cycle for this workload. Shrijan will close with the isolation test and timing results.

### 3:51–4:40 · Shrijan Sanidhya · Directed checks, timing, and close

**3:51–4:17.** Show `testbench/tb_harvard_directed.v` at the case that writes 42 to data word 1 while the PC is at 1. Point to the readback of 42 and the check that the ROM word stays unchanged. Run the test.

```sh
make -B test-harvard-directed
```

> I’m Shrijan Sanidhya. I wrote the direct Harvard tests. Writing forty-two to RAM word one leaves instruction word one and the program counter unchanged. The tests also confirm that invalid writes leave fetches free to proceed and that reset preserves RAM. All checks pass.

**4:17–4:40.** Show the timing table and highlight the 50 MHz PASS row for both designs. Switch to the README or report title page for the closing sentence. Show the actual report and video links in the README only if they are already available when recording.

> Anshuman ran the FPGA timing comparison. Both designs met the fifty-megahertz target on the same Lattice ECP5 device. The table shows the post-route estimates for the internal clock. Our repository contains the report, RTL, tests, and waveforms. Thank you.

### Final edit and upload

- Make sure the title and all five names are visible and spoken, every member has a technical segment, and the final cut shows a running test plus both waveforms. Check that the waveform times are in the right units and the benchmark output is readable.
- Leave the PASS lines on screen long enough to read. If rehearsal runs long, cut loading and scrolling, or shorten the RTL explanations. Keep the opening names, the overlap, the held fetch, and the measured cycle counts.
- Export one video at or below **5:00**. Shrijan uploads it, verifies that the evaluator can open it, and adds the working link under **Prototype video** in the README.

## Submission checklist

- [ ] Add the IEEE-format PDF to `docs/IEEE_Project_Report.pdf`. Include the abstract, literature review, proposed solution, individual contributions, and references.
- [ ] Add the video link to the README. Confirm that the video opens with the evaluator’s access and lasts at most five minutes.
- [ ] From a fresh clone, run the five Make targets listed in the README. Confirm that the block diagram, two waveform images, benchmark results, and synthesis results are visible in the repository.
- [ ] Confirm that the merged Git history shows all five members’ technical contributions.
- [ ] Submit the GitHub repository URL by **November 16, 2026 at 11:59 PM IST**. [Course submission form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform)
