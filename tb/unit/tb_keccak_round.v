`timescale 1ns/1ps
module tb_keccak_round;
    reg [1599:0] state_in;
    reg [4:0] round_index;
    wire [1599:0] state_out;
    reg [1599:0] expected;
    integer fd, rc, idx, checks, failures,i,trace_checks;
    reg [1023:0] vector_path,trace_path;
    reg [63:0] ec[0:4];reg [63:0] ed[0:4];
    reg [1599:0] etheta,erhopi,echi,eout;
    keccak_round dut(.state_in(state_in),.round_index(round_index),.state_out(state_out));
    initial begin
        if ($test$plusargs("DEBUG_WAVES")) begin $dumpfile("tb_keccak_round.vcd");$dumpvars(0,tb_keccak_round);end
        checks=0;failures=0;
        if (!$value$plusargs("VECTORS=%s",vector_path)) $fatal(1,"missing +VECTORS");
        fd=$fopen(vector_path,"r");if(fd==0)$fatal(1,"cannot open vectors");
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%d %h %h\n",idx,state_in,expected);
            if(rc==3) begin
                round_index=idx[4:0];#1;checks=checks+1;
                if(state_out!==expected) begin
                    failures=failures+1;
                    $display("FAIL class=keccak_round check=%0d round=%0d expected=%0400h observed=%0400h",checks,idx,expected,state_out);
                    $fatal(1,"first round failure");
                end
            end
        end
        $fclose(fd);
        if(checks<2048)$fatal(1,"insufficient checks %0d",checks);
        if(!$value$plusargs("TRACES=%s",trace_path))$fatal(1,"missing +TRACES");
        fd=$fopen(trace_path,"r");if(fd==0)$fatal(1,"cannot open traces");trace_checks=0;
        while(!$feof(fd))begin
            rc=$fscanf(fd,"%d %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n",
                idx,state_in,ec[0],ec[1],ec[2],ec[3],ec[4],ed[0],ed[1],ed[2],ed[3],ed[4],etheta,erhopi,echi,eout);
            if(rc==16)begin round_index=idx[4:0];#1;trace_checks=trace_checks+1;
                for(i=0;i<5;i=i+1)if(dut.c[i]!==ec[i]||dut.d[i]!==ed[i])$fatal(1,"theta trace round=%0d lane=%0d",idx,i);
                for(i=0;i<25;i=i+1)begin
                    if(dut.t[i]!==etheta[64*i +:64])$fatal(1,"theta lane round=%0d lane=%0d",idx,i);
                    if(dut.b[i]!==erhopi[64*i +:64])$fatal(1,"rho_pi round=%0d lane=%0d",idx,i);
                    if(dut.a[i]!==eout[64*i +:64])$fatal(1,"iota round=%0d lane=%0d",idx,i);
                    if(i!=0 && dut.a[i]!==echi[64*i +:64])$fatal(1,"chi round=%0d lane=%0d",idx,i);
                end
            end
        end
        $fclose(fd);if(trace_checks!=24)$fatal(1,"trace count=%0d",trace_checks);
        // Explicit table proof against independently encoded FIPS tables.
        if(dut.rho_offset(0)!=0||dut.rho_offset(1)!=1||dut.rho_offset(2)!=62||dut.rho_offset(6)!=44||dut.rho_offset(24)!=14)$fatal(1,"rho table anchors");
        if(dut.pi_destination(1)!=10||dut.pi_destination(5)!=16||dut.pi_destination(24)!=4)$fatal(1,"pi table anchors");
        if(dut.round_constant(0)!==64'h1||dut.round_constant(23)!==64'h8000000080008008)$fatal(1,"round constant anchors");
        $display("PASS tb_keccak_round checks=%0d traces=%0d failures=%0d",checks,trace_checks,failures);$finish;
    end
endmodule
