# Fault-Tolerant Parallel Streaming SDF FFT Designs (1024-pt / 4-lane)

This repository includes the source code of the fault-tolerant designs of
1024-point / 4-lane / 10-stage parallel streaming SDF FFTs (SubFFT S0–S3 and
PFFT P0–P2), written in SystemVerilog.

The code is for the paper: Zhu Ao, Guang-Cai Sun, Yuhui Deng, Jixiang Xiang,
Jianrong Ou, Yu Zhang, and Mengdao Xing, "Resource-Efficient Per-Stage Online
Recovery for Concurrent Inter-Stage Errors in Parallel Streaming SDF FFTs on
SRAM-Based FPGAs," under review in IEEE Transactions on Circuits and Systems I:
Regular Papers.

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

`schematic/` contains:

- Manuscript architecture / protection / platform figures
- `ROM_FI_shell_Vivado_schematics.pdf` — optional Vivado elaborated schematics of a
  **local ROM-fed fault-injection demonstration shell** (UART used only for ARM/FIRE;
  on-chip ROM feeds DUT stimulus). This PDF is a companion illustration; it is **not**
  a paper fair-kernel resource top. Do **not** treat pin counts or utilization from that
  shell as manuscript resource numbers. The authoritative RTL for utilization / timing /
  power regeneration remains the seven `*_src` kernels above.

The same PDF is also placed at the repository root for convenience.

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

# What is intentionally not included

- Full Vivado `.xpr` / `.runs` / bitstream packages
- UART / FI functional-simulation project trees
- Python campaign scripts and injection logs

(Same delivery scope as typical TCAS-I companion RTL releases.)

# License

See `LICENSE`.
