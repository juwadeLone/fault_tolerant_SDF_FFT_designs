`timescale 1ns/1ps

// Locator/apply half of arithmetic_corrector_643 with pre-registered syndromes.
(* keep_hierarchy = "yes" *) module arithmetic_apply_from_syndrome_643(
 input wire signed[34:0]s0r,s0i,s1r,s1i,s2r,s2i,s3r,s3i,
 input wire signed[38:0]sy0r,sy0i,sy1r,sy1i,
 output reg signed[34:0]d0r,d0i,d1r,d1i,d2r,d2i,d3r,d3i
);
reg signed[38:0]er,ei;reg[2:0]loc;reg found;
always @* begin
 d0r=s0r;d0i=s0i;d1r=s1r;d1i=s1i;d2r=s2r;d2i=s2i;d3r=s3r;d3i=s3i;loc=0;found=0;er=0;ei=0;
 if((sy0r!=0)||(sy0i!=0)||(sy1r!=0)||(sy1i!=0)) begin
  if((sy1r==sy0r)&&(sy1i==sy0i))begin loc=0;found=1;end
  else if((sy1r==-sy0i)&&(sy1i==sy0r))begin loc=1;found=1;end
  else if((sy1r==-sy0r)&&(sy1i==-sy0i))begin loc=2;found=1;end
  else if((sy1r==sy0i)&&(sy1i==-sy0r))begin loc=3;found=1;end
  else if((sy1r==0)&&(sy1i==0))begin loc=4;found=1;end
  else if((sy0r==0)&&(sy0i==0))begin loc=5;found=1;end
  if(found) begin
   if(loc<4)begin er=-sy0r;ei=-sy0i;end else if(loc==4)begin er=sy0r;ei=sy0i;end else begin er=sy1r;ei=sy1i;end
   case(loc)
    0:begin d0r=s0r-er[34:0];d0i=s0i-ei[34:0];end
    1:begin d1r=s1r-er[34:0];d1i=s1i-ei[34:0];end
    2:begin d2r=s2r-er[34:0];d2i=s2i-ei[34:0];end
    3:begin d3r=s3r-er[34:0];d3i=s3i-ei[34:0];end
    default:begin end
   endcase
  end
 end
end
endmodule
