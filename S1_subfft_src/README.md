# Configuration guide — S1 SubFFT path-ECC (thresholded)

SubFFT path-level ECC check/correct design (Gao-style path check), with residual compensation removed and syndrome thresholding (τ=16).

## Top module

`top_s1_gao_subfft_ecc`

## Source files (add all to the Vivado project)

The full list is also machine-readable in `../common/filelists/S1.f` (relative to that directory), e.g. `read_verilog -sv [...]` from a Tcl script.

In this directory (`S1_subfft_src/`):

- `top_s1_kernel.sv`

Shared with the other designs, in `../common/rtl/`:

- `datapath_subfft_v5.sv`
- `fft_common.sv`
- `twiddle_rom_1024.sv`
- `protection_rtl.sv`
- `protection_primitives_v5.sv`
- `tmr_subfft_merge_stages_v5.sv`

## Vivado project setup

1. Create a new RTL project in **Vivado 2022.1**.
2. Select part **`xc7vx690tffg1761-2`**.
3. Add all `.sv` files listed above (Add Sources → Add or create design sources).
4. Set top module to `top_s1_gao_subfft_ecc`.
5. Add `../constraints/kernel_clk_125mhz.xdc` (or equivalent 8.000 ns constraint on port `clk`).
6. Optional: set synthesis option `max_bram` / strategy consistent with `-max_bram 0` if matching the paper resource flow.
7. Run Synthesis → Implementation.
8. Report Utilization / Timing Summary / Power.

## Ports (common kernel interface)

- `clk`, `rst`
- `in_valid`, `in_last`, and lane data inputs / outputs as declared in the top module

**Threshold:** arithmetic acceptance uses τ=16 (TOL=2τ).
