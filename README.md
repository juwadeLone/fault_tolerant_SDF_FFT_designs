# Fault-Tolerant Parallel Streaming SDF FFT Designs (1024-pt / 4-lane)

This repository includes the source code of the fault-tolerant designs of
1024-point / 4-lane / 10-stage parallel streaming SDF FFTs (SubFFT S0–S3 and
PFFT P0–P2), written in SystemVerilog.

The code is for the paper: Ao Zhu, Guang-Cai Sun, Yuhui Deng, Jixiang Xiang,
Jianrong Ou, Yu Zhang, and Mengdao Xing, "Resource-Efficient Per-Stage Online
Recovery from Multiple Inter-Stage Faults in Parallel SDF FFTs on FPGAs via
Operator Homogeneity," under review in IEEE Transactions on Circuits and
Systems I: Regular Papers.

# Dependencies

- Vivado 2022.1
- Device: `xc7vx690tffg1761-2`
- No third-party IP cores (pure RTL; no Xilinx FFT / FIR / TMR IP)

# Content

Each `*_src` directory contains the SystemVerilog sources and a short
configuration guide (`README.md`) for recreating a Vivado project for one design.

- `S0_subfft_src`: SubFFT unprotected baseline (top: `top_s0_subfft_unprotected`)
- `S1_subfft_src`: SubFFT path-level ECC / Gao-style check (top: `top_s1_gao_subfft_ecc`; τ=16)
- `S2_subfft_src`: SubFFT TMR (top: `top_s2_subfft_tmr`)
- `S3_subfft_src`: SubFFT per-stage ECC (top: `top_s3_subfft_ecc`; τ=4)
- `P0_pfft_src`: PFFT unprotected baseline, no frame buffer (top: `top_p0_pfft_no_framebuf_v1`)
- `P1_pfft_src`: PFFT per-stage ECC (top: `top_p1_pfft_ecc`; τ=8)
- `P2_pfft_src`: PFFT TMR, no frame buffer (top: `top_p2_pfft_tmr_no_framebuf_v1`)

`constraints/kernel_clk_125mhz.xdc` provides the 125 MHz clock constraint used
for the reported kernel timing runs.

`uart_fi/` contains the on-board UART fault-injection chain used by the
manuscript's board-level campaign: the UART command path
(`uart_rx_simple` → `uart_cmd_decoder` → `fi_controller`, an ARM/FIRE scheme),
the two injection points (`mem_bitflip_v1` for the feedback-memory read port and
`bf_out_bitflip_v1` for butterfly outputs), and the per-kernel wrappers
(`wrap/{S1,S2,S3,P1,P2}/`). Injection is a single-cycle one-bit flip issued by
the host at the target cycle, synchronized to frame start; the `trig_mode` /
`trig_count` frame fields are reserved and unused. Note: no injection wrapper
exists (or is needed) for the unprotected S0/P0 baselines.

**Threshold note (RTL defaults vs. reported values).** The `THRESHOLD`
parameters compiled into the kernels (S3=4, P1=8, S1=16) are a conservative
power-of-two calibration. The recovery rates reported in the manuscript use the
3σ-calibrated values **S3=2, P1=3, S1=5** (raw-syndrome LSB units); override the
parameter to reproduce the reported campaign.

`schematic/Vivado_schematics.pdf` is an optional Vivado elaborated schematic of a
**local ROM-fed fault-injection demonstration shell** (UART used only for ARM/FIRE;
on-chip ROM feeds DUT stimulus). It is a companion illustration, **not** a paper
fair-kernel resource top. Do **not** treat pin counts or utilization from that
shell as manuscript resource numbers. The authoritative RTL for utilization /
timing / power regeneration remains the seven `*_src` kernels above.

# Generation of Utilization & Power report

- Set up a new project in Vivado 2022.1 for device `xc7vx690tffg1761-2`.
- Add all `.sv` files from **one** `*_src` directory; set the top module listed above.
- Add `constraints/kernel_clk_125mhz.xdc` (or create an equivalent `.xdc`):

```tcl
create_clock -period 8.000 -name clk -waveform {0.000 4.000} [get_ports clk]
set_false_path -from [get_ports rst]
```

- Optional synthesis hint used in the paper resource flow: `-max_bram 0`
  (map delay-line storage to distributed RAM / LUTRAM where applicable).
- Run Synthesis → Implementation (to match post-route utilization / timing /
  power reports).
- After Implementation completes, use Flow Navigator → Report Utilization,
  Report Timing Summary, and Report Power.

# License

See `LICENSE`.
