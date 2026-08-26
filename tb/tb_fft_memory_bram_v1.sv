`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_fft_memory_bram_v1;
`TB_INIT("fft_memory_bram_v1"); `TB_TIMEOUT(200000)
reg clk; reg rd_en128,rd_en64,wr_en; reg [6:0] ra128,wa128; reg [5:0] ra64,wa64; reg [69:0] wd; reg pulse; reg [5:0] bit_index; wire [69:0] out128,out64;
fft_memory_bram_v1 #(.DEPTH(128)) syncm(clk,rd_en128,ra128,out128,wr_en,wa128,wd,pulse,bit_index);
fft_memory_bram_v1 #(.DEPTH(64)) asyncm(clk,rd_en64,ra64,out64,wr_en,wa64,wd,pulse,bit_index);
reg [69:0] model[0:127]; reg [69:0] model64[0:63]; integer i; reg [69:0] old,newv;
always #1 clk=~clk;
task write128(input integer a,input [69:0] v);begin @(negedge clk);wr_en=1;wa128=a;wa64=a%64;wd=v;@(negedge clk);wr_en=0;end endtask
initial begin clk=0;rd_en128=0;rd_en64=0;wr_en=0;ra128=0;ra64=0;wa128=0;wa64=0;wd=0;pulse=0;bit_index=0;tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;
 for(i=0;i<128;i=i+1) begin model[i]=({$random,$random,$random});write128(i,model[i]);end
 for(i=0;i<64;i=i+1) begin model64[i]=({$random,$random,$random});model[i]=model64[i];write128(i,model64[i]);end
 for(i=0;i<128;i=i+1) begin @(negedge clk);ra128=i;rd_en128=1;@(posedge clk);#0.1;`TB_CHECK_EQ(out128,model[i],"sync readback");end
 @(negedge clk);rd_en128=0;ra128=5;@(posedge clk);#0.1;`TB_CHECK_EQ(out128,model[127],"sync rd_en hold");
 @(negedge clk);ra128=7;wd=70'h123;wa128=7;wr_en=1;rd_en128=1;@(posedge clk);#0.1;/* Empirically this behavioral model returns the old word on same-cycle read/write. */`TB_CHECK_EQ(out128,model[7],"sync same-cycle read old data"); @(negedge clk);wr_en=0;rd_en128=1;@(posedge clk);#0.1;`TB_CHECK_EQ(out128,70'h123,"sync write visible next read"); write128(63,model64[63]);
 for(i=0;i<64;i=i+1) begin @(negedge clk);ra64=i;rd_en64=1;@(posedge clk);#0.1;`TB_CHECK_EQ(out64,model64[i],"async readback");end
 @(negedge clk);ra64=7;rd_en64=1;pulse=1;bit_index=3;@(posedge clk);#0.1;`TB_CHECK_EQ(out64,model64[7]^(70'd1<<3),"FI flip");pulse=0;#0.1;`TB_CHECK_EQ(out64,model64[7],"FI does not alter storage");`TB_FINISH;end
endmodule
