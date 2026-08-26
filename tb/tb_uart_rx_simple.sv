`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_uart_rx_simple;
`TB_INIT("uart_rx_simple"); `TB_TIMEOUT(200000)
reg clk,rst,rx; wire ready; wire [7:0] got; integer ready_count; reg [7:0] expected; integer i;
uart_rx_simple #(.CLKS_PER_BIT(16)) d(clk,rst,rx,ready,got);
always #1 clk=~clk;
always @(posedge clk) if(ready) begin ready_count=ready_count+1; `TB_CHECK_EQ(got,expected,"received byte"); end
task uart_send(input [7:0] b); integer n; begin rx=0; repeat(16) @(posedge clk); for(n=0;n<8;n=n+1) begin rx=b[n]; repeat(16) @(posedge clk); end rx=1; repeat(16) @(posedge clk); end endtask
task send_check(input [7:0] b); begin expected=b; ready_count=0; uart_send(b); repeat(2) @(posedge clk); `TB_CHECK_EQ(ready_count,1,"one ready pulse"); end endtask
initial begin clk=0;rst=1;rx=1;ready_count=0;expected=0;tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0; repeat(3) @(posedge clk);rst=0;
 send_check(8'h00); send_check(8'hff); send_check(8'ha5); send_check(8'h5a); send_check(8'h01); send_check(8'h80);
 for(i=0;i<20;i=i+1) send_check($random);
 expected=8'h3c; ready_count=0; uart_send(8'h3c); expected=8'hc3; uart_send(8'hc3); repeat(2) @(posedge clk); `TB_CHECK_EQ(ready_count,2,"back-to-back bytes");
 ready_count=0; repeat(200) @(posedge clk); `TB_CHECK_EQ(ready_count,0,"idle line");
 rx=0; repeat(30) @(posedge clk); rst=1; repeat(2) @(posedge clk); rst=0; rx=1; expected=8'h96; ready_count=0; uart_send(8'h96); repeat(2) @(posedge clk); `TB_CHECK_EQ(ready_count,1,"post-reset byte"); `TB_FINISH; end
endmodule
