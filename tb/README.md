# RTL unit testbenches

Run the default suite with:

```sh
make -C tb dup-check lint all
```

The suite uses Icarus Verilog with `-g2012` and `vvp`; Verilator is used for
syntax linting. The system Icarus 11.0 cannot parse
`uart_cmd_decoder.sv` because of its unpacked-array function formal. A newer
Icarus v13 build was completed at
`/home/ubuntu/iverilog-v13-install/bin/iverilog`, but it still reports that
unpacked-array subroutine ports are unsupported during elaboration. Therefore
the decoder test remains available as `make -C tb cmd-decoder` and is skipped
when the selected Icarus is older than 12 or lacks that feature. The decoder
is linted by Verilator in the default lint target.

## Coverage

| RTL module | Testbench |
| --- | --- |
| `mem_bitflip_v1` | `tb_mem_bitflip_v1.sv` |
| `bf_out_bitflip_v1` | `tb_bf_out_bitflip_v1.sv` |
| `uart_rx_simple` | `tb_uart_rx_simple.sv` |
| `uart_cmd_decoder` | `tb_uart_cmd_decoder.sv` (`cmd-decoder` only) |
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

The following remain intentionally untested in this unit-test pass:
kernel tops (`top_*_kernel.sv`), `datapath_v5.sv`, `ecc_stage4_v5.sv`,
`complete_butterfly_ecc_v1.sv`, `independent_*_v5`, SDF lane/stage modules
with 128-deep delay lines, and the `uart_fi/wrap/*` wrappers. These require
full-frame FFT reference models or long simulations.

The stage-10 RTL tests empirically observe output valid/data one clock edge
after the input is sampled (the RTL contains the `v1`/output register pair);
the testbench checks that implemented timing and also checks bubble holding and
the arithmetic right-shift behavior.

## Expected failures

The decoder's intended-protocol checks are XFAILs documenting the existing
RTL defect:

`uart_cmd_decoder frame_buf off-by-one: payload byte k stored at
frame_buf[k-1]; checksum compared against stale frame_buf[10]`

The WIDTH=70 out-of-range checks in `tb_mem_bitflip_v1.sv` are XFAILs because
the current RTL's sized shift wraps the shift count instead of producing the
zero mask expected for bit indices 70 through 77:

`mem_bitflip_v1 WIDTH'(1) shift wraps the shift count instead of producing a
zero mask`

An XPASS is a hard failure so that a future RTL fix promotes the affected
expectation to an ordinary check.
