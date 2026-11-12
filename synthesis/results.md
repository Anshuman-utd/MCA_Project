# Phase I Synthesis and Implementation Results

## Tool Environment

- **Synthesis Tool:** Yosys Open SYnthesis Suite (Version `0.70+post`, commit `0c11ea098be065e585a90a06e7b7da49936cf231`, AppleClang `clang++ 21.0.0.21000334`)
- **Simulation Tool:** Icarus Verilog (`iverilog` version 12.0) / `vvp`
- **Target Technology:** Generic standard cell gate-level representation (`synth -top <top_module>; stat`)
- **Platform:** macOS (Darwin arm64, Apple Silicon)

---

## Synthesis Commands

### 1. Shared-Memory Baseline (`shared_memory`)
```sh
yosys -p 'read_verilog rtl/program_counter.v rtl/shared_memory.v; synth -top shared_memory; stat'
```

### 2. Harvard Subsystem (`harvard_top`)
```sh
yosys -p 'read_verilog rtl/program_counter.v rtl/instruction_memory.v rtl/address_decoder.v rtl/read_write_control.v rtl/data_memory.v rtl/data_path.v rtl/harvard_top.v; synth -top harvard_top; stat'
```

---

## Resource Utilization Comparison (Generic Yosys Cell Counts)

The table below presents the **hierarchy-inclusive cell totals** for both architectures synthesized under identical settings with Yosys:

| Cell Type / Category | Description | Shared-Memory Baseline (`shared_memory`) | Harvard Subsystem (`harvard_top`) | Notes on Difference |
| :--- | :--- | :---: | :---: | :--- |
| `$_DFFE_PP_` | D-type Flip-Flop with Enable | 512 | 256 | Shared memory implements unified 32×16 RAM (512 FFs); Harvard has 16×16 RAM (256 FFs) |
| `$_SDFFE_PP0P_` | Synchronous Reset DFF with Enable | 4 | 4 | 4-bit Program Counter (`program_counter`) |
| **Total Sequential (DFFs)** | **Total Registers** | **516** | **260** | **Shared memory requires 2.0× more flip-flops** |
| `$_MUX_` | Multiplexers | 452 | 241 | 32-word array read multiplexing vs 16-word RAM read multiplexing |
| `$_AND_` | 2-input AND gates | 121 | 45 | Address decode, control qualification, write gating |
| `$_OR_` / `$_ORNOT_` | OR gates | 48 | 2 | Request arbitration and qualification |
| `$_ANDNOT_` | AND with inverted input | 34 | 9 | Priority suppression and gating |
| `$_NAND_` | 2-input NAND gates | 33 | 5 | Combinational decoding |
| `$_NOT_` | Inverters | 7 | 7 | Address bit inversion and logic inversion |
| `$_XOR_` / `$_XNOR_` | XOR / XNOR gates | 4 | 3 | PC incrementer and control XOR |
| `$_NOR_` | 2-input NOR gates | 2 | 1 | Logic gating |
| **Total Combinational Cells** | **Logic & MUX Gates** | **701** | **313** | **Shared memory requires 2.24× more combinational gates** |
| **Total Generic Cells** | **Overall Cell Count** | **1,217** | **573** | **Hierarchy-inclusive total** |

---

## Architectural Hierarchy Breakdown

### 1. Shared-Memory Baseline (`shared_memory`) — 1,217 Total Cells
- **`shared_memory` (Local Count):** 1,207 cells
  - 512 `$_DFFE_PP_` (Unified 32×16 memory storage)
  - 452 `$_MUX_` (Address decode and single shared read expression)
  - 243 combinational gates (Priority arbiter, address range validation, grant gating)
- **`program_counter` (Submodule):** 10 cells
  - 4 `$_SDFFE_PP0P_` (4-bit program counter)
  - 6 combinational gates (Increment and synchronous reset)

### 2. Harvard Subsystem (`harvard_top`) — 573 Total Cells
- **`harvard_top` (Local Count):** 1 cell
  - 1 `$_ANDNOT_` (Fetch valid qualification: `instruction_valid = fetch_enable && !reset`)
- **`data_path` Subsystem:** 552 cells
  - **`address_decoder`:** 1 cell (1 `$_NOT_` for upper address bit validity check)
  - **`read_write_control`:** 5 cells (3 `$_ANDNOT_`, 2 `$_AND_` for operation qualification)
  - **`data_memory`:** 545 cells (256 `$_DFFE_PP_` for 16×16 RAM, 240 `$_MUX_`, 49 logic gates)
  - **`data_path` top-level wiring:** 1 cell (1 `$_OR_` asserting `data_valid`)
