`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_gao_ecc;
`TB_INIT("gao_ecc"); `TB_TIMEOUT(100000)
reg signed [34:0] c0r,c0i,c1r,c1i,c2r,c2i,c3r,c3i,c4r,c4i,c5r,c5i,c6r,c6i,r0r,r0i,r1r,r1i,r2r,r2i,r3r,r3i,r4r,r4i,r5r,r5i,r6r,r6i; wire signed [34:0] d0r,d0i,d1r,d1i,d2r,d2i,d3r,d3i; integer i,j; reg signed [34:0] er,ei;
 gao_boundary_from_clean_v5 d(c0r,c0i,c1r,c1i,c2r,c2i,c3r,c3i,c4r,c4i,c5r,c5i,c6r,c6i,r0r,r0i,r1r,r1i,r2r,r2i,r3r,r3i,r4r,r4i,r5r,r5i,r6r,r6i,d0r,d0i,d1r,d1i,d2r,d2i,d3r,d3i);
 task build;begin c0r=$random%10000;c0i=$random%10000;c1r=$random%10000;c1i=$random%10000;c2r=$random%10000;c2i=$random%10000;c3r=$random%10000;c3i=$random%10000;c4r=$random%10000;c4i=$random%10000;c5r=$random%10000;c5i=$random%10000;c6r=$random%10000;c6i=$random%10000;r0r=c0r;r0i=c0i;r1r=c1r;r1i=c1i;r2r=c2r;r2i=c2i;r3r=c3r;r3i=c3i;r4r=c4r;r4i=c4i;r5r=c5r;r5i=c5i;r6r=c6r;r6i=c6i;end endtask
 initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<30;i=i+1)begin build;#1;`TB_CHECK_EQ(d0r,c2r,"GAO clean d0");`TB_CHECK_EQ(d1r,c4r,"GAO clean d1");`TB_CHECK_EQ(d2r,c5r,"GAO clean d2");`TB_CHECK_EQ(d3r,c6r,"GAO clean d3");for(j=0;j<7;j=j+1)begin er=j+1;ei=-j-2;case(j)0:begin r0r=c0r+er;r0i=c0i+ei;end 1:begin r1r=c1r+er;r1i=c1i+ei;end 2:begin r2r=c2r+er;r2i=c2i+ei;end 3:begin r3r=c3r+er;r3i=c3i+ei;end 4:begin r4r=c4r+er;r4i=c4i+ei;end 5:begin r5r=c5r+er;r5i=c5i+ei;end 6:begin r6r=c6r+er;r6i=c6i+ei;end endcase #1;`TB_CHECK_EQ(d0r,c2r,"GAO single correction d0");`TB_CHECK_EQ(d1r,c4r,"GAO single correction d1");`TB_CHECK_EQ(d2r,c5r,"GAO single correction d2");`TB_CHECK_EQ(d3r,c6r,"GAO single correction d3");build;end end $display("GAO double errors are intentionally not corrected");`TB_FINISH;end
endmodule
