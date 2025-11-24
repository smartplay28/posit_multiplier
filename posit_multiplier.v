`timescale 1ns / 1ps

//================================================================
// Top-Level Wrapper
//================================================================
module posit_multiplier #(
    parameter WIDTH = 32,
    parameter ES = 3
) (
    input wire clk
);

    reg [2:0] clk_counter = 3'b000;
    wire slow_clk;

    always @(posedge clk) begin
        clk_counter <= clk_counter + 1;
    end

    BUFG clk_buf_inst (
        .I(clk_counter[2]),
        .O(slow_clk)
    );

    wire rst_n; 
    wire [WIDTH-1:0] a; 
    wire [WIDTH-1:0] b; 
    wire [WIDTH-1:0] res; 
    
    vio_0 your_vio_instance (
      .clk(slow_clk),
      .probe_out0(a),
      .probe_out1(b),
      .probe_out2(rst_n)
    );
    
    ila_0 your_ila_instance (
        .clk(slow_clk),
        .probe0(res)
    );
    
    wire sign_a, sign_b;
    wire signed [5:0] regime_a, regime_b;
    wire [ES-1:0] exp_a, exp_b;
    wire [WIDTH-ES:0] frac_a, frac_b;
    wire is_NaR_a, is_NaR_b, is_zero_a, is_zero_b;

    wire sign_result;
    wire signed [6:0] regime_result;
    wire [ES-1:0] exp_result;
    wire [WIDTH-ES-2:0] frac_result;
    wire is_NaR_result_pipe, is_zero_result_pipe;

    posit_decoder #(WIDTH, ES) decoder_a (
        .posit(a),
        .sign(sign_a),
        .regime(regime_a),
        .exponent(exp_a),
        .fraction(frac_a), 
        .is_NaR(is_NaR_a),
        .is_zero(is_zero_a)
    );

    posit_decoder #(WIDTH, ES) decoder_b (
        .posit(b),
        .sign(sign_b),
        .regime(regime_b),
        .exponent(exp_b),
        .fraction(frac_b), 
        .is_NaR(is_NaR_b),
        .is_zero(is_zero_b)
    );

    posit_multiply #(WIDTH, ES) multiplier (
        .clk(slow_clk),
        .rst_n(rst_n), 
        .sign_a(sign_a),
        .regime_a(regime_a),
        .exp_a(exp_a),
        .frac_a(frac_a),
        .is_NaR_a(is_NaR_a),
        .is_zero_a(is_zero_a),
        .sign_b(sign_b),
        .regime_b(regime_b),
        .exp_b(exp_b),
        .frac_b(frac_b),
        .is_NaR_b(is_NaR_b),
        .is_zero_b(is_zero_b),
        .sign_result(sign_result),
        .regime_result(regime_result),
        .exp_result(exp_result),
        .frac_result(frac_result), 
        .is_NaR_result(is_NaR_result_pipe), 
        .is_zero_result(is_zero_result_pipe)
    );

    posit_encoder #(WIDTH, ES) encoder (
        .sign(sign_result),
        .regime(regime_result),
        .exponent(exp_result),
        .fraction(frac_result),
        .is_NaR(is_NaR_result_pipe),
        .is_zero(is_zero_result_pipe),
        .res(res) 
    );

endmodule

//================================================================
// Decoder Module
//================================================================
module posit_decoder #(
    parameter WIDTH = 32,
    parameter ES = 3
) (
    input wire [WIDTH-1:0] posit,
    output wire sign,
    output reg signed [5:0] regime,
    output reg [ES-1:0] exponent,
    output reg [WIDTH-ES:0] fraction,
    output wire is_NaR,
    output wire is_zero
);

    wire [WIDTH-1:0] abs_posit;
    wire regime_sign;
    reg [5:0] count_reg;
    wire [WIDTH-1:0] shifted_posit;
    reg [5:0] shift_amount;

    assign sign = posit[WIDTH-1];
    assign is_NaR = (posit == {1'b1, {(WIDTH-1){1'b0}}});
    assign is_zero = (posit == 0);
    assign abs_posit = sign ? -posit : posit;
    
    assign regime_sign = abs_posit[WIDTH-2];

    always @(*) begin
        if (abs_posit[29] != regime_sign) count_reg = 1;
        else if (abs_posit[28] != regime_sign) count_reg = 2;
        else if (abs_posit[27] != regime_sign) count_reg = 3;
        else if (abs_posit[26] != regime_sign) count_reg = 4;
        else if (abs_posit[25] != regime_sign) count_reg = 5;
        else if (abs_posit[24] != regime_sign) count_reg = 6;
        else if (abs_posit[23] != regime_sign) count_reg = 7;
        else if (abs_posit[22] != regime_sign) count_reg = 8;
        else if (abs_posit[21] != regime_sign) count_reg = 9;
        else if (abs_posit[20] != regime_sign) count_reg = 10;
        else if (abs_posit[19] != regime_sign) count_reg = 11;
        else if (abs_posit[18] != regime_sign) count_reg = 12;
        else if (abs_posit[17] != regime_sign) count_reg = 13;
        else if (abs_posit[16] != regime_sign) count_reg = 14;
        else if (abs_posit[15] != regime_sign) count_reg = 15;
        else if (abs_posit[14] != regime_sign) count_reg = 16;
        else if (abs_posit[13] != regime_sign) count_reg = 17;
        else if (abs_posit[12] != regime_sign) count_reg = 18;
        else if (abs_posit[11] != regime_sign) count_reg = 19;
        else if (abs_posit[10] != regime_sign) count_reg = 20;
        else if (abs_posit[9] != regime_sign) count_reg = 21;
        else if (abs_posit[8] != regime_sign) count_reg = 22;
        else if (abs_posit[7] != regime_sign) count_reg = 23;
        else if (abs_posit[6] != regime_sign) count_reg = 24;
        else if (abs_posit[5] != regime_sign) count_reg = 25;
        else if (abs_posit[4] != regime_sign) count_reg = 26;
        else if (abs_posit[3] != regime_sign) count_reg = 27;
        else if (abs_posit[2] != regime_sign) count_reg = 28;
        else if (abs_posit[1] != regime_sign) count_reg = 29;
        else if (abs_posit[0] != regime_sign) count_reg = 30;
        else count_reg = 31;
    end

    always @(*) begin
        if (regime_sign == 1'b0)
            regime = -count_reg;
        else
            regime = count_reg - 1;
    end

    // Shift left to remove: sign bit (1) + regime bits (count_reg) + terminator (1)
    always @(*) begin
        shift_amount = count_reg + 2;
    end
    
    assign shifted_posit = abs_posit << shift_amount;

    always @(*) begin
        // After shift: exponent is at MSB, then fraction follows
        exponent = shifted_posit[WIDTH-1 : WIDTH-ES];
        
        // Fraction: hidden 1 + remaining bits (total 30 bits)
        fraction = {1'b1, shifted_posit[WIDTH-ES-1 : 0]};
    end

endmodule

//================================================================
// Multiply Module
//================================================================
module posit_multiply #(
    parameter WIDTH = 32,
    parameter ES = 3
) (
    input wire clk,
    input wire rst_n,
    
    input wire sign_a,
    input wire signed [5:0] regime_a,
    input wire [ES-1:0] exp_a,
    input wire [WIDTH-ES:0] frac_a,
    input wire is_NaR_a,
    input wire is_zero_a,
    
    input wire sign_b,
    input wire signed [5:0] regime_b,
    input wire [ES-1:0] exp_b,
    input wire [WIDTH-ES:0] frac_b,
    input wire is_NaR_b,
    input wire is_zero_b,
    
    output reg sign_result,
    output reg signed [6:0] regime_result,
    output reg [ES-1:0] exp_result,
    output reg [WIDTH-ES-2:0] frac_result,
    output reg is_NaR_result,
    output reg is_zero_result
);

    localparam FRAC_WIDTH = WIDTH - ES + 1;
    localparam FRAC_PROD_WIDTH = 2 * FRAC_WIDTH;
    localparam FRAC_OUT_WIDTH = WIDTH - ES - 2;

    reg signed [5:0] regime_a_reg, regime_b_reg;
    reg [ES-1:0] exp_a_reg, exp_b_reg;
    reg [FRAC_WIDTH-1:0] frac_a_reg, frac_b_reg;
    reg sign_a_reg, sign_b_reg;
    reg is_NaR_a_reg, is_NaR_b_reg, is_zero_a_reg, is_zero_b_reg;
    
    reg signed [6:0] regime_sum_raw;
    reg [ES:0] exp_sum_raw; 
    reg [FRAC_PROD_WIDTH-1:0] frac_product_raw;
    reg sign_result_raw;
    reg is_NaR_raw, is_zero_raw;
    
    reg signed [6:0] regime_final;
    reg [ES:0] exp_sum_norm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regime_a_reg <= 0; regime_b_reg <= 0;
            exp_a_reg <= 0;    exp_b_reg <= 0;
            frac_a_reg <= 0;   frac_b_reg <= 0;
            sign_a_reg <= 0;   sign_b_reg <= 0;
            is_NaR_a_reg <= 0; is_NaR_b_reg <= 0;
            is_zero_a_reg <= 0; is_zero_b_reg <= 0;
        end else begin
            regime_a_reg <= regime_a; regime_b_reg <= regime_b;
            exp_a_reg <= exp_a;       exp_b_reg <= exp_b;
            frac_a_reg <= frac_a;     frac_b_reg <= frac_b;
            sign_a_reg <= sign_a;     sign_b_reg <= sign_b;
            is_NaR_a_reg <= is_NaR_a; is_NaR_b_reg <= is_NaR_b;
            is_zero_a_reg <= is_zero_a; is_zero_b_reg <= is_zero_b;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regime_sum_raw <= 0;
            exp_sum_raw <= 0;
            frac_product_raw <= 0;
            sign_result_raw <= 0;
            is_NaR_raw <= 0; is_zero_raw <= 0;
        end else begin
            sign_result_raw <= sign_a_reg ^ sign_b_reg;
            regime_sum_raw <= $signed(regime_a_reg) + $signed(regime_b_reg);
            exp_sum_raw <= {1'b0, exp_a_reg} + {1'b0, exp_b_reg};
            frac_product_raw <= frac_a_reg * frac_b_reg;
            is_NaR_raw <= is_NaR_a_reg | is_NaR_b_reg;
            is_zero_raw <= is_zero_a_reg | is_zero_b_reg;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regime_result <= 0;
            exp_result <= 0;
            frac_result <= 0;
            sign_result <= 0;
            is_NaR_result <= 0; is_zero_result <= 0;
        end else begin
            // 30-bit x 30-bit = 60-bit product [59:0]
            // Product format: XX.XXXX... (2 integer bits, 58 fraction bits)
            if (frac_product_raw[59]) begin
                // Bit 59 = 1: product >= 2.0, normalize by shifting right
                exp_sum_norm = exp_sum_raw + 1;
                // Take 27 fraction bits: [58:32]
                frac_result <= frac_product_raw[58:32];
            end else begin
                // Bit 59 = 0, Bit 58 = 1: product in [1.0, 2.0)
                exp_sum_norm = exp_sum_raw;
                // Take 27 fraction bits: [57:31]
                frac_result <= frac_product_raw[57:31];
            end
            
            // Handle exponent overflow into regime
            if (exp_sum_norm[ES]) begin
                regime_final = regime_sum_raw + 1;
                exp_result <= exp_sum_norm[ES-1:0];
            end else begin
                regime_final = regime_sum_raw;
                exp_result <= exp_sum_norm[ES-1:0];
            end
            
            regime_result <= regime_final;
            sign_result <= sign_result_raw;
            is_NaR_result <= is_NaR_raw;
            is_zero_result <= is_zero_raw;
        end
    end
    
endmodule

//================================================================
// Encoder Module
//================================================================
module posit_encoder #(
    parameter WIDTH = 32,
    parameter ES = 3
) (
    input wire sign,
    input wire signed [6:0] regime,
    input wire [ES-1:0] exponent,
    input wire [WIDTH-ES-2:0] fraction,
    input wire is_NaR,
    input wire is_zero,
    output reg [WIDTH-1:0] res
);

    localparam FRAC_WIDTH = WIDTH - ES - 2; 
    localparam MAX_M = WIDTH - 2; 
    
    reg [$clog2(MAX_M+1)-1:0] m; 
    reg [$clog2(MAX_M+1)-1:0] i;
    reg signed [$clog2(WIDTH):0] bit_index; 
    reg [WIDTH-1:0] abs_posit;
    
    integer i_exp, i_frac; 

    always @(*) begin
        if (is_NaR) begin
            res = {1'b1, {(WIDTH-1){1'b0}}};
        end else if (is_zero) begin
            res = {WIDTH{1'b0}};
        end else begin
            
            if ($signed(regime) >= 0)
                m = $signed(regime) + 1;
            else
                m = -$signed(regime);
            
            if (m > MAX_M) m = MAX_M;

            abs_posit = 0; 
            bit_index = WIDTH - 2; 

            if ($signed(regime) >= 0) begin
                for(i=0; i < m; i=i+1) begin
                    if (bit_index >= 0) abs_posit[bit_index] = 1'b1;
                    bit_index = bit_index - 1;
                end
                if (bit_index >= 0) abs_posit[bit_index] = 1'b0; 
                bit_index = bit_index - 1;
            end else begin
                for(i=0; i < m; i=i+1) begin
                    if (bit_index >= 0) abs_posit[bit_index] = 1'b0;
                    bit_index = bit_index - 1;
                end
                if (bit_index >= 0) abs_posit[bit_index] = 1'b1; 
                bit_index = bit_index - 1;
            end

            for(i_exp=ES-1; i_exp >= 0; i_exp=i_exp-1) begin
                if (bit_index >= 0) abs_posit[bit_index] = exponent[i_exp];
                bit_index = bit_index - 1;
            end

            for(i_frac=FRAC_WIDTH-1; i_frac >= 0; i_frac=i_frac-1) begin
                if (bit_index >= 0) abs_posit[bit_index] = fraction[i_frac];
                bit_index = bit_index - 1;
            end
            
            if (sign)
                res = -abs_posit;
            else
                res = abs_posit;
        end
    end 
endmodule
