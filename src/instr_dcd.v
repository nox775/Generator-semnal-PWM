module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input[7:0] data_in,
    output[7:0] data_out,
    // register access signals
    output read,
    output write,
    output[5:0] addr,
    input[7:0] data_read,
    output[7:0] data_write
);

    reg [7:0] data_out_int = 0;
    reg read_int = 0;
    reg write_int = 0;
    reg [5:0] addr_int = 0;
    reg [7:0] data_write_int = 0;

    assign data_out = data_out_int;
    assign read = read_int;
    assign write = write_int;
    assign addr = addr_int;
    assign data_write = data_write_int;

    localparam STATE_SETUP = 1'b0;
    localparam STATE_DATA  = 1'b1;

    reg state = STATE_SETUP;
    reg is_write_op = 0;

    always @(posedge clk or negedge rst_n) begin

        if(!rst_n) begin
            state <= STATE_SETUP;

            read_int <= 0; write_int <= 0; addr_int <= 0;

            data_out_int <= 0; data_write_int <= 0; is_write_op <= 0;
            
        end 
        
        else begin

            read_int <= 0;
            write_int <= 0;

            case(state)

                STATE_SETUP: begin

                    if(byte_sync) begin

                        is_write_op <= data_in[7];

                        addr_int <= data_in[5:0];

                        if(data_in[7] == 1'b0) 
                            read_int <= 1'b1;

                        state <= STATE_DATA;

                    end
                    
                end

                STATE_DATA: begin

                    if(!is_write_op) 
                        data_out_int <= data_read; 

                    else 
                        data_out_int <= 8'b0;

                    if(byte_sync) begin

                        if(is_write_op) begin

                            data_write_int <= data_in;

                            write_int <= 1'b1;

                        end

                        state <= STATE_SETUP;

                    end

                end

            endcase

        end

    end

endmodule
