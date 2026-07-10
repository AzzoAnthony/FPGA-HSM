### FSM States

IDLE -> RECEIVE_CMD -> RECEIVE_LEN -> COLLECT -> EXECUTE -> SEND -> IDLE
                   -> KEYGEN -> SEND -> IDLE
                   -> LOCKOUT -> SEND -> IDLE (also triggered by tamper at any state)

---

## AES Pipeline Design

The AES-128 core uses a 6-stage partial pipeline pairing 2 rounds per stage instead of a naive 10-stage design. This balances area efficiency against throughput on the resource-constrained MAX 10.

| Stage | Operations |
|-------|-----------|
| Stage 0 | Initial AddRoundKey + Round 1 |
| Stage 1 | Rounds 2-3 |
| Stage 2 | Rounds 4-5 |
| Stage 3 | Rounds 6-7 |
| Stage 4 | Rounds 8-9 |
| Stage 5 | Round 10 (final, no MixColumns) |

Key design decisions:
- Round keys precomputed once at KEYGEN, stored in registers
- All 16 S-box instances run in parallel per round (combinational)
- Lockout signal flushes all in-flight pipeline stages simultaneously in one clock cycle

Resource usage on MAX 10 (10M50DAF484C7G):
- Total logic elements: 35,665 / 49,760 (72%)
- Total registers: 1,259
- I/O pins: 6
- Memory bits: 0 (S-box implemented in LUTs)
- Compilation: 0 errors, 19 warnings

---

## UART Command Protocol

Request:  [CMD 1 byte][LEN 1 byte][PAYLOAD N bytes]
Response: [STATUS 1 byte][RESULT N bytes]

STATUS: 0xAA = success, 0xFF = error

Commands:
  0x01 KEYGEN  - Generate and store AES key (no payload)
  0x02 ENCRYPT - Encrypt 16-byte plaintext block
  0x03 DECRYPT - Decrypt 16-byte ciphertext block
  0x04 LOCKOUT - Zeroize key, enter lockout state

---

## Hardware Requirements

- Intel DE10-Lite FPGA board (MAX 10 10M50DAF484C7G)
- USB-Blaster (built into DE10-Lite)
- CP2102 or FTDI USB-to-TTL serial adapter (3.3V logic)
- Quartus Prime 23.1 Lite Edition

### Pin Assignments

| Signal | Pin | Board Component |
|--------|-----|-----------------|
| clk | PIN_P11 | 50MHz oscillator |
| rst_n | PIN_B8 | KEY0 pushbutton |
| tamper | PIN_A7 | KEY1 pushbutton |
| led_locked | PIN_A8 | LEDR0 |
| uart_rxd | PIN_W10 | GPIO[1] |
| uart_txd | PIN_V10 | GPIO[0] |

---

## Build Instructions

### FPGA

1. Open Quartus Prime 23.1 Lite
2. Open project: hsm/hsm.qpf
3. Add all .sv files from project root
4. Run full compilation: Processing -> Start Compilation
5. Program board: Tools -> Programmer -> Start

### Linux CLI Tool

gcc -o hsm_tool hsm_tool.c

### Usage

Connect CP2102 adapter:
  CP2102 TX  -> DE10-Lite GPIO[1] (PIN_W10)
  CP2102 RX  -> DE10-Lite GPIO[0] (PIN_V10)
  CP2102 GND -> DE10-Lite GND pin

Generate key:
  ./hsm_tool /dev/ttyUSB0 keygen

Encrypt a block:
  ./hsm_tool /dev/ttyUSB0 encrypt 00112233445566778899aabbccddeeff

Decrypt a block:
  ./hsm_tool /dev/ttyUSB0 decrypt <ciphertext_hex>

Lockout (wipe key):
  ./hsm_tool /dev/ttyUSB0 lockout

---

## File Structure

hsm/
├── aes_sbox.sv          # AES S-box (256-entry case statement)
├── aes_functions.sv     # xtime, MixColumns, ShiftRows functions
├── aes_round.sv         # Single AES round module
├── aes_key_schedule.sv  # AES-128 key expansion (11 round keys)
├── aes_pipeline.sv      # 6-stage pipelined AES core
├── uart_rx.sv           # UART receiver (115200 baud)
├── uart_tx.sv           # UART transmitter
├── hsm_fsm.sv           # 7-state control FSM
├── hsm_top.sv           # Top-level module
├── hsm_tool.c           # Linux CLI tool
└── hsm_test.py          # Python test script

---

## Security Design Decisions

Why hardware key storage?
Keys stored in FPGA registers are inaccessible to the host CPU. Even with full OS compromise, an attacker cannot extract key material — they can only submit encrypt/decrypt requests and observe ciphertext.

Why tamper-response at any FSM state?
Most student implementations only handle tamper in idle. This design preempts the state register unconditionally — if tamper fires during an active encryption, the pipeline flushes, the key zeroes out, and the partial result is discarded. This matches FIPS 140-3 Level 2/3 tamper-response requirements.

Why 6 pipeline stages instead of 10?
Full 10-stage pipelining would consume approximately 90% of MAX 10 LEs, leaving no margin for timing closure. 6 stages with 2 rounds each achieves the same 1 block/cycle steady-state throughput at 72% resource utilization, with enough slack for the 50MHz timing constraint.

Why not use BRAM for the S-box?
The S-box is implemented as a 256-entry case statement that synthesizes to LUTs. This avoids consuming any of the 182 M9K blocks, leaving all block memory available for future enhancements such as key storage hardening or multiple key slots.

---

## Performance

| Metric | Value |
|--------|-------|
| Clock frequency | 50 MHz |
| Pipeline latency | 6 cycles / 120 ns |
| Pipeline throughput | 1 block/cycle (steady state) |
| Raw AES throughput | 6.4 Gbps (pipeline only) |
| System throughput | ~92 Kbps (UART bottleneck) |
| Logic utilization | 72% of MAX 10 LEs |
| Zeroization time | 2 clock cycles / 40 ns |

In a production design, replacing UART with PCIe or USB 3.0 would allow the pipeline to run near its 6.4 Gbps maximum.

---

## Standards Compliance

This design is inspired by but not certified to the following standards:

- FIPS 140-3 (supersedes FIPS 140-2 as of 2022) — key zeroization, tamper response, CSP boundary
- ISO/IEC 19790 Section 7 — physical security requirements
- PCI PTS HSM — referenced for industry context (payment HSMs)
- Common Criteria — referenced for evaluation framework context

---

## Author

Anthony Azzo
Computer Engineering, University of Illinois Chicago (UIC)
Graduating December 2026
