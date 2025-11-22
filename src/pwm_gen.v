    module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input [15:0] period,
    input [7:0] functions,
    input [15:0] compare1,
    input [15:0] compare2,
    input [15:0] count_val,
    // top facing signals
    output reg pwm_out
);
    
    reg [15:0] active_compare1;
    reg [15:0] active_compare2;
    reg [1:0]  active_func;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            active_compare1 <= 16'd0;
            active_compare2 <= 16'd0;
            active_func     <= 2'd0;
        end 
        else begin
            if(!pwm_en || (count_val == 16'd0)) begin
                active_compare1 <= compare1;
                active_compare2 <= compare2;
                active_func <= functions[1:0];
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pwm_out <= 1'b0;
        end 
        else if(!pwm_en) begin
            pwm_out <= 1'b0;
        end 
        else begin
            case (active_func)
                2'b00: begin
                    if(count_val < active_compare1)
                        pwm_out <= 1'b1;
                    else
                        pwm_out <= 1'b0;
                end

                2'b01: begin
                    if(count_val >= active_compare1)
                        pwm_out <= 1'b1;
                    else
                        pwm_out <= 1'b0;
                end
                default: begin
                    if((count_val >= active_compare1) && (count_val < active_compare2))
                        pwm_out <= 1'b1;
                    else
                        pwm_out <= 1'b0;
                end
            endcase
        end
    end
endmodule
