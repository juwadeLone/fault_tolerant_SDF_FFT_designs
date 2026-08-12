# Configuration guide — S0 SubFFT unprotected

Unprotected SubFFT baseline (1024-pt / 4-lane).

## Top module

`top_s0_subfft_unprotected`

## Source files (add all to the Vivado project)

- `top_s0_kernel.sv`
- `datapath_v5.sv`
- `fft_common.sv`
- `twiddle_rom_1024.sv`

## Vivado project setup

1. Create a new RTL project in **Vivado 2022.1**.
2. Select part **`xc7vx690tffg1761-2`**.
3. Add all `.sv` files listed above (Add Sources → Add or create design sources).
4. Set top module to `top_s0_subfft_unprotected`.
5. Add `../constraints/kernel_clk_125mhz.xdc` (or equivalent 8.000 ns constraint on port `clk`).
6. Optional: set synthesis option `max_bram` / strategy consistent with `-max_bram 0` if matching the paper resource flow.
7. Run Synthesis → Implementation.
8. Report Utilization / Timing Summary / Power.

## Ports (common kernel interface)

- `clk`, `rst`
- `in_valid`, `in_last`, and lane data inputs / outputs as declared in the top module


