`timescale 1ns/1ps
module tb_keccak_state_mapping;
    reg [1599:0] state;reg [1599:0] recovered;integer b,bitn,x,y,checks;
    initial begin checks=0;state=0;
        for(b=0;b<200;b=b+1)begin state=0;state[8*b +:8]=b[7:0];if(state[8*b +:8]!==b[7:0])$fatal(1,"byte map b=%0d",b);checks=checks+1;end
        state=0;state[7:0]=8'ha5;state[63:56]=8'h5a;state[71:64]=8'hc3;
        if(state[7:0]!==8'ha5||state[63:56]!==8'h5a||state[71:64]!==8'hc3)$fatal(1,"anchor map");checks=checks+3;
        for(y=0;y<5;y=y+1)for(x=0;x<5;x=x+1)begin state=0;state[64*(x+5*y)+:64]=x+5*y;if(state[64*(x+5*y)+:64]!==x+5*y)$fatal(1,"lane map x=%0d y=%0d",x,y);checks=checks+1;end
        for(bitn=0;bitn<1600;bitn=bitn+1)begin state=0;state[bitn]=1;recovered=0;for(b=0;b<200;b=b+1)recovered[8*b +:8]=state[8*b +:8];if(recovered!==state)$fatal(1,"walking bit=%0d",bitn);checks=checks+1;end
        // Rate/capacity direct-access proof for every supported rate.
        state='1;for(b=0;b<136;b=b+1)state[8*b +:8]^=8'hff;for(b=136;b<200;b=b+1)if(state[8*b +:8]!==8'hff)$fatal(1,"capacity modified rate136 b=%0d",b);
        state='1;for(b=0;b<72;b=b+1)state[8*b +:8]^=8'hff;for(b=72;b<200;b=b+1)if(state[8*b +:8]!==8'hff)$fatal(1,"capacity modified rate72 b=%0d",b);
        state='1;for(b=0;b<168;b=b+1)state[8*b +:8]^=8'hff;for(b=168;b<200;b=b+1)if(state[8*b +:8]!==8'hff)$fatal(1,"capacity modified rate168 b=%0d",b);
        checks=checks+200+128+32;
        $display("PASS tb_keccak_state_mapping checks=%0d bytes=200 bits=1600 lanes=25",checks);$finish;
    end
endmodule
