`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_fft_complex_mul_q28;
`TB_INIT("fft_complex_mul_q28"); `TB_TIMEOUT(200000)
reg signed [34:0] ir,ii; reg [9:0] exponent; wire signed [34:0] orr,oi; wire signed [29:0] cr,ci; integer i; reg signed [65:0] wr,wi;
fft_complex_mul_q28 d(ir,ii,exponent,orr,oi); twiddle_rom_1024 r(exponent,cr,ci);
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<500;i=i+1)begin ir=$random%100000000;ii=$random%100000000;exponent=$random;#1;wr=$signed(ir)*$signed(cr)-$signed(ii)*$signed(ci);wi=$signed(ir)*$signed(ci)+$signed(ii)*$signed(cr);`TB_CHECK_EQ(orr,wr>>>28,"Q28 integer reference re");`TB_CHECK_EQ(oi,wi>>>28,"Q28 integer reference im");end for(i=0;i<4;i=i+1)begin case(i)0:exponent=0;1:exponent=256;2:exponent=512;default:exponent=768;endcase ir=268435456;ii=0;#1;`TB_CHECK((orr-cr<=1)&&(cr-orr<=1),"Q28 unit real re");`TB_CHECK((oi-ci<=1)&&(ci-oi<=1),"Q28 unit real im");end `TB_FINISH;end
endmodule
