# Harvard memory subsystem

```mermaid
flowchart LR
    C["Scripted request controller"]
    PC["4-bit program counter"]
    ROM["16 × 16-bit instruction ROM"]
    CTRL["Address decoder and read/write control"]
    RAM["16 × 16-bit data RAM"]
    TB["Testbench checks"]

    C -->|fetch enable| PC
    PC -->|instruction address| ROM
    ROM -->|instruction word| TB
    C -->|data address and enables| CTRL
    C -->|write data| RAM
    CTRL -->|qualified operation and address| RAM
    RAM -->|read data| TB
```

The controller and Harvard top are connected in the testbench. The PC, ROM and data path are inside the top. The testbench also observes both valid signals. Both paths share the clock. A legal data request can complete on the same rising edge as an instruction fetch because each path has its own address and memory. The instruction word and read data are visible before the edge. At the edge, a fetch advances the PC and a write updates RAM.

The shared-memory baseline maps instruction and data addresses into two regions of one array and selects one address per cycle. When legal data and fetch requests overlap, the baseline grants data. The requester holds the fetch for the next available cycle. See the [interface contract](interfaces.md) for stimulus, timing and measurement rules.
