# Instruction and Data Memory Hierarchy

MCA Phase I prototype for comparing a Harvard memory subsystem with a single-port shared-memory baseline. The instruction and data memories can each accept one operation per cycle in the Harvard design. The team will measure how many cycles both designs take on the same workload.

## Start here

- [Phase I plan, ownership and submission checklist](docs/phase1-plan.md)
- [Architecture block diagram](docs/architecture.md)
- [Signal interfaces and test workload](docs/interfaces.md)
- [Step-by-step member work and screenshot ownership](docs/member-work.md)
- [Copy-paste coding agent prompts for all five members](docs/team-prompts.md)
- [Branch, commit, push and review commands for each member](docs/git-workflow.md)
- [Report and video handoff](docs/demo.md)

## Run locally

Install [Icarus Verilog](https://steveicarus.github.io/iverilog/) and GNU Make. On macOS use `brew install icarus-verilog`. On Debian or Ubuntu use `sudo apt install iverilog make`. On Windows, the same Linux commands work in Ubuntu under WSL.

From the repository root:

```sh
make test-instruction
```

The instruction-path smoke test checks reset, hold, ROM contents, increment and wraparound. Its VCD is `build/instruction_path.vcd`. Open the file in GTKWave or another VCD viewer.

Run the remaining targets as the matching member branches are merged:

```sh
make test-data
make test-harvard
make test-harvard-directed
make test-comparison
```

The integrated top depends on Member 2's data path. Member 3 owns the controller-driven Harvard demo. Member 5 owns the direct top-level checks, which need Member 2’s data path. The shared-memory RTL and comparison testbench come from Member 4.

## GitHub workflow

Member 1 publishes the starter on `main` and invites the other four members. Each teammate works in their own clone, pushes their assigned branch and opens a pull request into `main`. The [Git guide](docs/git-workflow.md) gives each person the exact commands.

Member 3 commits `docs/harvard-waveform.png`. Member 4 commits `docs/comparison-waveform.png`. See the [waveform capture steps](docs/member-work.md#how-to-capture-and-commit-the-two-screenshots).

## Prototype video

Member 5 adds the viewable video link here after upload. Anshuman prepares the final report from the team’s verified results and hands the source and PDF to Member 5 to commit.
