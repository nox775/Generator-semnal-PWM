module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing 
    output reg byte_sync,
    output reg [7:0] data_in,
    input[7:0] data_out
);

    reg [2:0] bit_cnt = 0;      
    reg [7:0] rx_shift = 0;     
    reg [7:0] tx_shift = 0;     
    reg spi_done_toggle = 0;    

    always @(posedge sclk or posedge cs_n or negedge rst_n) begin

        if (!rst_n) begin

            bit_cnt <= 0; rx_shift <= 0; spi_done_toggle <= 0; 

        end else if (cs_n) begin

            bit_cnt <= 0; 

        end else begin

            rx_shift <= {rx_shift[6:0], mosi};

            bit_cnt <= bit_cnt + 1;

            if (bit_cnt == 3'b111) spi_done_toggle <= ~spi_done_toggle;

        end

    end

    always @(negedge sclk or posedge cs_n or negedge rst_n) begin

        if (!rst_n) begin

            tx_shift <= 0;

        end else if (cs_n) begin

            tx_shift <= data_out; 

        end else begin

            if (bit_cnt == 3'b001) begin

                // Încărcăm restul de 7 biți (Bit 6..0) și un 0 la coadă

                tx_shift <= {data_out[6:0], 1'b0}; 

            end else begin

                tx_shift <= {tx_shift[6:0], 1'b0};

            end

        end

    end

    wire miso_bit = (bit_cnt == 3'b000) ? data_out[7] : tx_shift[7];

    assign miso = (!cs_n) ? miso_bit : 1'bz;

    reg spi_done_r1 = 0, spi_done_r2 = 0, spi_done_r3 = 0;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            byte_sync <= 0; data_in <= 0; 

            spi_done_r1 <= 0; spi_done_r2 <= 0; spi_done_r3 <= 0;

        end else begin

            spi_done_r1 <= spi_done_toggle;

            spi_done_r2 <= spi_done_r1;

            spi_done_r3 <= spi_done_r2;



            if (spi_done_r2 != spi_done_r3) begin

                byte_sync <= 1'b1;      

                data_in <= rx_shift;    

            end else begin

                byte_sync <= 1'b0;

            end

        end

    end

endmodule
