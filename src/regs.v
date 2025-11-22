/* ALEX ----
 * Modulul 'regs' implementează interfața de regiștrii pentru
 * un periferic de tip Timer/Counter/PWM.
 *
 * Acesta gestionează citirile și scrierile de pe magistrala
 * de date (data_write, data_read) pe baza adresei (addr)
 * și a semnalelor de control (read, write).
 */
module regs (
    // Semnale ceas și reset
    input clk,
    input rst_n,

    // Semnale interfață decodor (bus)
    input read,
    input write,
    input[5:0] addr,
    output reg[7:0] data_read, // Ieșirea de citire, declarată 'reg' pentru logica combinațională
    input[7:0] data_write,

    // Semnale de programare counter
    input[15:0] counter_val,  // Valoarea curentă a numărătorului (doar citire)
    output reg[15:0] period,
    output reg en,
    output reg count_reset,
    output reg upnotdown,
    output reg[7:0] prescale,

    // Semnale de programare PWM
    output reg pwm_en,
    output reg[1:0] functions, // Am folosit [1:0] conform descrierii (2 biți)
    output reg[15:0] compare1,
    output reg[15:0] compare2
);

/*
 * ====================================================================
 * Blocul Sincron - Logica de Scriere și Starea Regiștrilor
 * ====================================================================
 * Acest bloc 'always' este sensibil la frontul pozitiv al ceasului
 * și la frontul negativ (activ pe 0) al reset-ului.
 * Acesta gestionează actualizarea tuturor regiștrilor care pot fi scriși.
 */
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // Stare de reset: toți regiștrii sunt inițializați cu 0
        period      <= 16'h0000;
        en          <= 1'b0;
        compare1    <= 16'h0000;
        compare2    <= 16'h0000;
        count_reset <= 1'b0;
        prescale    <= 8'h00;
        upnotdown   <= 1'b0;
        pwm_en      <= 1'b0;
        functions   <= 2'b00;
    end
    else begin
        // Logica de funcționare normală
        
        // Resetarea lui 'count_reset' în ciclul următor scrierii.
        // Acesta este un registru de tip "write-to-trigger".
        count_reset <= 1'b0;

        if(write) begin
            // Un semnal de scriere este activ
            case(addr)
                // PERIOD [15:0] @ 0x00 (LSB), 0x01 (MSB)
                6'h00: period[7:0]   <= data_write;
                6'h01: period[15:8]  <= data_write;

                // COUNTER_EN [0] @ 0x02
                6'h02: en <= data_write[0];

                // COMPARE1 [15:0] @ 0x03 (LSB), 0x04 (MSB)
                6'h03: compare1[7:0]  <= data_write;
                6'h04: compare1[15:8] <= data_write;

                // COMPARE2 [15:0] @ 0x05 (LSB), 0x06 (MSB)
                6'h05: compare2[7:0]  <= data_write;
                6'h06: compare2[15:8] <= data_write;

                // COUNTER_RESET [0] @ 0x07 (Write-Only)
                6'h07: count_reset <= 1'b1; // Se activează pe scris

                // PRESCALE [7:0] @ 0x0A
                6'h0A: prescale <= data_write;

                // UPNOTDOWN [0] @ 0x0B
                6'h0B: upnotdown <= data_write[0];

                // PWM_EN [0] @ 0x0C
                6'h0C: pwm_en <= data_write[0];

                // FUNCTIONS [1:0] @ 0x0D
                6'h0D: functions <= data_write[1:0];

                // Adresele care nu sunt mapate sunt ignorate la scriere
                default: begin
                   // Nu se întâmplă nimic
                end
            endcase
        end
    end
end


/*
 * ====================================================================
 * Blocul Combinațional - Logica de Citire
 * ====================================================================
 * Acest bloc 'always' este pur combinațional.
 * Acesta setează ieșirea 'data_read' pe baza adresei 'addr'
 * atunci când semnalul 'read' este activ.
 */
always@(*) begin
    // Valoarea implicită pentru 'data_read' este 0.
    // Aceasta este valoarea returnată pentru adrese nemapate.
    data_read = 8'h00;

    if(read) begin
        // Un semnal de citire este activ
        case(addr)
            // PERIOD [15:0] @ 0x00 (LSB), 0x01 (MSB)
            6'h00: data_read = period[7:0];
            6'h01: data_read = period[15:8];

            // COUNTER_EN [0] @ 0x02
            6'h02: data_read = {7'b0, en};

            // COMPARE1 [15:0] @ 0x03 (LSB), 0x04 (MSB)
            6'h03: data_read = compare1[7:0];
            6'h04: data_read = compare1[15:8];

            // COMPARE2 [15:0] @ 0x05 (LSB), 0x06 (MSB)
            6'h05: data_read = compare2[7:0];
            6'h06: data_read = compare2[15:8];

            // COUNTER_RESET [0] @ 0x07 (Write-Only)
            6'h07: data_read = 8'h00; // Citirea returnează 0

            // COUNTER_VAL [15:0] @ 0x08 (LSB), 0x09 (MSB) (Read-Only)
            6'h08: data_read = counter_val[7:0];
            6'h09: data_read = counter_val[15:8];

            // PRESCALE [7:0] @ 0x0A
            6'h0A: data_read = prescale;

            // UPNOTDOWN [0] @ 0x0B
            6'h0B: data_read = {7'b0, upnotdown};

            // PWM_EN [0] @ 0x0C
            6'h0C: data_read = {7'b0, pwm_en};

            // FUNCTIONS [1:0] @ 0x0D
            6'h0D: data_read = {6'b0, functions};
            
            // Adresele care nu sunt mapate returnează 0 (setat implicit)
            default: data_read = 8'h00;
        endcase
    end
end

endmodule