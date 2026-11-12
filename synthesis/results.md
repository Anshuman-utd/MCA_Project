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

## FPGA Implementation and Timing Status

- **Status:** Generic standard cell gate-level counts are recorded above. Target-specific FPGA device utilization (LUTs, BRAMs, DSP slices) and maximum operating frequency ($F_{\max}$) remain **pending** target FPGA hardware selection and vendor place-and-route constraints.
