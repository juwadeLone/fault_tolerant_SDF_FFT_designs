# On-board UART fault-injection chain

UART command path used by the manuscript's board-level campaign:
`uart_rx_simple` → `uart_cmd_decoder` → `fi_controller` (ARM/FIRE).
Each FIRE issues a single-cycle one-bit flip at the host-specified cycle,
synchronized to frame start. The `trig_mode` / `trig_count` fields are
reserved and unused.

## Command frame (11 bytes)

| Offset | Field |
|---|---|
| 0 | preamble `A5` |
| 1 | opcode: NOP / ARM / FIRE / STATUS / RESET |
| 2 | site: 0 = feedback-memory read port, 1 = butterfly output |
| 3 | stage_id |
| 4 | sel (lane, etc.) |
| 5 | component |
| 6 | bit_index |
| 7 | trig_mode (reserved) |
| 8–9 | trig_count (reserved) |
| 10 | XOR checksum |

Injection points: `mem_bitflip_v1` (feedback-memory read data) and
`bf_out_bitflip_v1` (butterfly output). Wrappers exist for S1, S2, S3, P1,
and P2. Unprotected S0/P0 baselines have no injection wrapper.

## Layout

| Path | Role |
|---|---|
| `common/rtl/uart_rx_simple.sv` | UART byte receiver |
| `common/rtl/uart_cmd_decoder.sv` | Command-frame decoder |
| `common/rtl/fi_controller.sv` | ARM / FIRE |
| `common/rtl/mem_bitflip_v1.sv` | Injection site A |
| `common/rtl/fft_memory_bram_v1.sv` | Feedback storage with inject port |
| `common/rtl/bf_out_bitflip_v1.sv` | Injection site B |
| `common/rtl/stim_rom.sv`, `stim_feeder.sv` | On-chip stimulus for `top_fi_rom_*` |
| `wrap/{S1,S2,S3,P1,P2}/top_fi_*.sv` | Streaming-input UART shell |
| `wrap/{S1,S2,S3,P1,P2}/top_fi_rom_*.sv` | On-chip-ROM UART shell |

The ROM shells expect a relative `INIT_FILE` such as `S1_input.mem`. Stimulus
images are not shipped; generate them from the paper's vector contract.
The seven fair kernels remain in the top-level `*_src` directories.
