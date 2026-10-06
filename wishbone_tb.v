module wishbone_tb;
    reg clk;
    reg reset;
    reg start;
    wire busy;
    wire error;

    reg [31:0]in_address;
    reg [31:0]in_data;
    reg write_en;

    wire [31:0]ADR;
    wire [31:0]DAT_MOSI; 
    wire [31:0]DAT_MISO;

    wire WE;
    wire CYC; 
    wire STB; 
    wire ACK; 
    wire ERR;

    wire [31:0]out_data; 

    integer errors = 0; // it count the errors

wishbone_master mas(
    .clk(clk),
    .reset(reset),
    .start(start),
    .busy(busy),
    .in_address(in_address),
    .in_data(in_data),
    .write_en(write_en),
    .ADR(ADR),
    .DAT_MOSI(DAT_MOSI),
    .DAT_MISO(DAT_MISO),
    .WE(WE),
    .CYC(CYC),
    .STB(STB),
    .ACK(ACK),
    .ERR(ERR),
    .error(error),
    .out_data(out_data)
);

wishbone_slave sla(
    .clk(clk),
    .reset(reset),
    .ADR(ADR),
    .DAT_MOSI(DAT_MOSI),
    .DAT_MISO(DAT_MISO),
    .WE(WE),
    .CYC(CYC),
    .STB(STB),
    .ACK(ACK),
    .ERR(ERR)
);

always #5 clk = ~clk;

task write( input [31:0]address , input [31:0]data);
begin

    @(negedge clk)
        in_address = address ;
        in_data = data;
        write_en = 1;
        start = 1;

    @(negedge clk)
        start = 0;
    wait(!busy);
    @(negedge clk);
end
endtask

task read(input [31:0]address);
begin

    @(negedge clk)
        in_address = address;
        write_en = 0;
        start = 1;

    @(negedge clk)
        start = 0;
    wait(!busy);
    @(negedge clk);
end
endtask

task check_data(input [31:0] expected);
    begin
        if (out_data !== expected) begin
            $display("FAIL: out_data=%h expected=%h", out_data, expected);
            errors = errors + 1;
        end
        else
            $display("PASS: out_data=%h", out_data);
    end
    endtask

initial begin
    $dumpfile("wishbone_tb.vcd");
    $dumpvars(0, wishbone_tb);
    // $monitor("%0t state=%b busy=%b CYC=%b STB=%b ADR=%h ACK=%b ERR=%b error=%b",
    //              $time, mas.state, busy, CYC, STB, ADR, ACK, ERR, error);

    clk = 0; 
    reset = 1; 
    start = 0; 
    write_en = 0;
    in_address = 0; 
    in_data = 0;
    #20 reset = 0;

    write(32'h10, 32'h12345678);
    read (32'h10);
    check_data(32'h12345678);

    write(32'h10, 32'hAABBCCDD);  
    read (32'h10);
    check_data(32'hAABBCCDD);

    write(32'h20, 32'hDEADBEEF);   
    read (32'h20);
    check_data(32'hDEADBEEF);
    read (32'h10);            
    check_data(32'hAABBCCDD);

    //#50 $finish;

    // TAKEN FRON CHAT GPT 
    // error case: out-of-range address

        read (32'h100); // out of slave memory
        if (error !== 1'b1) begin 

            $display("FAIL: error not set");
            errors = errors + 1; 

            end

        else 
            $display("PASS: error flagged");

        check_data(32'hAABBCCDD);   // out_data must be unchanged

        // error clears on next good transaction
        read (32'h20);

        if (error !== 1'b0) begin  // master clears erroe for every new transaction
            $display("FAIL: error not cleared"); 
            errors = errors + 1; 
            end

        check_data(32'hDEADBEEF);

        if (errors == 0) 
            $display("ALL TESTS PASSED");

        else             
            $display("%0d TEST(S) FAILED", errors);
        
    $finish;

end

// WATCHDOG TIMER 
// both initial block runs simultaneously 
// we wait in task if it never reaches busy so tats why wahtchdog timer is for
initial begin
        #5000;
        $display("TIMEOUT");
        $finish;
    end


endmodule
