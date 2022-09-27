# educpu
educpu is an extremely simple, but fully functional educational CPU
implementation. It features an 8 bit data bus and a 16 bit address bus and uses
fixed-length opcodes of three bytes each. It is heavily optimized towards easy
understandability and not towards performance at all. In fact, it exhibits
worst-case performance for every operation, regardless of what it's doing. Even
a NOP takes 23 clock cycles to complete.
These are the supported opcodes:

| Opcode | Mnemonic  | Description                                          | Parameter                              |
|--------|-----------|------------------------------------------------------|----------------------------------------|
| 00     | NOP       | No operation                                         | ignored                                |
| 01     | LDIMM     | Load immediate into ACC                              | low byte: immediate high byte: ignored |
| 02     | LDMEM     | Load memory into ACC                                 | 16-bit memory address                  |
| 03     | STRMEM    | Store ACC into memory                                | 16-bit memory address                  |
| 04     | JMP       | Jump unconditionally                                 | 16-bit memory address                  |
| 05     | JMPEQ     | Jump if equal                                        | 16-bit memory address                  |
| 06     | JMPNEQ    | Jump if not equal                                    | 16-bit memory address                  |
| 07     | JMPLT     | Jump if less than                                    | 16-bit memory address                  |
| 08     | ADDMEM    | Arithmetic addition: ACC += *addr                    | 16-bit memory address                  |
| 09     | SUBMEM    | Arithmetic addition with carry: ACC += *addr + C     | 16-bit memory address                  |
| 0a     | SUBMEM    | Arithmetic subtraction: ACC -= *addr                 | 16-bit memory address                  |
| 0b     | SUBBMEM   | Arithmetic subtraction with borrow: ACC -= *addr - C | 16-bit memory address                  |
| 0c     | COM       | Complement: ACC = ~ACC                               | ignored                                |
| 0d     | WRITE     | Write ACC to terminal                                | ignored                                |
| 0e     | TERMINATE | Halt CPU                                             | ignored                                |

## Internal hardware
The educpu has an 16-bit address bus (`ADDR`) and an 8-bit bidirectional data bus (`DATA`). It is connected to main memory (RAM) which
serves both as program memory and data storage. There are four registers:

  - `ACC`: General purpose 8-bit accumulator
  - `PC`: 16-bit program counter
  - `SR`: 8-bit status register (of which only 3 flags bits are used)
  - `INSN`: 24-bit instruction register in which the current instruction is
    loaded (8 bit opcode + 16 bit operand)

For the registers, these are the interesting signals:

  - `ACC` and `ACC_next` is the Q output and D input of the respective D
    flip-flop of the `ACC` register
  - `PC` and `PC_next` is the Q output and D input of the respective D
    flip-flop of the `PC` register
  - `SR` and `SR_next` is the Q output and D input of the respective D
    flip-flop of the `SR` register
  - `INSN` and `INSN_next` is the Q output and D input of the respective D
    flip-flop of the `INSN` register
  - `WE_*` is the line that signals to the register to enable a write on the
    next register clock cycle, i.e. `WE_ACC` enables storage of `ACC_next` into
    the accumulator and so on
  - `RCLK` is the register clock. On a positive edge, data is stored if the
    respective `WE_*` line was active high.

The main memory is fairly similar:

  - `MWRITE` indicates wether or not a memory write operation is requested
    (`!MWRITE` = read, `MWRITE` = write)
  - On a positive edge on `MCLK` if `!MWRITE`, data from `ADDR` is read into
    `DATA`.  On a positive edge on `MCLK` if `MWRITE`, `DATA` is stored at
    address `ADDR`. 

## Theory of operation
Each instruction is executed in 23 clock cycles. If particular stages are not
necessary for an operation, they are effectively no-ops. However, there is no
optimization -- it is obvious that instructions that are mutually exclusive
could be handleded in parallel -- they are not in educpu. There is a clock
generator that counts between 0...23 and that instruments the individual
stages. Here they are in detail:

