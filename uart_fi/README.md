# 串口故障注入 SV（无工程）

日期：2026-08-13  
用途：从 `fft1024_ft_exp/vivado/fi_func_sim_v1` **只抽出串口命令链和两个注入点的 SV**。不收 `.xpr`、`.runs`、`.cache`、kernel 副本、激励 `.mem/.coe`、仿真日志。

原工程 README 副本：`SOURCE_README.md`。

## 串口行为

`uart_rx` → `uart_rx_simple` → `uart_cmd_decoder` → `fi_controller` → 单脉冲翻 1 bit。

命令帧（11 字节，首字节 `A5`，末字节 XOR 校验）：

| 偏移 | 字段 |
|---|---|
| 0 | preamble `A5` |
| 1 | opcode：NOP/ARM/FIRE/STATUS/RESET |
| 2 | site：0=反馈 BRAM 读出，1=蝶形输出 |
| 3 | stage_id |
| 4 | sel（lane 等） |
| 5 | component |
| 6 | bit_index |
| 7 | trig_mode |
| 8–9 | trig_count |
| 10 | checksum |

注入点只有两个：`mem_bitflip_v1`（BRAM 读数据）、`bf_out_bitflip_v1`（蝶形输出）。每 FIRE 只翻 1 bit。原工程约定：只用 raw/threshold 综合征，不用 `raw − residual` 补偿。

五核 wrap：S1、S2、S3、P1、P2。没有 S0/P0（无保护核，原工程就没做串口注入壳）。

## 收录

| 路径 | 角色 |
|---|---|
| `common/rtl/uart_rx_simple.sv` | UART 收字节 |
| `common/rtl/uart_cmd_decoder.sv` | 命令帧解码 |
| `common/rtl/fi_controller.sv` | ARM/FIRE |
| `common/rtl/fi_cmd_path.sv` | 串口命令链封装（收字节→解码→ARM/FIRE），五核十个壳共用 |
| `common/rtl/mem_bitflip_v1.sv` | 注入点 A |
| `common/rtl/fft_memory_bram_v1.sv` | 带注入口的反馈存储 |
| `common/rtl/bf_out_bitflip_v1.sv` | 注入点 B |
| `common/rtl/stim_rom.sv`、`stim_feeder.sv` | 仅被 `top_fi_rom_*` 实例化（片上激励，不是协议） |
| `common/rtl/fi_stim_source.sv` | `stim_rom`+`stim_feeder` 的封装，`top_fi_rom_*` 共用 |
| `common/tb/tb_fi_common.svh` | 五核 TB 公共任务 |
| `wrap/{S1,S2,S3,P1,P2}/top_fi_*.sv` | 串口壳（流输入 + uart_rx） |
| `wrap/{S1,S2,S3,P1,P2}/top_fi_rom_*.sv` | 串口壳（片上 ROM + uart_rx） |

（2026-08-20 起）仿真 TB（`tb/`、`common/tb/`）不随公开包发布。`top_fi_rom_*.sv` 的 `INIT_FILE` 已改为相对文件名（如 `S1_input.mem`）；`.mem` 激励镜像不随包发布，使用者按论文向量自行生成。

## 检查后未收录（不是遗漏）

| 未收 | 原因 |
|---|---|
| `FI_*/hdl/rtl/*`（kernel 拷贝） | FFT 本体，体积大，不是串口/注入点 |
| `*.xpr` `.runs` `.cache` `.sim` | 工程本身 |
| `common/mem`、`common/coe` | 激励向量 |
| `common/scripts`、`*.xdc` | 建工程/实现脚本 |
| `results/*.log` | 仿真日志 |
| `vivado/uncomp_v1_001`、任何 `*_uncomp.sv` | 去补偿 |
| `vivado/fi_rom_top_v1` | 该目录没有额外 SV |
| `fft1024_ft_exp/inject/` | Python 战役，不是串口 RTL |

本包不能单独打开 Vivado 工程；要仿真仍回 `fi_func_sim_v1`。

## 壳的结构（去重后）

十个壳（`top_fi_*` / `top_fi_rom_*`）原来各自重复一份串口命令链，现在都实例化
`fi_cmd_path`；`top_fi_rom_*` 的片上激励也都实例化 `fi_stim_source`。壳里只剩
端口、DUT 实例化和这两个（或一个）共用件。

`top_fi_*`（流输入壳）用 `fi_cmd_path #(.TB_OVERRIDE(1'b1))`，即仿真时可从 TB
层级 `force` 注命令的那条通路。这些 `tb_*` 线现在在 `u_cmd.g_tb` 里，TB 的
`force` 路径要相应加一层，例如：

```systemverilog
force u_dut.u_cmd.g_tb.tb_cmd_valid = 1'b1;   // 原为 u_dut.tb_cmd_valid
```

`top_fi_rom_*` 用 `TB_OVERRIDE=1'b0`（默认），只走串口，行为不变。
