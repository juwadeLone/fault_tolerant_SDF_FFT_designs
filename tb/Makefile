SHELL := /bin/bash
IVERILOG ?= iverilog
VVP ?= vvp
VERILATOR ?= verilator
BUILD := build
COMMON := common/tb_utils.svh
UART := ../uart_fi/common/rtl
S3 := ../S3_subfft_src
RTL_MEM := $(UART)/mem_bitflip_v1.sv
RTL_FFT := $(S3)/fft_common.sv $(S3)/twiddle_rom_1024.sv
RTL_PROT := $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv $(RTL_FFT)
TB_MEM := tb_mem_bitflip_v1.sv
TB_NAMES := mem_bitflip_v1 bf_out_bitflip_v1 uart_rx_simple fi_controller fft_memory_bram_v1 stim_rom stim_feeder protection_primitives arithmetic_ecc gao_ecc twiddle_rom_1024 fft_complex_mul_q28 fft_complex_rotate_trivial_1024 fft_complex_mul_q28_pipe pfft_phi_calc subfft_stage10 pfft_stage10
CMD_BUILD := $(BUILD)/verilator/uart_cmd_decoder
CMD_HARNESS := $(CURDIR)/verilator/uart_cmd_decoder/sim_main.cpp

TB_SRCS_tb_mem_bitflip_v1 := $(TB_MEM) $(RTL_MEM)
TB_SRCS_tb_bf_out_bitflip_v1 := tb_bf_out_bitflip_v1.sv $(UART)/bf_out_bitflip_v1.sv
TB_SRCS_tb_uart_rx_simple := tb_uart_rx_simple.sv $(UART)/uart_rx_simple.sv
TB_SRCS_tb_fi_controller := tb_fi_controller.sv $(UART)/fi_controller.sv
TB_SRCS_tb_fft_memory_bram_v1 := tb_fft_memory_bram_v1.sv $(UART)/fft_memory_bram_v1.sv $(RTL_MEM)
TB_SRCS_tb_stim_rom := tb_stim_rom.sv $(UART)/stim_rom.sv
TB_SRCS_tb_stim_feeder := tb_stim_feeder.sv $(UART)/stim_feeder.sv
TB_SRCS_tb_protection_primitives := tb_protection_primitives.sv $(S3)/protection_rtl.sv
TB_SRCS_tb_arithmetic_ecc := tb_arithmetic_ecc.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv $(RTL_FFT)
TB_SRCS_tb_gao_ecc := tb_gao_ecc.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv
TB_SRCS_tb_twiddle_rom_1024 := tb_twiddle_rom_1024.sv $(S3)/twiddle_rom_1024.sv
TB_SRCS_tb_fft_complex_mul_q28 := tb_fft_complex_mul_q28.sv $(RTL_FFT)
TB_SRCS_tb_fft_complex_rotate_trivial_1024 := tb_fft_complex_rotate_trivial_1024.sv $(S3)/fft_common.sv
TB_SRCS_tb_fft_complex_mul_q28_pipe := tb_fft_complex_mul_q28_pipe.sv $(RTL_FFT)
TB_SRCS_tb_pfft_phi_calc := tb_pfft_phi_calc.sv $(S3)/fft_common.sv
TB_SRCS_tb_subfft_stage10 := tb_subfft_stage10.sv $(S3)/fft_common.sv
TB_SRCS_tb_pfft_stage10 := tb_pfft_stage10.sv $(S3)/fft_common.sv

.PHONY: all lint dup-check clean cmd-decoder $(addprefix tb_,$(TB_NAMES))

all: $(addprefix tb_,$(TB_NAMES))
	@echo "TB summary: all default testbenches passed"

$(addprefix tb_,$(TB_NAMES)):
	@mkdir -p $(BUILD) && $(IVERILOG) -g2012 -s $@ -o $(BUILD)/$@ $(COMMON) $(TB_SRCS_$@) && $(VVP) $(BUILD)/$@

cmd-decoder:
	@mkdir -p $(CMD_BUILD) && $(VERILATOR) --cc --exe --build --top-module uart_cmd_decoder -Wno-fatal -Mdir $(CMD_BUILD) $(CURDIR)/$(UART)/uart_cmd_decoder.sv $(CMD_HARNESS) && $(CMD_BUILD)/Vuart_cmd_decoder

dup-check:
	@set -e; for f in fft_common.sv twiddle_rom_1024.sv; do sha256sum ../P0_pfft_src/$$f ../P1_pfft_src/$$f ../P2_pfft_src/$$f ../S0_subfft_src/$$f ../S1_subfft_src/$$f ../S2_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*7[[:space:]]'; done; for f in protection_rtl.sv; do sha256sum ../P1_pfft_src/$$f ../P2_pfft_src/$$f ../S1_subfft_src/$$f ../S2_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*5[[:space:]]'; done; for f in protection_primitives_v5.sv; do sha256sum ../P1_pfft_src/$$f ../S1_subfft_src/$$f ../S3_subfft_src/$$f | awk '{print $$1}' | uniq -c | grep -Eq '^[[:space:]]*3[[:space:]]'; done; echo "duplicate RTL check passed"

lint:
	@$(VERILATOR) --lint-only -Wno-fatal --language 1800-2012 $(UART)/mem_bitflip_v1.sv $(UART)/bf_out_bitflip_v1.sv $(UART)/uart_rx_simple.sv $(UART)/fi_controller.sv $(UART)/fft_memory_bram_v1.sv $(UART)/stim_feeder.sv $(UART)/stim_rom.sv
	@$(VERILATOR) --lint-only -Wno-fatal --language 1800-2012 $(S3)/fft_common.sv $(S3)/twiddle_rom_1024.sv $(S3)/protection_rtl.sv $(S3)/protection_primitives_v5.sv
	@$(VERILATOR) --lint-only -Wno-fatal --language 1800-2012 $(UART)/uart_cmd_decoder.sv

clean:
	rm -rf $(BUILD)
