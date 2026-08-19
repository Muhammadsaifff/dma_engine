# DMA Engine — Complete DMA Controller

A complete **Direct Memory Access (DMA) engine** implemented in Verilog. The design integrates a DMA FSM controller with memory and peripheral interfaces to perform data transfers with minimal CPU intervention.

## Features

* **Multiple Transfer Modes**

  * Memory-to-Memory (MM)
  * Memory-to-Peripheral (MP)
  * Peripheral-to-Memory (PM)
* **Configurable Burst Transfers**

  * Burst size configurable from 1–16 words
* **Error Handling**

  * Memory error detection
  * Peripheral error detection
  * DMA error reporting
* **Status Monitoring**

  * Busy flag
  * Done flag
  * Error flag
* **Interrupt Generation**

  * Transfer-completion interrupt
  * Error interrupt
* **Automatic Address Management**

  * Source address tracking
  * Destination address tracking
* **Configurable Transfers**

  * Source/destination addresses
  * Transfer size
  * Burst size
  * Transfer mode

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                         DMA ENGINE                              │
│                                                                 │
│  ┌──────────────────┐             ┌──────────────────────────┐  │
│  │    DMA FSM       │             │    Memory Interface      │  │
│  │    Controller    │────────────►│       AXI / AHB         │  │
│  └────────┬─────────┘             └────────────┬─────────────┘  │
│           │                                    │                │
│           │                                    │                │
│           ▼                                    ▼                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  CONTROL & DATA PATH                      │  │
│  │                                                           │  │
│  │  • Burst Counter       • Address Registers               │  │
│  │  • Transfer Counter    • Data Buffer                     │  │
│  │  • Mode Control        • Error Detection                 │  │
│  └───────────────────────┬───────────────────────────────────┘  │
│                          │                                      │
│              ┌───────────┴───────────┐                          │
│              ▼                       ▼                          │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │ Status / Interrupt   │  │     Peripheral Interface     │   │
│  │     Generator        │  │                              │   │
│  └──────────────────────┘  └──────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Interface

### Configuration Inputs

| Port             |   Width | Description                                    |
| ---------------- | ------: | ---------------------------------------------- |
| `clk`            |   1 bit | Clock signal                                   |
| `rst`            |   1 bit | Active-low reset                               |
| `start_transfer` |   1 bit | Starts a DMA transfer                          |
| `src_addr`       | 32 bits | Source address                                 |
| `dst_addr`       | 32 bits | Destination address                            |
| `byte_count`     | 32 bits | Number of bytes to transfer                    |
| `burst_size`     |  4 bits | Burst size, 1–16 words                         |
| `transfer_mode`  |  2 bits | Transfer mode: `00` = MM, `01` = PM, `10` = MP |

### Status Outputs

| Port            | Width | Description                               |
| --------------- | ----: | ----------------------------------------- |
| `dma_busy`      | 1 bit | Indicates that a transfer is in progress  |
| `dma_done`      | 1 bit | Indicates that the transfer has completed |
| `dma_error`     | 1 bit | Indicates that an error occurred          |
| `dma_interrupt` | 1 bit | DMA interrupt request                     |

### Memory Interface

| Port        |   Width | Direction | Description                  |
| ----------- | ------: | --------- | ---------------------------- |
| `mem_req`   |   1 bit | Output    | Memory operation request     |
| `mem_write` |   1 bit | Output    | `1` = Write, `0` = Read      |
| `mem_addr`  | 32 bits | Output    | Memory address               |
| `mem_wdata` | 32 bits | Output    | Data to write to memory      |
| `mem_rdata` | 32 bits | Input     | Data read from memory        |
| `mem_ack`   |   1 bit | Input     | Memory operation acknowledge |
| `mem_error` |   1 bit | Input     | Memory error indication      |

### Peripheral Interface

| Port         |   Width | Direction | Description                      |
| ------------ | ------: | --------- | -------------------------------- |
| `peri_req`   |   1 bit | Output    | Peripheral operation request     |
| `peri_write` |   1 bit | Output    | `1` = Write, `0` = Read          |
| `peri_addr`  | 32 bits | Output    | Peripheral address               |
| `peri_wdata` | 32 bits | Output    | Data to write to peripheral      |
| `peri_rdata` | 32 bits | Input     | Data read from peripheral        |
| `peri_ack`   |   1 bit | Input     | Peripheral operation acknowledge |
| `peri_error` |   1 bit | Input     | Peripheral error indication      |

---

## Transfer Modes

### 1. Memory-to-Memory (MM)

```text
System Memory ──► DMA ──► System Memory
```

* Source is system memory.
* Destination is system memory.
* Both read and write operations use the memory interface.

### 2. Memory-to-Peripheral (MP)

```text
System Memory ──► DMA ──► Peripheral
```

* Data is read from system memory.
* Data is written to the peripheral.
* Memory interface handles the read.
* Peripheral interface handles the write.

### 3. Peripheral-to-Memory (PM)

```text
Peripheral ──► DMA ──► System Memory
```

* Data is read from the peripheral.
* Data is written to system memory.
* Peripheral interface handles the read.
* Memory interface handles the write.

---

## Transfer Flow

A typical DMA transfer follows this sequence:

```text
START
  │
  ▼
Configure DMA
  │
  ├── Source Address
  ├── Destination Address
  ├── Transfer Size
  ├── Burst Size
  └── Transfer Mode
  │
  ▼
Start Transfer
  │
  ▼
Read Source
  │
  ▼
Store Data in Buffer
  │
  ▼
Write Destination
  │
  ▼
Update Addresses
  │
  ▼
Update Transfer Count
  │
  ├──── More Data ────► Read Source
  │
  ▼
Transfer Complete
  │
  ▼
Generate Done / Interrupt
```