| Clock | Unit                         | Condition                                                       | Description                                                                                                                                                                                                                                                                                                                        |
|-------|------------------------------|-----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 0     | N/A                          | always                                                          | No operation (for better readability after reset)                                                                                                                                                                                                                                                                                  |
| 1     | 1: Load opcode               | always                                                          | Prepare to read opcode: Let `INSN_next` be `INSN` but replace the most significant byte with `DATA`. Let `PC_next` be `PC` plus one (increment program counter). Set `ADDR` to `PC`.                                                                                                                                               |
| 2     | 1: Load opcode               | always                                                          | Assert signals `WE_PC` and `WE_INSN`. Issue an `MCLK` edge to read data from memory at location `PC`.                                                                                                                                                                                                                              |
| 3     | 1: Load opcode               | always                                                          | Issue an `RCLK` edge to store the read instruction byte into `INSN` and to save the incremented program counter.                                                                                                                                                                                                                   |
| 4     | 2: Load high operand         | always                                                          | Prepare to read high byte operand: Let `INSN_next` be `INSN` but replace the byte at index 1 with `DATA`. Let `PC_next` be `PC` plus one (increment program counter). Set `ADDR` to `PC`.                                                                                                                                          |
| 5     | 2: Load high operand         | always                                                          | Assert signals `WE_PC` and `WE_INSN`. Issue an `MCLK` edge to read data from memory at location `PC`.                                                                                                                                                                                                                              |
| 6     | 2: Load high operand         | always                                                          | Issue an `RCLK` edge to store the read instruction byte into `INSN` and to save the incremented program counter.                                                                                                                                                                                                                   |
| 7     | 3: Load low operand          | always                                                          | Prepare to read low byte of operand: Let `INSN_next` be `INSN` but replace the byte at index 2 with `DATA`. Let `PC_next` be `PC` plus one (increment program counter). Set `ADDR` to `PC`.                                                                                                                                        |
| 8     | 3: Load low operand          | always                                                          | Assert signals `WE_PC` and `WE_INSN`. Issue an `MCLK` edge to read data from memory at location `PC`.                                                                                                                                                                                                                              |
| 9     | 3: Load low operand          | always                                                          | Issue an `RCLK` edge to store the read instruction byte into `INSN` and to save the incremented program counter.                                                                                                                                                                                                                   |
| 10    | 4: Execute load from memory  | opcode is LDMEM, ADDMEM, ADDCMEM, SUBMEM, SUBCMEM               | Let `ADDR` be the operand of the instruction                                                                                                                                                                                                                                                                                       |
| 11    | 4: Execute load from memory  | opcode is LDMEM, ADDMEM, ADDCMEM, SUBMEM, SUBCMEM               | Issue an `MCLK` to read a byte from memory at the operand location.                                                                                                                                                                                                                                                                |
| 12    | 4: Execute load from memory  | opcode is LDMEM, ADDMEM, ADDCMEM, SUBMEM, SUBCMEM               | Replace the least significant byte of `INSN` with the read value at `DATA` and prepare to store that in the next clock cycle by asserting `WE_INSN`.                                                                                                                                                                               |
| 13    | 4: Execute load from memory  | opcode is LDMEM, ADDMEM, ADDCMEM, SUBMEM, SUBCMEM               | Issue an `RCLK` to save the value in the `INSN` register.                                                                                                                                                                                                                                                                          |
| 14    | 5: Finalize load instruction | opcode is LDIMM or LDMEM                                        | Let `ACC_next` be the low byte operand (least significant byte of `INSN`). Assert `WE_ACC` to prepare storing into the accumulator.                                                                                                                                                                                                |
| 15    | 5: Finalize load instruction | opcode is LDIMM or LDMEM                                        | Issue an `RCLK` to update the value of the `ACC` accumulator register.                                                                                                                                                                                                                                                             |
| 16    | 6: Execute ALU               | opcode is ADDMEM, ADDCMEM, SUBMEM, SUBCMEM, COM                 | Hand the requested operation to the ALU. Take the carry/borrow bit out of `SR` and input it into the ALU. Let ALU OP1 = `ACC` and OP2 = low operand byte of `INSN` (the value read from memory). Connect the output of the ALU to `ACC_next` and the status bits output of the ALU to `SR_next`. Assert both `WE_SR` and `WE_ACC`. |
| 17    | 6: Execute ALU               | opcode is ADDMEM, ADDCMEM, SUBMEM, SUBCMEM, COM                 | Issue a positive edge on `RCLK` to update both `ACC` and `SR`.                                                                                                                                                                                                                                                                     |
| 18    | 7: Execute store             | opcode is STRMEM                                                | Connect `ADDR` to the operand value stored in `INSN`. Connect `DATA` to `ACC`. Assert `MWRITE`.                                                                                                                                                                                                                                    |
| 19    | 7: Execute store             | opcode is STRMEM                                                | Issue an `MCLK` edge to store the accumulator into the memory address encoded in the operand.                                                                                                                                                                                                                                      |
| 20    | 8: Execute write/terminate   | opcode is WRITE or TERMINATE                                    | If TERMINATE, assert the `TERMINATE` signal to halt CPU. If WRITE, connect `TTYDATA` to the `ACC` accumulator.                                                                                                                                                                                                                     |
| 21    | 8: Execute write/terminate   | opcode is WRITE or TERMINATE                                    | Issue a clock edge on `TTYCLK` to display the accumulator byte on the terminal.                                                                                                                                                                                                                                                    |
| 22    | 9: Branch unit               | opcode is JMP, JMPEQ, JMPNEQ, JMPLT and branch condition is met | Set `PC_next` to the operand stored in `INSN`. Assert `WE_PC`.                                                                                                                                                                                                                                                                     |
| 23    | 9: Branch unit               | opcode is JMP, JMPEQ, JMPNEQ, JMPLT and branch condition is met | Issue an `RCLK` to make the change in `PC` effective.                                                                                                                                                                                                                                                                              |

## Simulation
The CPU can be simulated using the [Logisim
Evolution](https://github.com/logisim-evolution/logisim-evolution/releases)
circuit which can be found in the `educpu.circ` file. It is relatively easy to get started:

  - Load the circuit file
  - Load an image into the RAM (right clock, "Load contents...", load the .bin file)
  - Issue `RESET` manually
  - Deassert `RESET` and watch it run.

## Subcircuits
There are a few subcircuits that are used throughout in the simulation:

  - Registers: Contains all four registers (`ACC`, `SR`, `INSN` and `PC`).
  - ClockGenerator: Essentially a counter that counts from 0..23 repeatedly and
    creates the `CLK` signal this way.
  - Inc16: Simple 16-bit incrementer unit (to easily increment `PC`).
  - Set8of24: Replace one byte of a 24-bit value (which byte can be selected by
    the `INDEX` signal)
  - InsnDecoder: Decode a 24-bit instruction into its parts: opcode, operand
    and also operand highbyte and operand lowbyte.
  - OpcodeDecoder: Decode an 8-bit opcode into the corresponding instruction.
  - ALU: Perform arithmetic operation (add/subtract/complement)
  - SRDecoder: Decode the individual bits from the `SR` register.
  - SREncoder: Encode individual flags bits into a value that has the layout of
    the `SR` register.
  - BranchControl: Given the `SR` status register and the requested jump
    operation, determine if the jump should be taken or not.

## Assembler
A rudimentary assembler is provided as well with a few examples.

## License
GNU GPL-3.
