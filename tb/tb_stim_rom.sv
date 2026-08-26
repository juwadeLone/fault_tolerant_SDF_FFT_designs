`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_stim_rom;
`TB_INIT("stim_rom"); `TB_TIMEOUT(100000)
reg clk; reg [3:0] addr; wire [279:0] dout; integer i; reg [279:0] model[0:15];
stim_rom #(.DEPTH(16),.ADDR_W(4),.INIT_FILE("vectors/stim_rom_test.mem")) d(clk,addr,dout);
always #1 clk=~clk;
initial begin clk=0;addr=0;tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<16;i=i+1) model[i]={8{35'(i+1)}};for(i=0;i<16;i=i+1)begin @(negedge clk);addr=i;@(posedge clk);#0.1;`TB_CHECK_EQ(dout,model[i],"registered ROM read");end @(negedge clk);addr=0;@(posedge clk);#0.1;`TB_CHECK_EQ(dout,model[0],"ROM address wrap");`TB_FINISH;end
endmodule
