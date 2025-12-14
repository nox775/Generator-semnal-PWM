    module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[1:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output pwm_out
);
    
    // Latched active configuration sampled when inputs change
    reg [15:0] active_compare1;
    reg [15:0] active_compare2;
    reg [1:0]  active_func;
    // Latch configuration when input registers change so writes take effect
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_compare1 <= 16'd0;
            active_compare2 <= 16'd0;
            active_func     <= 2'd0;
        end else if ((compare1  != active_compare1) ||
                     (compare2  != active_compare2) ||
                     (functions[1:0] != active_func)) begin
            active_compare1 <= compare1;
            active_compare2 <= compare2;
            active_func     <= functions[1:0];
        end
    end

    // Compute PWM output combinationally from latched active config
    wire pwm_out_internal;
    assign pwm_out_internal = (pwm_en) &&
        (active_compare1 != active_compare2) && (
            (active_func == 2'b00 ? ((active_compare1 != 16'd0) && (count_val <= active_compare1)) :
             (active_func == 2'b01 ? (count_val >= active_compare1) :
              ((count_val >= active_compare1) && (count_val < active_compare2))))
        );

    assign pwm_out = pwm_out_internal;
endmodule
