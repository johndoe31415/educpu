# educpu
educpu is an extremely simple, but fully functional educational CPU
implementation. It features an 8 bit data bus and a 16 bit address bus and uses
fixed-length opcodes of three bytes each. These are the supported opcodes:

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
| 0e     | TERMINATE | Shut off CPU                                         | ignored                                |

## Simulation
The CPU can be simulated using the Logisim Evolution circuit which is contained.

## Assembler
A rudimentary assembler is provided as well with a few examples.

## License
GNU GPL-3.
