module wishbone_master(

    input clk,
    input reset,
    input start,
    output busy,
    output reg error,

    input [31:0]in_address,
    input [31:0]in_data,
    input write_en,

    output reg [31:0]ADR , // address
    output reg [31:0]DAT_MOSI, // data out
    input [31:0]DAT_MISO, // data in

    output WE, // write enable 
    output reg CYC, // bus cycle active cyc = 1 means i am actually using the bus 
    output reg STB, // transfer request master is requesting transfer
    input ACK, // slave says i accept/complet your transfer
    input ERR, // error from slave side

    output reg [31:0]out_data

);

reg [31:0]addr_r, data_r;
reg we_r;
reg [1:0]state, next_state;

parameter IDLE     = 2'b00,
          TRANSFER = 2'b01,         
          RECEIVE  = 2'b10,
          ERROR    = 2'b11;

assign busy = (state != IDLE);
assign WE   = we_r;

always @(posedge clk or posedge reset)begin

    if(reset)
        state <= IDLE;
    
    else 
        state <= next_state;

end

always @(posedge clk or posedge reset)begin

    if(reset)begin
        addr_r   <= 0;
        data_r   <= 0;
        we_r     <= 0;
        out_data <= 0;
        error    <= 0;
    end

    else begin
        if (state == RECEIVE && ACK) begin
            out_data <= DAT_MISO;
        end
    
        if(start) begin
            data_r  <= in_data;
            addr_r  <= in_address;
            we_r    <= write_en;
            error   <= 0;
        end

         if((state == TRANSFER || state == RECEIVE) && ERR && !ACK)
            error <= 1'b1;  // output data is not updated on error
    end
       
end

always @(*)begin
    CYC = 0;
    STB = 0;
    ADR = 0;
    DAT_MOSI = 0;

    case(state)

    TRANSFER : begin

        CYC = 1;
        STB = 1;
        ADR = addr_r;
        DAT_MOSI = data_r;
        
    end

    RECEIVE : begin

        CYC = 1;
        STB = 1;
        ADR = addr_r;

    end

    default : ;

    endcase
    
end

always @(*)begin
    next_state = state;

    case(state)

    IDLE : begin
        if (state == IDLE && start)
            next_state = (write_en) ? TRANSFER : RECEIVE;
        
        else 
            next_state = IDLE;
    end

    TRANSFER : begin

        if(ACK) next_state = IDLE;
        else if(ERR) next_state = ERROR;
    end

    RECEIVE: begin
            if (ACK)      next_state = IDLE;
            else if (ERR) next_state = ERROR;
    end

    ERROR: next_state = IDLE;

    default : next_state = IDLE;

    endcase
end

endmodule