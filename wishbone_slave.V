module wishbone_slave(

    input clk,
    input reset,
    
    input [31:0]ADR,
    input [31:0]DAT_MOSI,
    output reg [31:0]DAT_MISO,

    input WE,
    input CYC,
    input STB,
    output reg ACK,
    output reg ERR

);

reg [31:0] memory [0:255];

// the loop is to set all values to zero in memory
integer i;
initial begin
    for (i = 0; i < 256; i = i + 1)
        memory[i] = 32'b0;
end


always @(posedge clk or posedge reset)begin
    
   if(reset)begin
        ACK <= 0;
        ERR <= 0;
        DAT_MISO <= 0;
   end

   else begin
    ACK <= 0;
    ERR <= 0;

    if(CYC && STB && !ACK && !ERR)begin
        //The slaves memory has 256 words so only address 0x00000000 to 0x000000ff are valid
        // SO it takes upper 24 bit data and see if it zero if it not then error
        if(ADR[31:8] != 0)begin
            ERR <= 1'b1;
        end

        else begin
            if(WE)
                memory[ADR[7:0]] <= DAT_MOSI;
            else 
                DAT_MISO <= memory[ADR[7:0]];

                ACK <= 1;
        end
    end
   end
end

endmodule