---

## Usage Example

```verilog
dma_engine dma_inst (
    .clk(clk),
    .rst(rst),

    .start_transfer(start),

    .src_addr(32'h00001000),
    .dst_addr(32'h00002000),
    .byte_count(32'd1024),
    .burst_size(4'd8),
    .transfer_mode(2'b00),

    .dma_busy(busy),
    .dma_done(done),
    .dma_error(error),
    .dma_interrupt(interrupt),

    .mem_req(mem_req),
    .mem_write(mem_write),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_ack(mem_ack),
    .mem_error(mem_error),

    .peri_req(peri_req),
    .peri_addr(peri_addr),
    .peri_write(peri_write),
    .peri_wdata(peri_wdata),
    .peri_rdata(peri_rdata),
    .peri_ack(peri_ack),
    .peri_error(peri_error)
);
```

---

## Simulation

### Prerequisites

The project requires:

* A Verilog simulator

  * ModelSim / QuestaSim
  * Icarus Verilog
  * Verilator
  * Vivado Simulator
* `dma_fsm.v`
* `dma_engine.v`
* `dma_engine_tb.v`

### Icarus Verilog

Compile the design and testbench:

```bash
iverilog -o dma_engine_tb.vvp dma_fsm.v dma_engine.v dma_engine_tb.v
```

Run the simulation:

```bash
vvp dma_engine_tb.vvp
```

### ModelSim / QuestaSim

```tcl
vlib work
vlog dma_fsm.v dma_engine.v dma_engine_tb.v
vsim work.dma_engine_tb
run -all
```

---

## Test Cases

The testbench should verify the following scenarios:

| Test                 | Description                                                           |
| -------------------- | --------------------------------------------------------------------- |
| Memory-to-Memory     | Verify correct data transfer between memory locations                 |
| Memory-to-Peripheral | Verify data is correctly written to the peripheral                    |
| Peripheral-to-Memory | Verify peripheral data is correctly stored in memory                  |
| Error Handling       | Verify memory/peripheral errors generate `dma_error` and an interrupt |
| Burst Transfer       | Verify configurable burst operation                                   |
| Single Word          | Verify a single-word transfer                                         |
| Zero-Length          | Verify that no transfer starts when the transfer size is zero         |

---

## Expected Simulation Output

```text
========== Test 1: Memory to Memory ==========
Memory[4]: 12345678
Memory[5]: 9ABCDEF0
Memory[6]: 11223344
Memory[7]: 55667788
DMA Done: 1, Error: 0, Interrupt: 1

========== Test 2: Memory to Peripheral ==========
Peripheral value: 0000AAAA
DMA Done: 1, Error: 0

========== Test 3: Peripheral to Memory ==========
Memory[12]: CAFEBABE
DMA Done: 1, Error: 0

========== Test 4: Error Condition ==========
DMA Error: 1, Interrupt: 1
```

---

## Error Handling

The DMA engine monitors both memory and peripheral interfaces for errors.

### Memory Error

```text
mem_error = 1
      │
      ▼
DMA detects error
      │
      ├── dma_error = 1
      └── dma_interrupt = 1
```

### Peripheral Error

```text
peri_error = 1
      │
      ▼
DMA detects error
      │
      ├── dma_error = 1
      └── dma_interrupt = 1
```

After an error, software can inspect the status registers, reinitialize the DMA configuration, and retry the transfer if appropriate.

---

## Performance Considerations

### Burst Size

Larger burst sizes can improve bus utilization and throughput, but may require additional buffering.

```text
Small Burst
   ↓
Lower Buffer Requirement
   ↓
Potentially Lower Throughput

Large Burst
   ↓
Higher Buffer Requirement
   ↓
Potentially Higher Throughput
```

### Bus Arbitration

The DMA controller may need to wait when another master is using the system bus.

### FIFO / Buffer Depth

The internal data buffer or FIFO should be sized according to:

* Maximum burst size
* Bus latency
* Peripheral throughput
* Required transfer rate

### Clock Domain

For a basic implementation, the DMA, memory, and peripheral interfaces should operate in the same clock domain.

If different clock domains are used, appropriate CDC mechanisms such as asynchronous FIFOs or synchronizers are required.

---

## Integration Guide

### Hardware Integration

1. Connect the DMA engine to the system bus.
2. Connect the memory interface to the memory controller or bus fabric.
3. Connect the peripheral interface to the target peripheral.
4. Connect `dma_interrupt` to the CPU interrupt controller.
5. Provide the required clock and reset signals.
6. Configure the transfer parameters.

### Software Programming Flow

```text
1. Set source address
2. Set destination address
3. Set transfer size
4. Configure burst size
5. Configure transfer mode
6. Assert start_transfer
7. Monitor dma_busy
8. Wait for dma_done or dma_interrupt
9. Check dma_error
```

### Error Recovery

```text
DMA Error
   │
   ▼
Check dma_error
   │
   ▼
Identify memory/peripheral error
   │
   ▼
Re-initialize DMA
   │
   ▼
Retry Transfer
```

---

## Project Structure

```text
DMA-Engine/
├── dma_fsm.v
├── dma_engine.v
├── dma_engine_tb.v
└── README.md
```

---

## Applications

This DMA engine can serve as a foundation for:

* FPGA-based SoC designs
* Memory-to-memory data movement
* Peripheral data transfers
* Embedded systems
* Bus-interface experiments
* Hardware design and verification projects
* DMA controller learning and prototyping

## License

This project is provided for **educational purposes**.
