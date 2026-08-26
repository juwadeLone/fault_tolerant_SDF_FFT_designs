`ifndef TB_UTILS_SVH
`define TB_UTILS_SVH
`define TB_INIT(n) integer tb_pass, tb_fail, tb_xfail, tb_xpass; reg [1023:0] tb_name; initial tb_name = n
`define TB_CHECK(c,m) begin if ((c) === 1'b1) begin tb_pass = tb_pass + 1; end else begin tb_fail = tb_fail + 1; $display("FAIL: %s",m); end end
`define TB_CHECK_EQ(g,e,m) begin if ((g) === (e)) begin tb_pass = tb_pass + 1; end else begin tb_fail = tb_fail + 1; $display("FAIL: %s got=%0d (0x%0h) expected=%0d (0x%0h)",m,g,g,e,e); end end
`define TB_XCHECK(c,m,r) begin if ((c) === 1'b1) begin tb_xpass = tb_xpass + 1; tb_fail = tb_fail + 1; $display("XPASS: %s (RTL behaviour changed: %s)",m,r); end else begin tb_xfail = tb_xfail + 1; $display("XFAIL: %s (%s)",m,r); end end
`define TB_FINISH begin $display("TB %s: %0d passed, %0d failed, %0d xfail, %0d xpass",tb_name,tb_pass,tb_fail,tb_xfail,tb_xpass); if ((tb_fail != 0) || (tb_xpass != 0)) $fatal(1,"test failure"); else $finish; end
`define TB_TIMEOUT(c) initial begin #(c); $fatal(1,"TB timeout"); end
`endif
