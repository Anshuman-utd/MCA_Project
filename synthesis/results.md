# Phase I Synthesis and Implementation Results

## Tool Environment

- **Synthesis Tool:** Yosys Open SYnthesis Suite (Version 0.70+post, AppleClang `clang++ 21.0.0.21000334`)
- **Simulation Tool:** Icarus Verilog (`iverilog` version 12.0) / `vvp`
- **Target Technology:** Generic standard cell gate-level representation (`synth -top <top_module>`)
- **Platform:** macOS (Darwin arm64, Apple Silicon)

---

## Synthesis Commands

### 1. Shared-Memory Baseline (`shared_memory`)
```sh
yosys -p 'read_verilog rtl/program_counter.v rtl/shared_memory.v; synth -top shared_memory; stat'
```

### 2. Harvard Top-Level (`harvard_top`)
*(Note: Complete synthesis of `harvard_top` depends on Member 2's `data_path.v` and submodules merging into `main`)*
```sh
yosys -p 'read_verilog rtl/program_counter.v rtl/instruction_memory.v rtl/address_decoder.v rtl/read_write_control.v rtl/data_memory.v rtl/data_path.v rtl/harvard_top.v; synth -top harvard_top; stat'
```

---

## Resource Utilization Summary

### Shared-Memory Baseline (`shared_memory`)

| Cell Type | Function / Description | Cell Count |
| :--- | :--- | :--- |
| `$_DFFE_PP_` | D-Type Flip-Flop with Enable (Unified 32×16 RAM array) | 512 |
| `$_SDFFE_PP0P_` | Synchronous Reset DFF with Enable (4-bit Program Counter) | 4 |
| **Total Sequential (DFFs)** | | **516** |
| `$_MUX_` | Multiplexers (Address decoding & single read port selection) | 452 |
| `$_AND_` | 2-input AND gates | 121 |
| `$_OR_` | 2-input OR gates | 48 |
| `$_ANDNOT_` | AND with inverted input | 34 |
| `$_NAND_` | 2-input NAND gates | 33 |
| `$_NOT_` | Inverters | 7 |
| `$_XOR_` | 2-input XOR gates | 3 |
| `$_NOR_` | 2-input NOR gates | 2 |
| `$_XNOR_` | 2-input XNOR gates | 1 |
| **Total Combinational Logic** | | **701** |
| **Total Cell Count** | | **1,217** |

#### Hierarchy Breakdown:
- **`shared_memory` (Local Count):** 1,207 cells (512 DFFs for RAM array, 452 MUXes, 243 logic gates)
- **`program_counter` (Submodule):** 10 cells (4 SDFFEs for 4-bit PC, 6 logic gates for increment and reset)

### Harvard Subsystem (`harvard_top`)
- **Status:** Pending integration of Member 2 (`feature/data-path`).
- Expected resources:
  - 16×16 Data RAM: ~256 DFFs
  - 16×16 Instruction ROM: Combinational LUT ROM (~0 DFFs)
  - 4-bit PC: 4 DFFs
  - Dual independent address paths and dual read outputs without shared multiplexer contention.

---

## Timing and FPGA Implementation

- **FPGA Target & Fmax:** Pending target FPGA device selection and place-and-route constraints. For Phase I, standard cell generic elaboration confirms zero design rule violations, clean synchronous reset behavior, and zero latch inferences.
- **Synthesis Warnings:** None affecting design intent or functional behavior. All latch inferences were cleanly prevented through default combinational assignments.
