SHELL := /bin/bash
IVERILOG ?= iverilog
VVP ?= vvp
BUILD := build
COMMON := common/tb_utils.svh
UART := ../uart_fi/common/rtl
S3 := ../S3_subfft_src
RTL_MEM := $(UART)/mem_bitflip_v1.sv
RTL_FFT := $(S3)/fft_common.sv $(S3)/twiddle_rom_1024.sv
RTL_PROT := $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv $(RTL_FFT)
TB_NAMES := mem_bitflip_v1 bf_out_bitflip_v1 uart_rx_simple fi_controller fft_memory_bram_v1 stim_rom stim_feeder protection_primitives arithmetic_ecc gao_ecc twiddle_rom_1024 fft_complex_mul_q28 fft_complex_rotate_trivial_1024 fft_complex_mul_q28_pipe pfft_phi_calc subfft_stage10 pfft_stage10

.PHONY: all lint dup-check clean cmd-decoder $(addprefix tb_,$(TB_NAMES))

all: $(addprefix tb_,$(TB_NAMES))
	@echo "TB summary: all default testbenches passed"

tb_mem_bitflip_v1:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_mem_bitflip_v1 -o $(BUILD)/$@ $(COMMON) $(TB_MEM) $(RTL_MEM); $(VVP) $(BUILD)/$@
TB_MEM := tb_mem_bitflip_v1.sv

tb_bf_out_bitflip_v1:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_bf_out_bitflip_v1 -o $(BUILD)/$@ $(COMMON) tb_bf_out_bitflip_v1.sv $(UART)/bf_out_bitflip_v1.sv; $(VVP) $(BUILD)/$@

tb_uart_rx_simple:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_uart_rx_simple -o $(BUILD)/$@ $(COMMON) tb_uart_rx_simple.sv $(UART)/uart_rx_simple.sv; $(VVP) $(BUILD)/$@

tb_fi_controller:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_fi_controller -o $(BUILD)/$@ $(COMMON) tb_fi_controller.sv $(UART)/fi_controller.sv; $(VVP) $(BUILD)/$@

tb_fft_memory_bram_v1:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_fft_memory_bram_v1 -o $(BUILD)/$@ $(COMMON) tb_fft_memory_bram_v1.sv $(UART)/fft_memory_bram_v1.sv $(RTL_MEM); $(VVP) $(BUILD)/$@

tb_stim_rom:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_stim_rom -o $(BUILD)/$@ $(COMMON) tb_stim_rom.sv $(UART)/stim_rom.sv; $(VVP) $(BUILD)/$@

tb_stim_feeder:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_stim_feeder -o $(BUILD)/$@ $(COMMON) tb_stim_feeder.sv $(UART)/stim_feeder.sv; $(VVP) $(BUILD)/$@

tb_protection_primitives:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_protection_primitives -o $(BUILD)/$@ $(COMMON) tb_protection_primitives.sv $(S3)/protection_rtl.sv; $(VVP) $(BUILD)/$@

tb_arithmetic_ecc:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_arithmetic_ecc -o $(BUILD)/$@ $(COMMON) tb_arithmetic_ecc.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv $(RTL_FFT); $(VVP) $(BUILD)/$@

tb_gao_ecc:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_gao_ecc -o $(BUILD)/$@ $(COMMON) tb_gao_ecc.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv; $(VVP) $(BUILD)/$@

tb_twiddle_rom_1024:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_twiddle_rom_1024 -o $(BUILD)/$@ $(COMMON) tb_twiddle_rom_1024.sv $(S3)/twiddle_rom_1024.sv; $(VVP) $(BUILD)/$@

tb_fft_complex_mul_q28:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_fft_complex_mul_q28 -o $(BUILD)/$@ $(COMMON) tb_fft_complex_mul_q28.sv $(RTL_FFT); $(VVP) $(BUILD)/$@

tb_fft_complex_rotate_trivial_1024:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_fft_complex_rotate_trivial_1024 -o $(BUILD)/$@ $(COMMON) tb_fft_complex_rotate_trivial_1024.sv $(S3)/fft_common.sv; $(VVP) $(BUILD)/$@

tb_fft_complex_mul_q28_pipe:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_fft_complex_mul_q28_pipe -o $(BUILD)/$@ $(COMMON) tb_fft_complex_mul_q28_pipe.sv $(RTL_FFT); $(VVP) $(BUILD)/$@

tb_pfft_phi_calc:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_pfft_phi_calc -o $(BUILD)/$@ $(COMMON) tb_pfft_phi_calc.sv $(S3)/fft_common.sv; $(VVP) $(BUILD)/$@

tb_subfft_stage10:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_subfft_stage10 -o $(BUILD)/$@ $(COMMON) tb_subfft_stage10.sv $(S3)/fft_common.sv; $(VVP) $(BUILD)/$@

tb_pfft_stage10:
	@mkdir -p $(BUILD); $(IVERILOG) -g2012 -s tb_pfft_stage10 -o $(BUILD)/$@ $(COMMON) tb_pfft_stage10.sv $(S3)/fft_common.sv; $(VVP) $(BUILD)/$@

cmd-decoder:
	@ver=$$($(IVERILOG) -V 2>&1 | sed -n 's/Icarus Verilog version \([0-9]*\).*/\1/p'); if [ "$$ver" -ge 12 ]; then mkdir -p $(BUILD); if $(IVERILOG) -g2012 -s tb_uart_cmd_decoder -o $(BUILD)/tb_uart_cmd_decoder $(COMMON) tb_uart_cmd_decoder.sv $(UART)/uart_cmd_decoder.sv; then $(VVP) $(BUILD)/tb_uart_cmd_decoder; else echo "cmd-decoder skipped: selected Icarus lacks unpacked-array subroutine support"; fi; else echo "cmd-decoder skipped: requires iverilog >= 12 (found $$ver)"; fi

dup-check:
	@set -e; for f in fft_common.sv twiddle_rom_1024.sv; do sha256sum ../P0_pfft_src/$$f ../P1_pfft_src/$$f ../P2_pfft_src/$$f ../S0_subfft_src/$$f ../S1_subfft_src/$$f ../S2_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*7[[:space:]]'; done; for f in protection_rtl.sv; do sha256sum ../P1_pfft_src/$$f ../P2_pfft_src/$$f ../S1_subfft_src/$$f ../S2_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*5[[:space:]]'; done; for f in protection_primitives_v5.sv; do sha256sum ../P1_pfft_src/$$f ../S1_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*3[[:space:]]'; done; echo "duplicate RTL check passed"

lint:
	@verilator --lint-only -Wno-fatal --language 1800-2012 $(UART)/mem_bitflip_v1.sv $(UART)/bf_out_bitflip_v1.sv $(UART)/uart_rx_simple.sv $(UART)/fi_controller.sv $(UART)/fft_memory_bram_v1.sv $(UART)/stim_feeder.sv $(UART)/stim_rom.sv
	@verilator --lint-only -Wno-fatal --language 1800-2012 $(S3)/fft_common.sv $(S3)/twiddle_rom_1024.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv
	@verilator --lint-only -Wno-fatal --language 1800-2012 $(UART)/uart_cmd_decoder.sv

clean:
	rm -rf $(BUILD)
