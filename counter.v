module counter (
    input wire clk,                  // Ceasul sistemului (10MHz conform cerintei)
    input wire rst_n,                // Reset asincron activ pe 0
    
    // Semnale de control si date venite din regs.v
    input wire [15:0] period,        // Valoarea perioadei (Registrul PERIOD)
    input wire [7:0] prescale,       // Valoarea de scalare (Registrul PRESCALE)
    input wire counter_en,           // Bit de activare (Registrul COUNTER_EN)
    input wire counter_reset,        // Bit de reset soft (Registrul COUNTER_RESET)
    input wire upnotdown,            // Directia de numarare (Registrul UPNOTDOWN)
    
    // Iesiri catre pwm_gen.v si regs.v
    output reg [15:0] counter_val    // Valoarea curenta a numaratorului
);

    // -------------------------------------------------------------------------
    // 1. Definirea Registrelor Interne (Active / Shadow Registers)
    // -------------------------------------------------------------------------
    // Cerinta specifica: Valorile se schimba doar la overflow/underflow.
    // Astfel, avem nevoie de registre interne care tin minte configuratia curenta
    // si se actualizeaza doar cand ciclul este gata.
    reg [15:0] active_period;
    reg [7:0]  active_prescale;
    reg        active_upnotdown;

    // Contor intern pentru prescaler
    // Prescalerul este de tip 2^N. Un registru de 32 biti este suficient 
    // pentru a acoperi shiftari rezonabile (desi prescale e 8 biti, in practica nu se shifteaza cu 255).
    reg [31:0] prescale_cnt; 
    
    // Semnal intern pentru a marca momentul de update (overflow/underflow)
    reg update_event; 

    // Calculam limita prescalerului: 2 la puterea active_prescale
    // Folosim valoarea 'activa', nu cea de la intrare direct.
    wire [31:0] prescale_limit;
    assign prescale_limit = (32'd1 << active_prescale); 

    // Semnal care indica un "tick" valid de numarare pentru contorul principal
    wire tick_enable;
    
    // Logică pentru generarea tick-ului de la prescaler
    // Tick-ul se genereaza cand contorul intern atinge (Limita - 1)
    assign tick_enable = (prescale_cnt >= (prescale_limit - 32'd1));

    // -------------------------------------------------------------------------
    // 2. Logica Secventiala Principala
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset Hardware Asincron
            counter_val      <= 16'd0;
            prescale_cnt     <= 32'd0;
            active_period    <= 16'd0;
            active_prescale  <= 8'd0;
            active_upnotdown <= 1'b1;
            update_event     <= 1'b0;
        end else begin
            // Reset Software (Sincron) - Reseteaza doar numaratoarea, nu configuratia
            // Conform cerintei: "COUNTER_RESET va rescrie toti registrii de numarare"
            if (counter_reset) begin
                counter_val      <= 16'd0;
                prescale_cnt     <= 32'd0;
                // La reset fortat, incarcam si noile configuratii imediat
                active_period    <= period;
                active_prescale  <= prescale;
                active_upnotdown <= upnotdown;
                update_event     <= 1'b0;
            end 
            else if (counter_en) begin
                // ---------------- Prescaler Logic ----------------
                if (tick_enable) begin
                    prescale_cnt <= 32'd0; // Resetam prescalerul
                    
                    // ---------------- Main Counter Logic ----------------
                    // Aici actualizam contorul principal bazat pe directie
                    
                    if (active_upnotdown) begin // Numarare Crescatoare (UP)
                        if (counter_val >= active_period) begin
                            // Overflow: Am atins perioada, resetam la 0
                            counter_val  <= 16'd0;
                            update_event <= 1'b1; // Marcam eveniment pentru update config
                        end else begin
                            counter_val  <= counter_val + 16'd1;
                            update_event <= 1'b0;
                        end
                    end else begin // Numarare Descrescatoare (DOWN)
                        if (counter_val == 16'd0) begin
                            // Underflow: Am atins 0, incarcam perioada
                            counter_val  <= active_period;
                            update_event <= 1'b1; // Marcam eveniment pentru update config
                        end else begin
                            counter_val  <= counter_val - 16'd1;
                            update_event <= 1'b0;
                        end
                    end
                    
                    // ---------------- Update Logic ----------------
                    // Dacă tocmai am avut un overflow/underflow (ciclu complet),
                    // actualizam parametrii activi cu noile valori de la intrari.
                    if (update_event) begin
                        active_period    <= period;
                        active_prescale  <= prescale;
                        active_upnotdown <= upnotdown;
                        // Resetam flag-ul
                        update_event <= 1'b0; 
                    end
                    
                end else begin
                    // Daca prescalerul nu a terminat, doar incrementam contorul intern
                    prescale_cnt <= prescale_cnt + 32'd1;
                    update_event <= 1'b0; // Asiguram ca update_event e puls scurt (sau gestionat pe tick)
                end
            end else begin
                // Cand COUNTER_EN = 0, putem actualiza registrii imediat (sau ii pastram)
                // Cerinta spune "valorile se schimba cand... se va opri". 
                // Deci cand e oprit, actualizam configuratia imediat.
                active_period    <= period;
                active_prescale  <= prescale;
                active_upnotdown <= upnotdown;
            end
        end
    end

endmodule
