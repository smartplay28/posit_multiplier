/*
 * File: posit_multiplier_tb.v
 * This is a STRUCTURAL testbench for the 32-bit, es=3 posit multiplier.
 * It does NOT instantiate your top-level wrapper (which is for hardware debug).
 * Instead, it instantiates your three core modules (decoder, multiply, encoder)
 * and wires them together, just like your wrapper does.
 *
 * THIS TESTBENCH IS DESIGNED TO BE EASY TO VALIDATE.
 * The test cases are simple (e.g., 1.0 * 1.0) so you can clearly see
 * the expected result in the waveform.
 */

`timescale 1ns / 1ps

module posit_multiplier_tb;

    // --- Parameters ---
    parameter WIDTH = 32;
    parameter ES = 3;

    // --- Testbench Signals ---
    reg clk;
    reg rst_n;
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    wire [WIDTH-1:0] res; // This is the final result from the encoder

    // --- Internal Wires (to connect the modules) ---
    // Wires from decoders
    wire sign_a, sign_b;
    wire signed [5:0] regime_a, regime_b;
    wire [ES-1:0] exp_a, exp_b;
    wire [WIDTH-ES-1:0] frac_a, frac_b; // From your decoder
    wire is_NaR_a, is_NaR_b, is_zero_a, is_zero_b;

    // Wires from multiplier
    wire sign_result;
    wire signed [6:0] regime_result;
    wire [ES-1:0] exp_result;
    wire [WIDTH-ES-2:0] frac_result; // From your multiplier
    wire is_NaR_result_pipe, is_zero_result_pipe;


    //================================================================
    // 1. DECODER Instantiations (Combinational)
    //================================================================
    posit_decoder #(WIDTH, ES) decoder_a (
        .posit(a),
        .sign(sign_a),
        .regime(regime_a),
        .exponent(exp_a),
        .fraction(frac_a), 
        .is_NaR(is_NaR_a),
        .is_zero(is_zero_a)
        // Note: Your decoder module did not have abs_posit as an output
        // so it is not connected here, matching your top module.
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

    //================================================================
    // 2. MULTIPLY Instantiation (3-Stage Pipeline)
    //================================================================
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

    //================================================================
    // 3. ENCODER Instantiation (Combinational)
    //================================================================
    posit_encoder #(WIDTH, ES) encoder (
        .sign(sign_result),
        .regime(regime_result),
        .exponent(exp_result),
        .fraction(frac_result),
        .is_NaR(is_NaR_result_pipe),
        .is_zero(is_zero_result_pipe),
        .res(res) // The final output
        // Note: Your encoder module does not have a clk input
        // so it is not connected here.
    );


    //================================================================
    // 4. Clock Generator
    //================================================================
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk; // 10ns period (100MHz)


    //================================================================
    // 5. Test Vector Stimulus
    //================================================================
    initial begin
        // For n=32, es=3:
        // Posit(1.0)  = 32'h4000_0000
        // Posit(2.0)  = 32'h4400_0000
        // Posit(4.0)  = 32'h4800_0000
        // Posit(-1.0) = 32'hC000_0000 (Two's complement of 1.0)
        // Posit(0)    = 32'h0000_0000
        // Posit(NaR)  = 32'h8000_0000

        // --- Initialize and Reset ---
        a = 32'h0;
        b = 32'h0;
        rst_n = 1'b0; // Assert reset
        #20;
        rst_n = 1'b1; // De-assert reset
        #10;
        
        // --- TEST 1: 1.0 * 1.0 = 1.0 ---
        // Expect res = 32'h4000_0000 after pipeline delay
        a = 32'h4000_0000;
        b = 32'h4000_0000;
        #40; // Wait 4 clock cycles

        // --- TEST 2: 2.0 * 2.0 = 4.0 ---
        // Expect res = 32'h4800_0000 after pipeline delay
        a = 32'h4400_0000;
        b = 32'h4400_0000;
        #40; // Wait 4 clock cycles

        // --- TEST 3: 1.0 * -1.0 = -1.0 ---
        // Expect res = 32'hC000_0000 after pipeline delay
        a = 32'h4000_0000;
        b = 32'hC000_0000;
        #40; // Wait 4 clock cycles

        // --- TEST 4: 0.0 * 4.0 = 0.0 ---
        // Expect res = 32'h0000_0000 after pipeline delay
        a = 32'h0000_0000;
        b = 32'h4800_0000;
        #40; // Wait 4 clock cycles
        
        // --- TEST 5: NaR * 4.0 = NaR ---
        // Expect res = 32'h8000_0000 after pipeline delay
        a = 32'h8000_0000; // NaR
        b = 32'h4800_0000; // 4.0
        #40; // Wait 4 clock cycles
        
        // --- TEST 6: 4.0 * NaR = NaR ---
        // Expect res = 32'h8000_0000 after pipeline delay
        a = 32'h4800_0000; // 4.0
        b = 32'h8000_0000; // NaR
        #40; // Wait 4 clock cycles

        #100; // Extra time at the end
        $finish; // End simulation
    end
    
    // --- VCD Waveform Dump (Optional, but recommended) ---
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, posit_multiplier_tb);
    end

endmodule