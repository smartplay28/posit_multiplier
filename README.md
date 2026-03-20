# Pipelined Posit Multiplier — FPGA Implementation

> A hardware implementation of a 32-bit Posit multiplier on FPGA, with performance comparison against the IEEE 754 floating-point standard.
> **Group 23** | Akshat Mittal (IMT2023606) · Nachiappan (IMT2023605)

---

## 📌 Project Overview

The **Posit number system** is an emerging alternative to IEEE 754 floating-point arithmetic. Introduced to provide higher accuracy and a larger dynamic range for the same number of bits, Posit uses a **dynamic bit allocation strategy** — unlike IEEE 754's fixed-width exponent and mantissa fields.

This project implements a **pipelined 32-bit Posit Multiplier** in Verilog and synthesizes it on an FPGA, comparing its performance (timing, power, resource utilization) against conventional IEEE 754 floating-point multiplication.

Key advantage of Posit:
- Allocates **more bits to the fraction** (precision) when numbers are close to 1
- Allocates **more bits to the exponent** (range) when numbers are extremely large or small

---

## ⚙️ Methodology — 3-Stage Pipeline

### Stage 1: Decode (Extraction)
- Extract regime bits using a **Leading Zero/One Detector (LZOD)** to determine run-length *k*
- Separate sign bit, exponent *e*, and fraction *f* from the 32-bit Posit format

### Stage 2: Execute (Core Computation)
- Calculate output sign using XOR
- Compute total scale factor using adder logic
- Perform mantissa multiplication **(1.f_A) × (1.f_B)** using **FPGA DSP48 slices** with pipelining

### Stage 3: Encode (Packing)
- Normalize the product by shifting fraction if result ≥ 2.0
- Apply rounding
- Re-pack sign, regime, exponent, and fraction into the final 32-bit Posit output

---

## 📂 Repository Structure

```
posit_multiplier/
├── posit_multiplier.v       # Top-level Posit multiplier RTL (Verilog)
├── posit_multiplier_tb.v    # Testbench for functional verification
├── value.py                 # Python script for generating test vectors / verifying results
└── constraints.txt          # FPGA timing/pin constraints
```

---

## 📊 Results Summary

| Metric | Value |
|---|---|
| **Max Frequency** | Refer timing summary (with/without clock divider) |
| **Power** | Refer power summary from Vivado |
| **Resource Utilization** | DSP48 slices + LUTs (see utilization report) |
| **Simulation Error** | 0–5% relative error vs exact result depending on operands |

> Simulation verified using ILA (Integrated Logic Analyzer) on-chip and waveform analysis in Vivado.

---

## 🛠️ Tools & Technology

| Tool | Purpose |
|---|---|
| **Vivado (Xilinx)** | Synthesis, Implementation, Bitstream Generation |
| **Verilog HDL** | RTL Design |
| **DSP48 Slices** | Hardware multiplier acceleration |
| **ILA (Integrated Logic Analyzer)** | On-chip hardware debugging |
| **Python** | Test vector generation & result verification |

---

## 🚀 How to Run

### Simulation
1. Open Vivado and create a new project
2. Add `posit_multiplier.v` as the design source
3. Add `posit_multiplier_tb.v` as the simulation source
4. Add `constraints.txt` as the constraints file
5. Run **Behavioral Simulation** to verify functionality

### Synthesis & Implementation
1. Run **Synthesis** in Vivado
2. Run **Implementation**
3. Check timing summary, power report, and resource utilization
4. Generate **Bitstream** and program your FPGA board

### Test Vector Generation
```bash
python value.py
```
Use the output to cross-verify simulation results against expected floating-point values.

---

## 📚 Background Reading

- Gustafson, J. L., & Yonemoto, I. T. (2017). *Beating Floating Point at its Own Game: Posit Arithmetic.* Supercomputing Frontiers and Innovations.
- IEEE 754-2008 Standard for Floating-Point Arithmetic

---

## 👥 Team

| Name | Roll Number |
|---|---|
| Akshat Mittal | IMT2023606 |
| Nachiappan | IMT2023605 |

---

## 📜 License

This project was developed for academic purposes as part of an FPGA design course. Feel free to reference or build upon it with appropriate credit.
