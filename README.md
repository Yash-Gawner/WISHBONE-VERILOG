# WISHBONE-VERILOG
Verilog implementation of a Wishbone bus master and slave with read/write transactions, ACK/ERR handling, memory-mapped access, and simulation testbench.

# Wishbone Bus Master-Slave in Verilog

A simple RTL implementation of a **Wishbone bus master and slave** using Verilog HDL.

This project was developed to understand the fundamentals of the Wishbone bus protocol, including bus cycles, transfer requests, read/write operations, acknowledgments, error handling, and memory-mapped slave access.

## 📌 Project Overview

The project consists of three main components:

* **Wishbone Master** – Initiates read and write transactions.
* **Wishbone Slave** – Responds to master requests and provides memory access.
* **Testbench** – Verifies read, write, error, and recovery operations.

The master and slave communicate using the basic Wishbone signals:

```text
ADR
DAT_MOSI
DAT_MISO
WE
CYC
STB
ACK
ERR
```

## 🏗️ Architecture

```text
                 Wishbone Bus
        ┌──────────────────────────┐
        │                          │
        │   ADR                    │
        │   DAT_MOSI               │
        │   DAT_MISO               │
        │   WE                     │
        │   CYC                    │
        │   STB                    │
        │   ACK                    │
        │   ERR                    │
        │                          │
┌───────▼────────┐        ┌────────▼───────┐
│ Wishbone       │        │ Wishbone       │
│ Master         │◄──────►│ Slave          │
└────────────────┘        └────────────────┘
                                  │
                                  │
                           ┌──────▼──────┐
                           │ 256 × 32-bit│
                           │ Memory      │
                           └─────────────┘
```

## 🔹 Wishbone Master

The master accepts a transaction from the user through:

* `start`
* `in_address`
* `in_data`
* `write_en`

It then generates the appropriate Wishbone bus signals.

### Master operation

For a write:

```text
start
  ↓
IDLE
  ↓
TRANSFER
  ↓
CYC = 1
STB = 1
WE  = 1
  ↓
Wait for ACK / ERR
  ↓
IDLE
```

For a read:

```text
start
  ↓
IDLE
  ↓
RECEIVE
  ↓
CYC = 1
STB = 1
WE  = 0
  ↓
Wait for ACK / ERR
  ↓
Capture DAT_MISO
  ↓
IDLE
```

## 🔹 Wishbone Slave

The slave contains a simple:

```text
256 × 32-bit
```

memory.

Therefore, valid addresses are:

```text
0x00000000 - 0x000000FF
```

The slave checks the upper address bits:

```verilog
if (ADR[31:8] != 0)
    ERR <= 1'b1;
```

An address outside this range generates an error response.

### Write operation

When:

```text
CYC = 1
STB = 1
WE  = 1
```

the slave writes:

```text
DAT_MOSI → memory[ADR]
```

and generates:

```text
ACK = 1
```

### Read operation

When:

```text
CYC = 1
STB = 1
WE  = 0
```

the slave reads:

```text
memory[ADR] → DAT_MISO
```

and generates:

```text
ACK = 1
```

## 🔹 Wishbone Signals

| Signal     | Direction      | Description           |
| ---------- | -------------- | --------------------- |
| `ADR`      | Master → Slave | Address               |
| `DAT_MOSI` | Master → Slave | Write data            |
| `DAT_MISO` | Slave → Master | Read data             |
| `WE`       | Master → Slave | Write enable          |
| `CYC`      | Master → Slave | Bus cycle active      |
| `STB`      | Master → Slave | Transfer request      |
| `ACK`      | Slave → Master | Transfer acknowledged |
| `ERR`      | Slave → Master | Transfer error        |

## 🧠 Important Protocol Concepts

### CYC

`CYC` indicates that the master is currently using the bus for a transaction.

```text
CYC = 1 → Bus cycle active
CYC = 0 → No active transaction
```

### STB

`STB` indicates that the master is requesting an actual data transfer.

```text
CYC = 1
STB = 1
```

