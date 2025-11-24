`timescale 1ns / 1ps

//================================================================
// TESTBENCH WITH ENHANCED TEST CASES
//================================================================
module posit_multiplier_tb;

    parameter WIDTH = 32;
    parameter ES = 3;

    reg clk;
    reg rst_n;
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    wire [WIDTH-1:0] res;

    // *** FIX 1: Wire widths must match decoder output ***
    wire sign_a, sign_b;
    wire signed [5:0] regime_a, regime_b;
    wire [ES-1:0] exp_a, exp_b;
    wire [WIDTH-ES:0] frac_a, frac_b; // Changed from [WIDTH-ES-1:0] to [WIDTH-ES:0]
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
        .clk(clk),
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

    initial begin
        clk = 0;
    end
    always #5 clk = ~clk;

    initial begin
        // Enhanced test cases with floating-point variations
        a = 32'h0;
        b = 32'h0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;
        
        // TEST 1: 1.0 * 1.0 = 1.0
        $display("TEST 1: 1.0 * 1.0");
        a = 32'h4000_0000;
        b = 32'h4000_0000;
        #40;
        $display("Result: %h (Expected: 40000000)", res);

        // TEST 2: 2.0 * 2.0 = 4.0
        $display("TEST 2: 2.0 * 2.0");
        a = 32'h4400_0000;
        b = 32'h4400_0000;
        #40;
        $display("Result: %h (Expected: 48000000)", res);

        // TEST 3: 1.5 * 2.0 = 3.0
        $display("TEST 3: 1.5 * 2.0");
        a = 32'h4200_0000; // 1.5
        b = 32'h4400_0000; // 2.0
        #40;
        $display("Result: %h (Expected: 46000000)", res);

      

        // TEST 5: 1.0 * -1.0 = -1.0
        $display("TEST 5: 1.0 * -1.0");
        a = 32'h4000_0000;
        b = 32'hC000_0000;
        #40;
        $display("Result: %h (Expected: C0000000)", res);

       
        // TEST 7: 0.0 * 4.0 = 0.0
        $display("TEST 7: 0.0 * 4.0");
        a = 32'h0000_0000;
        b = 32'h4800_0000;
        #40;
        $display("Result: %h (Expected: 00000000)", res);
        
       
        // TEST 9: 4.0 * NaR = NaR
        $display("TEST 9: 4.0 * NaR");
        a = 32'h4800_0000;
        b = 32'h8000_0000;
        #40;
        $display("Result: %h (Expected: 80000000)", res);

        #100;
        $finish;
    end
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, posit_multiplier_tb);
    end

endmodule
