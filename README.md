# ⏱️ SPI-Controlled PWM Timer Core

![Language](https://img.shields.io/badge/language-Verilog_2001-blue.svg?style=flat-square)
![Interface](https://img.shields.io/badge/interface-SPI_Slave-orange.svg?style=flat-square)
![Status](https://img.shields.io/badge/status-Verified-success.svg?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square)

## 📝 Overview

This project implements a robust, flexible **16-bit Timer/Counter and PWM Generator** controlled via an **SPI Slave Interface**. Designed for FPGA implementation, this IP core allows a master device (MCU/CPU) to configure frequencies, duty cycles, and alignment modes dynamically.

The design features a modular architecture separating the communication layer from the timing logic, ensuring clean clock domain crossing and stable signal generation.

---

## ✨ Key Features

* **🔌 Standard SPI Interface:** 4-wire slave mode (Mode 0/3 compatible) with byte-level synchronization.
* **🎯 16-bit Precision:** Full 16-bit resolution for Period and Compare thresholds[ 34].
* **🐌 Exponential Prescaler:** Programmable clock division ($2^n$) for a wide range of output frequencies.
* **🔄 Shadow Registers:** Glitch-free reconfiguration (updates occur only on counter overflow/underflow).
* **📊 Versatile PWM Modes:**
    * *Left Aligned*
    * *Right Aligned*
    * *Range Mode (Between two compare values)*
* **🔃 Up/Down Counting:** Configurable counting direction via software.

---

## 🏗️ System Architecture

The top-level module `top.v` integrates the following sub-components:

| Module | Icon | Description |
| :--- | :---: | :--- |
| **`spi_bridge`** | 📡 | **PHY Layer:** Handles MOSI/MISO shifting and clock synchronization. |
| **`instr_dcd`** | 🧠 | **Protocol Layer:** Decodes SPI packets into Read/Write commands and Addresses. |
| **`regs`** | 🗃️ | **Register File:** Manages memory mapping and configuration storage. |
| **`counter`** | ⏱️ | **Timing Engine:** Implements the prescaler and main 16-bit up/down counter. |
| **`pwm_gen`** | ⚡ | **Output Logic:** Combinational logic that generates the `pwm_out` signal. |

---

## 📡 Communication Protocol

The core uses a **2-byte transaction** format. Data is sampled on the rising edge of `sclk`.

### Frame Format
1.  **Byte 0: Command & Address**
2.  **Byte 1: Data Payload**

**Bit Structure for Byte 0:**
| Bit 7 (MSB) | Bit 6 | Bit 5..0 |
| :---: | :---: | :---: |
| **R/W** | *Reserved* | **Address [5:0]** |

* `0` = **READ** Operation
* `1` = **WRITE** Operation

---

## 🗺️ Register Map

Configuration is handled via the following 8-bit registers. 16-bit values are split into LSB/MSB pairs.

| Address | Register Name | R/W | Description |
| :--- | :--- | :---: | :--- |
| `0x00` | **PERIOD_L** | `RW` | Cycle Period (Lower Byte) |
| `0x01` | **PERIOD_H** | `RW` | Cycle Period (Upper Byte)  |
| `0x02` | **CNTR_EN** | `RW` | Enable Counter (`1` = Run, `0` = Stop) |
| `0x03` | **COMP1_L** | `RW` | Compare Threshold 1 (Lower Byte)  |
| `0x04` | **COMP1_H** | `RW` | Compare Threshold 1 (Upper Byte) |
| `0x05` | **COMP2_L** | `RW` | Compare Threshold 2 (Range Mode)  |
| `0x06` | **COMP2_H** | `RW` | Compare Threshold 2 (Upper Byte)  |
| `0x07` | **RESET** | `W` | Write `1` to reset counter to 0 |
| `0x08` | **VAL_L** | `R` | Current Counter Value (Lower Byte)  |
| `0x09` | **VAL_H** | `R` | Current Counter Value (Upper Byte)  |
| `0x0A` | **PRESCALE** | `RW` | Clock Divisor = $2^{Value}$  |
| `0x0B` | **UP/DOWN** | `RW` | `1` = Up, `0` = Down  |
| `0x0C` | **PWM_EN** | `RW` | `1` = PWM Active, `0` = Force Low  |
| `0x0D` | **FUNC** | `RW` | PWM Alignment Mode (See below)  |

---

## ⚙️ PWM Operation Modes

The `FUNCTIONS` register (`0x0D`) controls the generation logic:

* `00` **Align Left:** Output High when `Counter <= Compare1`
* `01` **Align Right:** Output High when `Counter >= Compare1`
* `10` **Range Mode:** Output High when `Compare1 <= Counter < Compare2`
* `11` **Reserved**

---

## 🚀 Simulation & Testing

The project includes a self-checking testbench (`testbench.v`) that verifies SPI transactions and PWM duty cycles.

### Prerequisites
* Icarus Verilog (`iverilog`)
* GTKWave (optional, for viewing waveforms)

### Running the Test
1.  **Compile the design:**
    ```bash
    iverilog -o system.out top.v spi_bridge.v instr_dcd.v regs.v counter.v pwm_gen.v testbench.v
    ```

2.  **Execute simulation:**
    ```bash
    vvp system.out
    ```

3.  **View Waveforms:**
    Open the generated `waves.vcd` file in GTKWave.

### Test Scenarios
* ✅ **Test 1:** PWM Left Aligned (Period=7, Compare=3) 
* ✅ **Test 2:** Range Mode (Between Compare1 & Compare2) 
* ✅ **Test 3:** PWM Right Aligned 
* ✅ **Test 4:** Edge Case (Equal Compares)
* ✅ **Test 5:** Trigger logic check 

---

> **Note:** Do not modify `top.v` as it is strictly defined for the testbench interface[ 21].

