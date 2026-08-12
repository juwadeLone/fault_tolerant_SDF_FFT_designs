`timescale 1ns/1ps

// Complete-butterfly [6,4,3] boundary: each symbol is (upper,lower) in C^2.
// One locator / one recovery boundary; upper/lower are never separate codewords.
(* keep_hierarchy = "yes" *) module complete_butterfly_corrector_643(
 input wire signed[34:0]
  u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,u4r,u4i,u5r,u5i,
  l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i,l4r,l4i,l5r,l5i,
 input wire signed[38:0]
  res0_ur,res0_ui,res1_ur,res1_ui,
  res0_lr,res0_li,res1_lr,res1_li,
 output reg signed[34:0]
  du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
  dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
reg signed[38:0]
 raw0_ur,raw0_ui,raw1_ur,raw1_ui,
 raw0_lr,raw0_li,raw1_lr,raw1_li,
 sy0_ur,sy0_ui,sy1_ur,sy1_ui,
 sy0_lr,sy0_li,sy1_lr,sy1_li,
 eru,eiu,erl,eil;
reg[2:0] loc;
reg found;
reg match0,match1,match2,match3,match4,match5;

always @* begin
 raw0_ur=$signed(u4r)-($signed(u0r)+$signed(u1r)+$signed(u2r)+$signed(u3r));
 raw0_ui=$signed(u4i)-($signed(u0i)+$signed(u1i)+$signed(u2i)+$signed(u3i));
 raw1_ur=$signed(u5r)-($signed(u0r)-$signed(u1i)-$signed(u2r)+$signed(u3i));
 raw1_ui=$signed(u5i)-($signed(u0i)+$signed(u1r)-$signed(u2i)-$signed(u3r));
 raw0_lr=$signed(l4r)-($signed(l0r)+$signed(l1r)+$signed(l2r)+$signed(l3r));
 raw0_li=$signed(l4i)-($signed(l0i)+$signed(l1i)+$signed(l2i)+$signed(l3i));
 raw1_lr=$signed(l5r)-($signed(l0r)-$signed(l1i)-$signed(l2r)+$signed(l3i));
 raw1_li=$signed(l5i)-($signed(l0i)+$signed(l1r)-$signed(l2i)-$signed(l3r));

 sy0_ur=raw0_ur-res0_ur; sy0_ui=raw0_ui-res0_ui;
 sy1_ur=raw1_ur-res1_ur; sy1_ui=raw1_ui-res1_ui;
 sy0_lr=raw0_lr-res0_lr; sy0_li=raw0_li-res0_li;
 sy1_lr=raw1_lr-res1_lr; sy1_li=raw1_li-res1_li;

 du0r=u0r;du0i=u0i;du1r=u1r;du1i=u1i;du2r=u2r;du2i=u2i;du3r=u3r;du3i=u3i;
 dl0r=l0r;dl0i=l0i;dl1r=l1r;dl1i=l1i;dl2r=l2r;dl2i=l2i;dl3r=l3r;dl3i=l3i;
 loc=0;found=0;eru=0;eiu=0;erl=0;eil=0;

 // Vector-symbol locator: same complex relation must hold on upper and lower.
 match0=(sy1_ur==sy0_ur)&&(sy1_ui==sy0_ui)&&(sy1_lr==sy0_lr)&&(sy1_li==sy0_li);
 match1=(sy1_ur==-sy0_ui)&&(sy1_ui==sy0_ur)&&(sy1_lr==-sy0_li)&&(sy1_li==sy0_lr);
 match2=(sy1_ur==-sy0_ur)&&(sy1_ui==-sy0_ui)&&(sy1_lr==-sy0_lr)&&(sy1_li==-sy0_li);
 match3=(sy1_ur==sy0_ui)&&(sy1_ui==-sy0_ur)&&(sy1_lr==sy0_li)&&(sy1_li==-sy0_lr);
 match4=(sy1_ur==0)&&(sy1_ui==0)&&(sy1_lr==0)&&(sy1_li==0);
 match5=(sy0_ur==0)&&(sy0_ui==0)&&(sy0_lr==0)&&(sy0_li==0);

 if((sy0_ur!=0)||(sy0_ui!=0)||(sy1_ur!=0)||(sy1_ui!=0)||
    (sy0_lr!=0)||(sy0_li!=0)||(sy1_lr!=0)||(sy1_li!=0)) begin
  if(match0) begin loc=0;found=1;end
  else if(match1) begin loc=1;found=1;end
  else if(match2) begin loc=2;found=1;end
  else if(match3) begin loc=3;found=1;end
  else if(match4) begin loc=4;found=1;end
  else if(match5) begin loc=5;found=1;end
  if(found) begin
   if(loc<4) begin
    eru=-sy0_ur;eiu=-sy0_ui;erl=-sy0_lr;eil=-sy0_li;
   end else if(loc==4) begin
    eru=sy0_ur;eiu=sy0_ui;erl=sy0_lr;eil=sy0_li;
   end else begin
    eru=sy1_ur;eiu=sy1_ui;erl=sy1_lr;eil=sy1_li;
   end
   case(loc)
    0:begin
     du0r=u0r-eru[34:0];du0i=u0i-eiu[34:0];
     dl0r=l0r-erl[34:0];dl0i=l0i-eil[34:0];
    end
    1:begin
     du1r=u1r-eru[34:0];du1i=u1i-eiu[34:0];
     dl1r=l1r-erl[34:0];dl1i=l1i-eil[34:0];
    end
    2:begin
     du2r=u2r-eru[34:0];du2i=u2i-eiu[34:0];
     dl2r=l2r-erl[34:0];dl2i=l2i-eil[34:0];
    end
    3:begin
     du3r=u3r-eru[34:0];du3i=u3i-eiu[34:0];
     dl3r=l3r-erl[34:0];dl3i=l3i-eil[34:0];
    end
    default:begin end
   endcase
  end
 end
end
endmodule


(* keep_hierarchy = "yes" *) module complete_butterfly_boundary_from_clean_v1(
 input wire signed[34:0]
  cu0r,cu0i,cu1r,cu1i,cu2r,cu2i,cu3r,cu3i,cu4r,cu4i,cu5r,cu5i,
  cl0r,cl0i,cl1r,cl1i,cl2r,cl2i,cl3r,cl3i,cl4r,cl4i,cl5r,cl5i,
 input wire signed[34:0]
  ru0r,ru0i,ru1r,ru1i,ru2r,ru2i,ru3r,ru3i,ru4r,ru4i,ru5r,ru5i,
  rl0r,rl0i,rl1r,rl1i,rl2r,rl2i,rl3r,rl3i,rl4r,rl4i,rl5r,rl5i,
 output wire signed[34:0]
  du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
  dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
(* keep = "true" *) wire signed[38:0]
 res0_ur=$signed(cu4r)-($signed(cu0r)+$signed(cu1r)+$signed(cu2r)+$signed(cu3r));
(* keep = "true" *) wire signed[38:0]
 res0_ui=$signed(cu4i)-($signed(cu0i)+$signed(cu1i)+$signed(cu2i)+$signed(cu3i));
(* keep = "true" *) wire signed[38:0]
 res1_ur=$signed(cu5r)-($signed(cu0r)-$signed(cu1i)-$signed(cu2r)+$signed(cu3i));
(* keep = "true" *) wire signed[38:0]
 res1_ui=$signed(cu5i)-($signed(cu0i)+$signed(cu1r)-$signed(cu2i)-$signed(cu3r));
(* keep = "true" *) wire signed[38:0]
 res0_lr=$signed(cl4r)-($signed(cl0r)+$signed(cl1r)+$signed(cl2r)+$signed(cl3r));
(* keep = "true" *) wire signed[38:0]
 res0_li=$signed(cl4i)-($signed(cl0i)+$signed(cl1i)+$signed(cl2i)+$signed(cl3i));
(* keep = "true" *) wire signed[38:0]
 res1_lr=$signed(cl5r)-($signed(cl0r)-$signed(cl1i)-$signed(cl2r)+$signed(cl3i));
(* keep = "true" *) wire signed[38:0]
 res1_li=$signed(cl5i)-($signed(cl0i)+$signed(cl1r)-$signed(cl2i)-$signed(cl3r));

complete_butterfly_corrector_643 u_corrector(
 ru0r,ru0i,ru1r,ru1i,ru2r,ru2i,ru3r,ru3i,ru4r,ru4i,ru5r,ru5i,
 rl0r,rl0i,rl1r,rl1i,rl2r,rl2i,rl3r,rl3i,rl4r,rl4i,rl5r,rl5i,
 res0_ur,res0_ui,res1_ur,res1_ui,res0_lr,res0_li,res1_lr,res1_li,
 du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
 dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
endmodule


// Four functional + two check complete butterflies; Stage-10 unity twiddles.
(* keep_hierarchy = "yes" *) module complete_butterfly_ecc_stage10_v1(
 input wire signed[34:0]a0r,a0i,a1r,a1i,a2r,a2i,a3r,a3i,
 input wire signed[34:0]b0r,b0i,b1r,b1i,b2r,b2i,b3r,b3i,
 output wire signed[34:0]u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
 output wire signed[34:0]l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i
);
wire signed[34:0] ar[0:5],ai[0:5],br[0:5],bi[0:5];
assign ar[0]=a0r;assign ai[0]=a0i;assign ar[1]=a1r;assign ai[1]=a1i;
assign ar[2]=a2r;assign ai[2]=a2i;assign ar[3]=a3r;assign ai[3]=a3i;
assign br[0]=b0r;assign bi[0]=b0i;assign br[1]=b1r;assign bi[1]=b1i;
assign br[2]=b2r;assign bi[2]=b2i;assign br[3]=b3r;assign bi[3]=b3i;
wire signed[34:0]a01r=a0r+a1r,a01i=a0i+a1i,a23r=a2r+a3r,a23i=a2i+a3i;
wire signed[34:0]b01r=b0r+b1r,b01i=b0i+b1i,b23r=b2r+b3r,b23i=b2i+b3i;
assign ar[4]=a01r+a23r;assign ai[4]=a01i+a23i;
assign br[4]=b01r+b23r;assign bi[4]=b01i+b23i;
wire signed[34:0]aw1r=-a1i,aw1i=a1r,aw2r=-a2r,aw2i=-a2i,aw3r=a3i,aw3i=-a3r;
wire signed[34:0]bw1r=-b1i,bw1i=b1r,bw2r=-b2r,bw2i=-b2i,bw3r=b3i,bw3i=-b3r;
assign ar[5]=(a0r+aw1r)+(aw2r+aw3r);assign ai[5]=(a0i+aw1i)+(aw2i+aw3i);
assign br[5]=(b0r+bw1r)+(bw2r+bw3r);assign bi[5]=(b0i+bw1i)+(bw2i+bw3i);

wire signed[34:0]upper_r[0:5],upper_i[0:5],lower_r[0:5],lower_i[0:5];
(* keep = "true" *) wire signed[34:0]recv_u_r[0:5],recv_u_i[0:5],recv_l_r[0:5],recv_l_i[0:5];
genvar g;
generate for(g=0;g<6;g=g+1)begin:complete_butterflies
 wire signed[34:0]sumr=ar[g]+br[g],sumi=ai[g]+bi[g];
 wire signed[34:0]diffr=ar[g]-br[g],diffi=ai[g]-bi[g];
 assign upper_r[g]=sumr>>>1;assign upper_i[g]=sumi>>>1;
 assign lower_r[g]=diffr>>>1;assign lower_i[g]=diffi>>>1;
 // Unity stage-10 twiddle: identity. Fault-injection port is the received pair.
 assign recv_u_r[g]=upper_r[g];assign recv_u_i[g]=upper_i[g];
 assign recv_l_r[g]=lower_r[g];assign recv_l_i[g]=lower_i[g];
end endgenerate

complete_butterfly_boundary_from_clean_v1 boundary(
 upper_r[0],upper_i[0],upper_r[1],upper_i[1],upper_r[2],upper_i[2],
 upper_r[3],upper_i[3],upper_r[4],upper_i[4],upper_r[5],upper_i[5],
 lower_r[0],lower_i[0],lower_r[1],lower_i[1],lower_r[2],lower_i[2],
 lower_r[3],lower_i[3],lower_r[4],lower_i[4],lower_r[5],lower_i[5],
 recv_u_r[0],recv_u_i[0],recv_u_r[1],recv_u_i[1],recv_u_r[2],recv_u_i[2],
 recv_u_r[3],recv_u_i[3],recv_u_r[4],recv_u_i[4],recv_u_r[5],recv_u_i[5],
 recv_l_r[0],recv_l_i[0],recv_l_r[1],recv_l_i[1],recv_l_r[2],recv_l_i[2],
 recv_l_r[3],recv_l_i[3],recv_l_r[4],recv_l_i[4],recv_l_r[5],recv_l_i[5],
 u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
 l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i
);
endmodule
