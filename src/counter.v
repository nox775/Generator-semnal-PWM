module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output reg [15:0] count_val, // Am adaugat 'reg' pentru a putea scrie in el
    input [15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input [7:0] prescale
);

    // --- Registre Interne (Shadow Registers) ---
    // Acestea retin configuratia curenta si se schimba doar la sfarsit de ciclu
    reg [15:0] active_period;
    reg [7:0]  active_prescale;
    reg        active_upnotdown;

    // --- Logica Prescaler ---
    // Contor pe 32 biti pentru a gestiona divizarea ceasului
    reg [31:0] prescale_cnt; 
    wire [31:0] prescale_limit;
    
    // Prescaler exponential: 2^active_prescale
    assign prescale_limit = (32'd1 << active_prescale); 
    
    // Semnalul de tick (activare incrementare)
    wire tick_enable;
    assign tick_enable = (prescale_cnt >= (prescale_limit - 32'd1));

    // Semnal intern pentru update-ul registrelor shadow
    reg update_event; 

    // --- Logica Principala ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset Asincron (Hardware)
            count_val        <= 16'd0;
            prescale_cnt     <= 32'd0;
            active_period    <= 16'd0;
            active_prescale  <= 8'd0;
            active_upnotdown <= 1'b1;
            update_event     <= 1'b0;
        end else begin
            // Reset Sincron (Software - count_reset)
            if (count_reset) begin
                count_val        <= 16'd0;
                prescale_cnt     <= 32'd0;
                // Incarcam configuratia imediat la reset
                active_period    <= period;
                active_prescale  <= prescale;
                active_upnotdown <= upnotdown;
                update_event     <= 1'b0;
            end 
            else if (en) begin
                // Modulul este activ
                if (tick_enable) begin
                    prescale_cnt <= 32'd0; // Resetam prescalerul
                    
                    // Logica Up/Down
                    if (active_upnotdown) begin 
                        // Numarare UP
                        if (count_val >= active_period) begin
                            count_val    <= 16'd0;
                            update_event <= 1'b1; // Marcam overflow
                        end else begin
                            count_val    <= count_val + 16'd1;
                            update_event <= 1'b0;
                        end
                    end else begin 
                        // Numarare DOWN
                        if (count_val == 16'd0) begin
                            count_val    <= active_period;
                            update_event <= 1'b1; // Marcam underflow
                        end else begin
                            count_val    <= count_val - 16'd1;
                            update_event <= 1'b0;
                        end
                    end
                    
                    // Actualizam registrele shadow daca a fost un ciclu complet
                    if (update_event) begin
                        active_period    <= period;
                        active_prescale  <= prescale;
                        active_upnotdown <= upnotdown;
                        update_event     <= 1'b0;
                    end
                    
                end else begin
                    // Asteptam prescalerul
                    prescale_cnt <= prescale_cnt + 32'd1;
                    update_event <= 1'b0;
                end
            end else begin
                // Daca en = 0, actualizam registrele imediat (idle state)
                active_period    <= period;
                active_prescale  <= prescale;
                active_upnotdown <= upnotdown;
            end
        end
    end

endmodule