- **`instruction_memory` Submodule:** 10 cells
  - 10 combinational LUT gates (Hardwired 16×16 instruction ROM; 0 flip-flops required)
- **`program_counter` Submodule:** 10 cells
  - 4 `$_SDFFE_PP0P_` (4-bit program counter)
  - 6 combinational gates (Increment and synchronous reset)

---

## Synthesis Warnings and Quality Assessment

- **Warnings:** Zero unexpected warnings. Both frontends cleanly elaborated Verilog-2005 constructs without syntax warnings.
- **Latch Prevention:** Verified zero latch inferences across both designs (`CHECK pass: Found and reported 0 problems`). All switch rules were recognized as full-case decision trees.
- **Clock Domains:** Both subsystems operate on a single synchronous clock domain (`clk`) with synchronous active-high resets (`reset`).

---

## ECP5 post-route timing and utilization

Both memory subsystems were synthesized and routed for the **Lattice ECP5 LFE5U-25F**, package **CABGA381**, speed grade **6**. The clock target was **50 MHz** (20 ns) with placement seed **1**. This run used YoWASP builds of Yosys **0.70** (`28ba3cb92`) and nextpnr-ecp5 **0.11.1** on the RTL from `dddcc0e`. The table uses the final post-route values. [YoWASP toolchain](https://yowasp.org/) · [nextpnr clock constraints](https://github.com/YosysHQ/nextpnr/blob/main/docs/constraints.md)

| Post-route metric | Harvard (`harvard_top`) | Shared memory (`shared_memory`) |
| --- | ---: | ---: |
| 50 MHz clock constraint | Pass | Pass |
| Internal `clk` Fmax | 541.13 MHz | 314.07 MHz |
| Longest same-clock path | 1.85 ns | 3.18 ns |
| Longest input-to-output path | 8.20 ns | 10.35 ns |
| Combinational sites (`TRELLIS_COMB`) | 69 | 104 |
| Flip-flops (`TRELLIS_FF`) | 4 | 4 |
| Distributed RAM write sites (`TRELLIS_RAMW`) | 4 | 8 |
| Block RAMs (`DP16KD`) | 0 | 0 |
| I/O sites (`TRELLIS_IO`) | 64 | 64 |

In this placement, the Harvard clock path runs through the PC increment logic. The shared-memory clock path runs from the PC to the distributed RAM write-address logic. Both designs use distributed FPGA RAM. The generic counts above use a different mapping that represents RAM with flip-flops and multiplexers.

The I/O pins were assigned by nextpnr without board pin or external timing constraints. The Fmax values cover the internal clock paths for these routed implementations. Board-level operation and I/O timing require board-specific constraints and validation. The simulation comparison independently measures eight requests completing in four versus eight cycles. [nextpnr ECP5 I/O handling](https://github.com/YosysHQ/nextpnr/blob/main/ecp5/main.cc)

Raw nextpnr reports are available for [Harvard](harvard_top-report.json) and [shared memory](shared_memory-report.json).

### Reproduce the FPGA run

From the repository root, create the tool environment and run both designs with the same settings. The JSON netlists, reports, and logs are generated under `build/timing/`.

```sh
uv --no-cache venv --no-project build/fpga-tools
uv --no-cache pip install --python build/fpga-tools/bin/python \
  yowasp-yosys==0.70.0.0.post1259 yowasp-nextpnr-ecp5==0.11.1.0.post826

mkdir -p build/timing
export YOWASP_CACHE_DIR="$PWD/build/fpga-cache"
for top in harvard_top shared_memory; do
  build/fpga-tools/bin/yowasp-yosys -Q -q -l "build/timing/$top-synth.log" \
    -p "read_verilog rtl/*.v; synth_ecp5 -top $top -json build/timing/$top.json" &&
  build/fpga-tools/bin/yowasp-nextpnr-ecp5 \
    --25k --package CABGA381 --speed 6 --freq 50 --seed 1 \
    --lpf-allow-unconstrained --json "build/timing/$top.json" \
    --report "build/timing/$top-report.json" > "build/timing/$top-route.log" 2>&1 || break
done
```
