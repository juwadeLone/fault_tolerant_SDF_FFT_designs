# FI functional simulation projects (five kernels)

Isolated Vivado **behavioral simulation** harness for single-bit fault injection at:

1. **Feedback cache read** (site A, `fft_memory_bram_v1` + `mem_bitflip_v1`)
2. **Butterfly output data** (site B, `bf_out_bitflip_v1`)

UART command path: `uart_rx_simple` → `uart_cmd_decoder` → `fi_controller`.

## Projects

| ID | Directory | DUT top | Wrap top |
|----|-----------|---------|----------|
| S1 | `FI_S1_subfft/` | `top_s1_gao_subfft_ecc` | `top_fi_s1` |
| S2 | `FI_S2_subfft/` | `top_s2_subfft_tmr` | `top_fi_s2` |
| S3 | `FI_S3_subfft/` | `top_s3_subfft_ecc` | `top_fi_s3` |
| P1 | `FI_P1_pfft/` | `top_p1_pfft_ecc` | `top_fi_p1` |
| P2 | `FI_P2_pfft/` | `top_p2_pfft_tmr_no_framebuf_v1` | `top_fi_p2` |

RTL copies from `vivado/K_*`; **do not modify** fair-kernel `K_*` trees.

## Setup

```bash
python3 vivado/fi_func_sim_v1/common/scripts/setup_fi_projects.py
```

## Create project + simulate (example S3)

```bash
cd vivado/fi_func_sim_v1/FI_S3_subfft
vivado -mode batch -source scripts/create_project.tcl
vivado -mode batch -source ../common/scripts/run_xsim_S3.tcl
```

Test modes via plusarg: `TEST=0` CLEAN, `1` FEEDBACK, `2` BUTTERFLY, `3` UART.

## Hard rules

- Only **one bit** flipped per FIRE; only sites A and B.
- Raw/threshold syndrome path only; no `residual` / `raw - res`.
- Simulation only — no synth/impl/resource claims.