together indicate an active transfer request.

### ACK

The slave asserts `ACK` when it has successfully completed the requested transfer.

```text
ACK = 1 → Transfer completed successfully
```

### ERR

The slave asserts `ERR` when the requested transfer cannot be completed.

In this project, an invalid memory address generates `ERR`.

## 🧪 Testbench

The testbench verifies the following operations:

### Test 1 – Write and Read

```text
Write 0x12345678 → Address 0x10
Read  Address 0x10
Expected: 0x12345678
```

### Test 2 – Overwrite Memory

```text
Write 0xAABBCCDD → Address 0x10
Read  Address 0x10
Expected: 0xAABBCCDD
```

### Test 3 – Second Memory Location

```text
Write 0xDEADBEEF → Address 0x20
Read  Address 0x20
Expected: 0xDEADBEEF
```

### Test 4 – Verify Previous Data

```text
Read Address 0x10
Expected: 0xAABBCCDD
```

This verifies that writing to another memory location does not affect the previous location.

### Test 5 – Invalid Address

```text
Read Address 0x100
```

Since the valid address range ends at:

```text
0xFF
```

the slave generates:

```text
ERR = 1
ACK = 0
```

The master enters its `ERROR` state and sets its `error` output.

The previous `out_data` value is also verified to remain unchanged.

### Test 6 – Error Recovery

A valid transaction is performed after the invalid transaction:

```text
Read Address 0x20
Expected: 0xDEADBEEF
```

This verifies that the master can successfully recover from an error transaction.

## 📊 Master FSM

The master uses four states:

```text
        ┌──────┐
        │ IDLE │
        └───┬──┘
            │
       start│
       ┌────┴─────┐
       │          │
       ▼          ▼
   TRANSFER    RECEIVE
       │          │
     ACK/ERR    ACK/ERR
       │          │
       └────┬─────┘
            │
       ┌────▼────┐
       │ ERROR   │
       └────┬────┘
            │
            ▼
          IDLE
```

## 🛠️ Tools Used

* **Verilog HDL**
* **Icarus Verilog**
* **GTKWave**
* **VS Code**
* **VCD waveform simulation**

## ▶️ Simulation

Compile the design and testbench using Icarus Verilog:

```bash
iverilog -o wishbone_sim wishbone_master.v wishbone_slave.v wishbone_tb.v
```

Run the simulation:

```bash
vvp wishbone_sim
```

A VCD waveform file will be generated:

```text
wishbone_tb.vcd
```

Open the waveform using GTKWave:

```bash
gtkwave wishbone_tb.vcd
```

## 📁 Project Structure

```text
wishbone-verilog/
│
├── wishbone_master.v
├── wishbone_slave.v
├── wishbone_tb.v
├── wishbone_tb.vcd
└── README.md
```

## ✅ Expected Result

If all tests pass, the simulation prints:

```text
PASS: out_data=12345678
PASS: out_data=AABBCCDD
PASS: out_data=DEADBEEF
PASS: out_data=AABBCCDD
PASS: error flagged
PASS: out_data=AABBCCDD
PASS: out_data=DEADBEEF
ALL TESTS PASSED
```

## 🚀 Future Improvements

Possible extensions to this project include:

* Support for configurable memory size
* Multiple Wishbone slaves
* Wishbone interconnect
* Wait-state support
* Pipelined Wishbone transactions
* More detailed protocol assertions
* Formal verification
* FPGA implementation
* Integration with UART, SPI, or other peripherals

## 📚 Learning Objectives

This project helped demonstrate:

* RTL design using Verilog
* Finite State Machines
* Master-slave bus communication
* Synchronous read/write operations
* Handshake signals
* Address validation
* Error handling
* Testbench development
* Waveform-based debugging
* Basic Wishbone protocol concepts

## 👤 Author

**Yash Rajendra Gawane**

Electronics & Telecommunication Engineering Student

Interested in:

* VLSI Design
* Design Verification
* SystemVerilog
* FPGA
* Embedded Systems
* Digital Design
