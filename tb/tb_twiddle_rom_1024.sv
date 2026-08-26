`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_twiddle_rom_1024;
`TB_INIT("twiddle_rom_1024"); `TB_TIMEOUT(200000)
reg [9:0] exponent; wire signed [29:0] coeff_re,coeff_im; real pi,rr,ii,err,mag; integer k,iref,iim;
twiddle_rom_1024 d(exponent,coeff_re,coeff_im);
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;pi=3.14159265358979323846;
 for(k=0;k<1024;k=k+1)begin exponent=k;#1;rr=$cos(2.0*pi*k/1024.0)*268435456.0;ii=-$sin(2.0*pi*k/1024.0)*268435456.0;iref=$rtoi(rr+(rr>=0?0.5:-0.5));iim=$rtoi(ii+(ii>=0?0.5:-0.5));err=coeff_re-iref;if(err<0)err=-err;`TB_CHECK(err<=1.0,"ROM real reference re");err=coeff_im-iim;if(err<0)err=-err;`TB_CHECK(err<=1.0,"ROM real reference im");mag=(1.0*coeff_re*coeff_re)+(1.0*coeff_im*coeff_im);err=mag-1.0*268435456*268435456;if(err<0)err=-err;/* Quantized coefficients empirically vary by at most 355e6 in squared magnitude. */`TB_CHECK(err<500000000.0,"ROM magnitude");end
 exponent=0;#1;`TB_CHECK_EQ(coeff_re,268435456,"ROM k0 re");`TB_CHECK_EQ(coeff_im,0,"ROM k0 im");exponent=256;#1;`TB_CHECK_EQ(coeff_re,0,"ROM k256 re");`TB_CHECK_EQ(coeff_im,-268435456,"ROM k256 im");exponent=512;#1;`TB_CHECK_EQ(coeff_re,-268435456,"ROM k512 re");exponent=768;#1;`TB_CHECK_EQ(coeff_im,268435456,"ROM k768 im");
 for(k=0;k<512;k=k+1)begin exponent=k;#1;rr=coeff_re;ii=coeff_im;exponent=k+512;#1;`TB_CHECK_EQ(coeff_re,-$rtoi(rr),"ROM half-turn symmetry re");`TB_CHECK_EQ(coeff_im,-$rtoi(ii),"ROM half-turn symmetry im");end `TB_FINISH;end
endmodule
