`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_arithmetic_ecc;
`TB_INIT("arithmetic_ecc"); `TB_TIMEOUT(100000)
reg signed [34:0] c0r,c0i,c1r,c1i,c2r,c2i,c3r,c3i,c4r,c4i,c5r,c5i,r0r,r0i,r1r,r1i,r2r,r2i,r3r,r3i,r4r,r4i,r5r,r5i;
wire signed [34:0] o0r,o0i,o1r,o1i,o2r,o2i,o3r,o3i;
arithmetic_boundary_from_clean_v5 dut(c0r,c0i,c1r,c1i,c2r,c2i,c3r,c3i,c4r,c4i,c5r,c5i,r0r,r0i,r1r,r1i,r2r,r2i,r3r,r3i,r4r,r4i,r5r,r5i,o0r,o0i,o1r,o1i,o2r,o2i,o3r,o3i);
integer i,j; reg signed [34:0] er,ei;
task build; begin c0r=$random%100000;c0i=$random%100000;c1r=$random%100000;c1i=$random%100000;c2r=$random%100000;c2i=$random%100000;c3r=$random%100000;c3i=$random%100000;c4r=c0r+c1r+c2r+c3r;c4i=c0i+c1i+c2i+c3i;c5r=c0r-c1i-c2r+c3i;c5i=c0i+c1r-c2i-c3r;r0r=c0r;r0i=c0i;r1r=c1r;r1i=c1i;r2r=c2r;r2i=c2i;r3r=c3r;r3i=c3i;r4r=c4r;r4i=c4i;r5r=c5r;r5i=c5i;end endtask
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<20;i=i+1)begin build;#1;`TB_CHECK_EQ(o0r,c0r,"arithmetic clean 0");`TB_CHECK_EQ(o0i,c0i,"arithmetic clean 0i");`TB_CHECK_EQ(o1r,c1r,"arithmetic clean 1");`TB_CHECK_EQ(o1i,c1i,"arithmetic clean 1i");`TB_CHECK_EQ(o2r,c2r,"arithmetic clean 2");`TB_CHECK_EQ(o2i,c2i,"arithmetic clean 2i");`TB_CHECK_EQ(o3r,c3r,"arithmetic clean 3");`TB_CHECK_EQ(o3i,c3i,"arithmetic clean 3i");for(j=0;j<6;j=j+1)begin er=(j+1);ei=-((j+1)*2);case(j)0:begin r0r=c0r+er;r0i=c0i+ei;end 1:begin r1r=c1r+er;r1i=c1i+ei;end 2:begin r2r=c2r+er;r2i=c2i+ei;end 3:begin r3r=c3r+er;r3i=c3i+ei;end 4:begin r4r=c4r+er;r4i=c4i+ei;end default:begin r5r=c5r+er;r5i=c5i+ei;end endcase #1;`TB_CHECK_EQ(o0r,c0r,"arithmetic correction");`TB_CHECK_EQ(o1r,c1r,"arithmetic correction");`TB_CHECK_EQ(o2r,c2r,"arithmetic correction");`TB_CHECK_EQ(o3r,c3r,"arithmetic correction");build;end end $display("double-symbol errors are intentionally not corrected");`TB_FINISH;end
endmodule
