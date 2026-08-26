`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_fi_controller;
`TB_INIT("fi_controller"); `TB_TIMEOUT(100000)
reg clk,rst,frame_valid,frame_bad; reg [7:0] opcode,site,stage_id,sel,component,bit_index,trig_mode; reg [15:0] trig_count;
wire armed,fired,bad_cmd,arm_component,arm_site_mem,fire_pulse; wire [7:0] last_site,status_code; wire [3:0] arm_stage_id; wire [2:0] arm_sel; wire [5:0] arm_bit;
fi_controller d(clk,rst,frame_valid,opcode,site,stage_id,sel,component,bit_index,trig_mode,trig_count,frame_bad,armed,fired,last_site,bad_cmd,arm_stage_id,arm_sel,arm_component,arm_bit,arm_site_mem,fire_pulse,status_code);
always #1 clk=~clk;
task cmd(input [7:0] op,input [7:0] si,input [7:0] st,input [7:0] se,input [7:0] co,input [7:0] bi); begin @(negedge clk); opcode=op;site=si;stage_id=st;sel=se;component=co;bit_index=bi;frame_valid=1;@(negedge clk);frame_valid=0;end endtask
task check(input [7:0] op,input [7:0] si,input [7:0] st,input [7:0] se,input [7:0] co,input [7:0] bi); begin cmd(op,si,st,se,co,bi);@(posedge clk);end endtask
initial begin clk=0;rst=1;frame_valid=0;frame_bad=0;opcode=0;site=0;stage_id=0;sel=0;component=0;bit_index=0;trig_mode=0;trig_count=0;tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;repeat(2)@(posedge clk);rst=0;
 `TB_CHECK(!armed&&!fired&&!bad_cmd&&status_code==0,"reset state");
 check(1,0,1,5,1,0); `TB_CHECK(armed&&status_code==1&&arm_stage_id==1&&arm_sel==5&&arm_component==1&&arm_bit==0&&arm_site_mem&&last_site==0,"valid ARM site 0");
 check(2,0,0,0,0,0); `TB_CHECK(fire_pulse&&fired&&!armed&&status_code==2,"FIRE while armed"); @(posedge clk);`TB_CHECK(!fire_pulse,"fire pulse one cycle");
 check(3,0,0,0,0,0); `TB_CHECK(status_code==2,"STATUS fired priority");
 check(4,0,0,0,0,0); `TB_CHECK(!armed&&!fired&&!bad_cmd&&status_code==0,"RESET command");
 check(2,0,0,0,0,0); `TB_CHECK(bad_cmd&&status_code==3&&!fire_pulse,"FIRE while idle");
 check(3,0,0,0,0,0); `TB_CHECK(status_code==3,"STATUS bad priority");
 check(4,0,0,0,0,0); check(1,1,10,7,0,77); `TB_CHECK(armed&&arm_stage_id==10&&arm_sel==7&&arm_bit==6'd13&&!arm_site_mem&&last_site==1,"valid ARM site 1");
 check(1,2,1,0,0,0); `TB_CHECK(bad_cmd&&status_code==3&&armed,"invalid site");
 check(4,0,0,0,0,0); check(1,0,0,0,0,0); `TB_CHECK(bad_cmd&&status_code==3&&!armed,"invalid stage zero");
 check(4,0,0,0,0,0); check(1,0,11,0,0,0); `TB_CHECK(bad_cmd&&status_code==3&&!armed,"invalid stage eleven");
 check(4,0,0,0,0,0); check(1,0,1,0,0,78); `TB_CHECK(bad_cmd&&status_code==3&&!armed,"invalid bit");
 check(4,0,0,0,0,0); check(1,0,1,0,0,0); check(3,0,0,0,0,0); `TB_CHECK(status_code==1,"STATUS armed priority");
 check(4,0,0,0,0,0); @(negedge clk);frame_bad=1;@(posedge clk);@(negedge clk);frame_bad=0; check(3,0,0,0,0,0);#0.1;`TB_CHECK(status_code==3,"frame_bad status");
 check(4,0,0,0,0,0); check(8'h7f,0,1,0,0,0); `TB_CHECK(!armed&&!fired&&!bad_cmd&&status_code==0,"unknown opcode unchanged");
 `TB_FINISH;end
endmodule
