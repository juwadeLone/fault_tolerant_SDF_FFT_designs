`timescale 1ns/1ps

module vote35(input wire [34:0] a,b,c,output wire [34:0] y);
assign y=(a&b)|(a&c)|(b&c);
endmodule

module secded_encode70(input wire [69:0] data,output reg [77:0] codeword);
integer position,payload_index,parity_position;
reg parity,overall;
always @* begin
 codeword=78'd0;payload_index=0;
 for(position=1;position<=77;position=position+1) begin
  if((position&(position-1))!=0) begin codeword[position-1]=data[payload_index];payload_index=payload_index+1;end
 end
 for(parity_position=1;parity_position<=64;parity_position=parity_position<<1) begin
  parity=0;
  for(position=1;position<=77;position=position+1) if((position&parity_position)!=0) parity=parity^codeword[position-1];
  codeword[parity_position-1]=parity;
 end
 overall=0;for(position=0;position<77;position=position+1) overall=overall^codeword[position];codeword[77]=overall;
end
endmodule

module secded_decode70(input wire [77:0] codeword,output reg [69:0] data,output reg detected,output reg corrected);
integer position,payload_index,parity_position;
reg [6:0] syndrome;reg overall,parity;reg [77:0] fixed;
always @* begin
 syndrome=0;
 for(parity_position=1;parity_position<=64;parity_position=parity_position<<1) begin
  parity=0;for(position=1;position<=77;position=position+1) if((position&parity_position)!=0) parity=parity^codeword[position-1];
  if(parity) syndrome=syndrome|parity_position;
 end
 overall=0;for(position=0;position<78;position=position+1) overall=overall^codeword[position];
 fixed=codeword;detected=0;corrected=0;
 if((syndrome!=0)&&overall) begin fixed[syndrome-1]=~fixed[syndrome-1];detected=1;corrected=1;end
 else if((syndrome==0)&&overall) begin fixed[77]=~fixed[77];detected=1;corrected=1;end
 else if((syndrome!=0)&&!overall) detected=1;
 data=0;payload_index=0;
 for(position=1;position<=77;position=position+1) if((position&(position-1))!=0) begin data[payload_index]=fixed[position-1];payload_index=payload_index+1;end
end
endmodule

(* keep_hierarchy = "yes" *) module arithmetic_corrector_643(
 input wire signed[34:0]s0r,s0i,s1r,s1i,s2r,s2i,s3r,s3i,s4r,s4i,s5r,s5i,
 input wire signed[38:0]res0r,res0i,res1r,res1i,
 output reg signed[34:0]d0r,d0i,d1r,d1i,d2r,d2i,d3r,d3i
);
reg signed[38:0]raw0r,raw0i,raw1r,raw1i,sy0r,sy0i,sy1r,sy1i,er,ei;reg[2:0]loc;reg found;
always @* begin
 raw0r=$signed(s4r)-($signed(s0r)+$signed(s1r)+$signed(s2r)+$signed(s3r));
 raw0i=$signed(s4i)-($signed(s0i)+$signed(s1i)+$signed(s2i)+$signed(s3i));
 raw1r=$signed(s5r)-($signed(s0r)-$signed(s1i)-$signed(s2r)+$signed(s3i));
 raw1i=$signed(s5i)-($signed(s0i)+$signed(s1r)-$signed(s2i)-$signed(s3r));
 sy0r=raw0r-res0r;sy0i=raw0i-res0i;sy1r=raw1r-res1r;sy1i=raw1i-res1i;
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
   endcase
  end
 end
end
endmodule
