# Phase I work plan

The deadline from the course notice is **16 November 2026 at 11:59 PM IST**. Aim to submit on 15 November.

## What we are building

A 16-word × 16-bit instruction ROM and a separate 16-word × 16-bit data RAM. A four-bit program counter steps on accepted fetches. The Phase I controller issues a fixed sequence of fetch, read and write requests. The ROM words are sample values for checking the fetch path. A separate 32-word × 16-bit single-port baseline shares one access per cycle between instruction and data regions.

The common requirements include a block diagram, state or timing description, synthesizable RTL, directed tests, waveform evidence, a measured metric, a baseline comparison, synthesis utilization and maximum operating frequency. Aim to include preliminary comparison and synthesis evidence in Phase I. Check with the instructor if target-specific timing is unavailable. For Phase II, complete the final report and results, target-specific utilization and timing, and prepare for the live demo and interview. A tiny instruction decoder is an optional extension once the memory evaluation is complete.

## Owners and merge order

Use the [member work guide](member-work.md), [agent prompts](team-prompts.md) and [Git commands](git-workflow.md) for the full handoff.

| Owner | Work | Files and evidence |
| --- | --- | --- |
| 1 — Anshuman (assumed) | Architecture, PC, instruction ROM, integration, interface review and final report preparation | `rtl/program_counter.v`, `rtl/instruction_memory.v`, `rtl/harvard_top.v`, `testbench/tb_instruction_path.v`, `docs/interfaces.md`, `docs/architecture.md`, starter Makefile and final report handoff to Member 5 |
| 2 — assign name | Data address decoding, read/write qualification, RAM and unit tests | `rtl/data_path.v`, `rtl/address_decoder.v`, `rtl/read_write_control.v`, `rtl/data_memory.v`, `testbench/tb_data_path.v` |
| 3 — assign name | Scripted request controller, full Harvard testbench, waveform capture | `rtl/controller.v`, `testbench/tb_harvard.v`, `docs/controller.md`, `docs/harvard-waveform.png` |
| 4 — assign name | Single-port RTL, arbitration, same-workload comparison and synthesis | `rtl/shared_memory.v`, `testbench/tb_comparison.v`, `docs/comparison.md`, `docs/comparison-waveform.png`, `synthesis/results.md` |
| 5 — assign name | Direct Harvard integration tests, report commit and video | `testbench/tb_harvard_directed.v`, Anshuman’s final PDF at `docs/IEEE_Project_Report.pdf`, editable source under `docs/report/`, video link in `README.md` |

Publish the starter first. Members 2–5 branch from it. Merge Member 2 before running Member 3's full-system tests on main. Member 4 can develop the shared port and its checks independently, then run the comparison once Member 2 is merged. Member 5 develops the direct Harvard tests in parallel and runs them after Member 2 merges. Anshuman prepares the final report from verified evidence. Member 5 commits the PDF and source in a follow-up PR. Use the starter Makefile targets as written. Discuss any port change with affected owners before merging.

## Schedule

| Date (IST) | Finish by end of day |
| --- | --- |
| Nov 11 | Publish starter, add collaborators, assign names and confirm interfaces. |
| Nov 12 | Finish RAM tests and controller stimulus. Start the shared port and direct Harvard tests. Collect references and member details for Anshuman. |
| Nov 13 | Run the integrated Harvard tests, capture the waveform, and run the matched workload on both designs. Run the direct Harvard tests and start synthesis. |
| Nov 14 | Anshuman finishes the report with verified results and hands it to Member 5 to commit. Record and upload the video. |
| Nov 15 | Test a fresh clone, check report and video access, and submit the repository link. |
| Nov 16 | Deadline buffer. |

## Submission checklist

- [ ] IEEE-format PDF (10 marks) includes Abstract, Literature Review, Proposed Solution, Individual Contributions and References. Include the block diagram, controller timing, and verified measurements available at submission.
- [ ] Prototype video (15 marks) runs at most 5 minutes, states the idea, names all five members and shows working RTL and simulation progress.
- [ ] Member 5’s `make test-harvard-directed` passes from a fresh clone.
- [ ] Member 3 committed `docs/harvard-waveform.png`. Member 4 committed `docs/comparison-waveform.png`. Both images match the regenerated traces.
- [ ] GitHub repo (5 marks) contains the PDF, accessible video link, RTL, testbenches and relevant evidence. Each person pushes meaningful commits from their own GitHub account. Review the authors in the merged history.
- [ ] Record FPGA device, tool, clock constraints, utilization and timing method for any timing result. Label generic Yosys counts as generic cell counts. Use routed timing on a named device for an Fmax claim.
- [ ] Test the repository and video links with the evaluator's expected access and submit the [course form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform).
