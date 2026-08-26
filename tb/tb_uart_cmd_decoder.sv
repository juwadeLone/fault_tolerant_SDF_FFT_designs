`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_uart_cmd_decoder;
`TB_INIT("uart_cmd_decoder"); `TB_TIMEOUT(100000)
reg clk,rst,byte_ready; reg [7:0] rx_byte; wire frame_valid,frame_bad; wire [7:0] opcode,site,stage_id,sel,component,bit_index,trig_mode; wire [15:0] trig_count;
uart_cmd_decoder d(clk,rst,byte_ready,rx_byte,frame_valid,opcode,site,stage_id,sel,component,bit_index,trig_mode,trig_count,frame_bad);
always #1 clk=~clk;
task put(input [7:0] b); begin @(negedge clk);rx_byte=b;byte_ready=1;@(negedge clk);byte_ready=0; end endtask
task frame(input [7:0] op,input [7:0] si,input [7:0] st,input [7:0] se,input [7:0] co,input [7:0] bi,input [7:0] tm,input [7:0] lo,input [7:0] hi,input bad); reg [7:0] x; begin x=op^si^st^se^co^bi^tm^lo^hi; put(8'ha5);put(op);put(si);put(st);put(se);put(co);put(bi);put(tm);put(lo);put(hi);put(bad?x^8'h1:x); end endtask
integer i; reg [7:0] saved;
initial begin clk=0;rst=1;byte_ready=0;rx_byte=0;tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;repeat(2)@(posedge clk);rst=0;
 for(i=0;i<3;i=i+1) put(8'h11+i); `TB_CHECK(!frame_valid,"junk ignored"); frame(8'h1,0,1,2,1,3,4,5,6,0);
 `TB_XCHECK(frame_valid,"valid frame pulse","uart_cmd_decoder frame_buf off-by-one: payload byte k stored at frame_buf[k-1]; checksum compared against stale frame_buf[10]");
 `TB_XCHECK(frame_bad==0,"valid frame not bad","uart_cmd_decoder frame_buf off-by-one: payload byte k stored at frame_buf[k-1]; checksum compared against stale frame_buf[10]");
 `TB_XCHECK(opcode==8'h1 && site==0 && stage_id==1 && sel==2 && component==1 && bit_index==3 && trig_mode==4 && trig_count==16'h0605,"decoded fields","uart_cmd_decoder frame_buf off-by-one: payload byte k stored at frame_buf[k-1]; checksum compared against stale frame_buf[10]");
 frame(8'h1,0,1,2,1,3,4,5,6,1); `TB_XCHECK(frame_bad && !frame_valid,"bad checksum response","uart_cmd_decoder frame_buf off-by-one: payload byte k stored at frame_buf[k-1]; checksum compared against stale frame_buf[10]");
 put(8'ha5);put(8'h1);rst=1;repeat(2)@(posedge clk);rst=0;frame(8'h1,1,10,7,0,77,0,9,8,0); `TB_XCHECK(frame_valid,"frame after reset","uart_cmd_decoder frame_buf off-by-one: payload byte k stored at frame_buf[k-1]; checksum compared against stale frame_buf[10]"); `TB_FINISH;end
endmodule
