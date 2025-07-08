# ALU

This project implements a simple 32 bit ALU in SystemVerilog, supporting 9 basic operations. The ALU implementation itself is located at `alu.v`. The project also includes a testbench at `alu_tb.v` that uses a reference model written in C, which is connected via VPI. The C code is located in `alu_predictor.c`.

## Features

- 9 operations:
  - ADD, SUB, AND, OR, XOR, SLT (set less than), SLL (shift left logical), SRL (shift right logical), SRA (shift right arithmetic)
- 32 bit inputs:
  - Operates on two 32-bit inputs: `a` and `b`
- Status flags:
  - Outputs `zero_flag`, `sign_flag`, `carry_flag`, and `overflow_flag`
- Testbench:
  - Written in SystemVerilog, checks ALU outputs using a C predictor via VPI

## Requirements

- [Icarus Verilog](https://steveicarus.github.io/iverilog/)
- GCC or compatible C compiler

## How to Run

1. Build the VPI C predictor:

   ```
   iverilog-vpi alu_predictor.c
   ```

   This produces a shared library, `alu_predictor.vpi`.

2. Compile the testbench:

   ```
   iverilog -g2012 -o alu_tb.vvp alu.v alu_tb.v
   ```

   This creates the simulation file `alu_tb.vvp`.

3. Run the simulation along with the VPI module:

   ```
   vvp -M. -malu_predictor alu_tb.vvp
   ```

   `-M.` tells `vvp` to look for VPI modules in the current directory, and `-malu_predictor` loads the `alu_predictor` VPI module.
