# Fair-kernel clock for S0–S3 / P0–P2 tops (port name: clk).
# Target device: xc7vx690tffg1761-2
# Period 8.000 ns = 125 MHz (kernel-only reg→reg timing).

create_clock -period 8.000 -name clk -waveform {0.000 4.000} [get_ports clk]

# Asynchronous reset: do not time as a data path into the kernel.
set_false_path -from [get_ports rst]
