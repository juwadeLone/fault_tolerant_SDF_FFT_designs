# RTL unit testbenches

Run the default suite with:

```sh
make -C tb dup-check lint all
```

The default suite uses Icarus Verilog with `-g2012` and `vvp`; Verilator is
used for syntax linting. The decoder's unpacked-array function formal is not
elaborated by the supported Icarus versions, so `uart_cmd_decoder` is tested
through the Verilator/C++ harness with:

```sh
make -C tb cmd-decoder
```

The decoder target is separate from the default Icarus suite and is also run
explicitly by CI.

## Coverage

| RTL module | Testbench |
| --- | --- |
| `mem_bitflip_v1` | `tb_mem_bitflip_v1.sv` |
| `bf_out_bitflip_v1` | `tb_bf_out_bitflip_v1.sv` |
| `uart_rx_simple` | `tb_uart_rx_simple.sv` |
| `uart_cmd_decoder` | `verilator/uart_cmd_decoder/sim_main.cpp` (`cmd-decoder` only) |
| `fi_controller` | `tb_fi_controller.sv` |
| `fft_memory_bram_v1` | `tb_fft_memory_bram_v1.sv` |
| `stim_rom` | `tb_stim_rom.sv` |
| `stim_feeder` | `tb_stim_feeder.sv` |
| `vote35`, `secded_encode70`, `secded_decode70` | `tb_protection_primitives.sv` |
| `arithmetic_boundary_from_clean_v5`, `arithmetic_corrector_643` | `tb_arithmetic_ecc.sv` |
| `gao_boundary_from_clean_v5`, `gao_corrector_743_v5` | `tb_gao_ecc.sv` |
| `twiddle_rom_1024` | `tb_twiddle_rom_1024.sv` |
| `fft_complex_mul_q28` | `tb_fft_complex_mul_q28.sv` |
| `fft_complex_rotate_trivial_1024` | `tb_fft_complex_rotate_trivial_1024.sv` |
| `fft_complex_mul_q28_pipe` | `tb_fft_complex_mul_q28_pipe.sv` |
| `pfft_phi_calc` | `tb_pfft_phi_calc.sv` |
| `subfft_stage10` | `tb_subfft_stage10.sv` |
| `pfft_stage10` | `tb_pfft_stage10.sv` |

`mem_bitflip_v1` exposes a six-bit `bit_index`, so injection can address only
bits 0 through 63 of a 78-bit word. The testbench sweeps all 64 reachable
indices and pins the upper 14 bits as unreachable. This is an RTL interface
limitation, not a testbench defect.

The following remain intentionally untested in this unit-test pass:
kernel tops (`top_*_kernel.sv`), `datapath_v5.sv`, `ecc_stage4_v5.sv`,
`complete_butterfly_ecc_v1.sv`, `independent_*_v5`, SDF lane/stage modules
with 128-deep delay lines, and the `uart_fi/wrap/*` wrappers. These require
full-frame FFT reference models or long simulations.

The stage-10 RTL tests check the two-edge output latency, bubble holding, and
arithmetic right-shift behavior.

## Expected failures

The decoder harness ports junk-before-preamble, valid and bad-checksum
frames, back-to-back frames, reset in the middle of a frame, and byte gaps.
Its intended-protocol checks are XFAILs, while regression-lock checks capture
the current RTL behavior. Empirically, after `A5`, payload byte `k` is stored
in `frame_buf[k-1]`: the first payload overwrites the preamble, and the
eleventh byte after the preamble is needed to reach `idx == 10`. The compare
then reads `frame_buf[10]` in the same nonblocking-assignment cycle, so the
new byte is stale/`X`. In the harness sequence the delayed twelfth byte first
produces `frame_bad`; after reset does not clear the buffer, a later corrupted
frame can instead produce `frame_valid` when the stale value happens to match.
Reset discards a partial frame, and bytes after the delayed error are ignored
until a new preamble.

The XFAIL reason is:

`uart_cmd_decoder frame_buf off-by-one: payload byte k stored at
frame_buf[k-1]; checksum compared against stale frame_buf[10]`

An XPASS is a hard failure so that a future decoder correction promotes the
affected expectation to an ordinary check.
