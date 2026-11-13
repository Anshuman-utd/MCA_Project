# Instruction and Data Memory Hierarchy

MCA Phase I prototype comparing a Harvard memory subsystem with a single-port shared-memory baseline. The Harvard design has a 16-word instruction ROM and a separate 16-word data RAM. The baseline uses one 32-word memory with data-priority arbitration. Each word is 16 bits.

## Run the prototype

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and GNU Make. On macOS, use `brew install icarus-verilog`. On Debian, Ubuntu or Ubuntu under WSL, use `sudo apt install iverilog make`.

From the repository root:

```sh
make test-instruction test-data test-harvard test-harvard-directed test-comparison
```

The tests check the instruction path, data path, controller-driven workload, Harvard edge cases, and shared-port comparison. Each test prints a PASS result and writes a VCD under `build/`. Open `build/harvard.vcd` or `build/comparison.vcd` in Surfer or GTKWave to inspect the main demo traces.

On the four-pair benchmark, both designs accept eight operations. Harvard completes them in **4 cycles (2.00 ops/cycle)** and shared memory in **8 cycles (1.00 op/cycle)**.

## Design and evidence

- [Architecture diagram](docs/architecture.md) and [interface and timing contract](docs/interfaces.md)
- [Controller states and verification](docs/controller.md) and [Harvard waveform](docs/harvard-waveform.png)
- [Benchmark results](docs/comparison.md) and [Surfer comparison waveform](docs/comparison-waveform-surfer.png)
- [Generic synthesis and ECP5 post-route timing results](synthesis/results.md)

## Phase I submission

- [IEEE Phase I project report](docs/IEEE_Project_Report.pdf) · [Editable LaTeX source](docs/report/IEEE_Project_Report.tex)
- [Report and demo checklist](docs/demo.md)

### Prototype video

Pending upload.

## Team

| Member | Contribution |
| --- | --- |
| Anshuman Mehta | Architecture, instruction path, integration, FPGA timing, and report preparation |
| Rudraksh | Data path and its unit tests |
| Vridhi Chaudhary | Controller, Harvard integration test, and waveform |
| Bineet Keshari | Shared-memory baseline, comparison, waveform, and generic synthesis |
| Shrijan Sanidhya | Directed Harvard verification and report and video handoff |
