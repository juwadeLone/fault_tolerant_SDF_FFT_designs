`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_mem_bitflip_v1;
`TB_INIT("mem_bitflip_v1");
`TB_TIMEOUT(100000)
reg [77:0] c78; reg [69:0] c70; reg pulse; reg [5:0] bit_index;
wire [77:0] o78; wire [69:0] o70;
mem_bitflip_v1 #(.WIDTH(78)) d78(c78,pulse,bit_index,o78);
mem_bitflip_v1 #(.WIDTH(70)) d70(c70,pulse,bit_index,o70);
integer i,j; reg [77:0] mask78; reg [69:0] mask70;
initial begin
 tb_pass=0; tb_fail=0; tb_xfail=0; tb_xpass=0; c78=78'h123456789abcdef0123; c70=70'h155555555555555555; pulse=0;
 for (i=0;i<50;i=i+1) begin c78={$random,$random,$random}; c70={$random,$random,$random}; bit_index=i%78; #1; `TB_CHECK_EQ(o78,c78,"WIDTH=78 clean"); `TB_CHECK_EQ(o70,c70,"WIDTH=70 clean"); end
 for (j=0;j<3;j=j+1) begin c78={$random,$random,$random}; c70={$random,$random,$random}; pulse=1;
  for (i=0;i<64;i=i+1) begin bit_index=i; #1; mask78=78'd1<<i; mask70=70'd1<<i; `TB_CHECK_EQ(o78,c78^mask78,"WIDTH=78 one-bit flip"); if (i<70) `TB_CHECK_EQ(o70,c70^mask70,"WIDTH=70 one-bit flip"); end
 for (i=70;i<78;i=i+1) begin bit_index=i; #1; `TB_XCHECK(o70==c70,"WIDTH=70 out-of-range truncates","Icarus 11/13 wraps the shift count in WIDTH'(1)<<bit_index; per LRM the mask is zero for bit_index >= WIDTH, so Vivado zero-extends and the RTL is correct"); end
 end
 `TB_FINISH;
end
endmodule
