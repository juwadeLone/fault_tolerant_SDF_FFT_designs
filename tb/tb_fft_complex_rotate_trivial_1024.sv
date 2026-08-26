`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_fft_complex_rotate_trivial_1024;
`TB_INIT("fft_complex_rotate_trivial_1024"); `TB_TIMEOUT(100000)
reg signed [34:0] ir,ii; reg [9:0] exponent; wire signed [34:0] orr,oi; integer i;
fft_complex_rotate_trivial_1024 d(ir,ii,exponent,orr,oi);
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<100;i=i+1)begin ir=$random;ii=$random;exponent=0;#1;`TB_CHECK_EQ(orr,ir,"trivial k0 re");`TB_CHECK_EQ(oi,ii,"trivial k0 im");exponent=256;#1;`TB_CHECK_EQ(orr,ii,"trivial k256 re");`TB_CHECK_EQ(oi,-ir,"trivial k256 im");exponent=512;#1;`TB_CHECK_EQ(orr,-ir,"trivial k512 re");`TB_CHECK_EQ(oi,-ii,"trivial k512 im");exponent=768;#1;`TB_CHECK_EQ(orr,-ii,"trivial k768 re");`TB_CHECK_EQ(oi,ir,"trivial k768 im");exponent=7;#1;`TB_CHECK_EQ(orr,ir,"trivial default re");`TB_CHECK_EQ(oi,ii,"trivial default im");end ir=35'sh0_3ffffffff;ii=-35'sh100000000;exponent=512;#1;`TB_CHECK_EQ(orr,-ir,"extreme sign");`TB_FINISH;end
endmodule
