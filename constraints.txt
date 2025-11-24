## 1. CLOCK SIGNAL (Crucial! The ILA won't work without this)
## Use W5 for Basys 3, Use E3 for Nexys A7
set_property PACKAGE_PIN W5 [get_ports clk]							
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]


## 2. BYPASS ERRORS FOR MISSING PINS
## Since you are using VIO, you don't have physical pins for 'a' and 'b'.
## These lines tell Vivado: "It's okay, don't stop the bitstream."
set_property BITSTREAM.GENERAL.UNCONSTRAINEDPINS {Allow} [current_design]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

## 3. VOLTAGE CONFIG (Standard for Artix-7)
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]