`timescale 1ns/1ps
//=============================================================================
// File        : tb_top.sv
// Description : Top-level testbench for Vivado xsim
//               ARMv8-M PACBTI/TrustZone UVM 1.2 Verification
//
//  UVM 1.2 is pre-compiled in Vivado ML. The -L uvm flag in xelab
//  links it. The includes below pull in all local UVM class files.
//=============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// ---- UVM class files (compiled order matters) ----------------------------
`include "../uvm/sequences/v8m_pacbti_item.sv"
`include "../uvm/sequences/v8m_sequences.sv"
`include "../uvm/agents/v8m_driver.sv"
`include "../uvm/agents/v8m_monitor.sv"
`include "../uvm/agents/v8m_agent.sv"
`include "../uvm/scoreboard/v8m_scoreboard.sv"
`include "../uvm/coverage/v8m_coverage.sv"
`include "../uvm/env/v8m_env.sv"
`include "../uvm/tests/v8m_tests.sv"
// --------------------------------------------------------------------------

module tb_top;

    // Clock and reset
    logic clk;
    logic rst_n;

    // Clock generation — 100 MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Reset sequence
    initial begin
        rst_n = 1'b0;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        `uvm_info("TB_TOP", "Reset released", UVM_MEDIUM)
    end

    // Interface instantiation
    v8m_if dut_if (.clk(clk), .rst_n(rst_n));

    // DUT instantiation
    v8m_pacbti_mock dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .HADDR        (dut_if.HADDR),
        .HBURST       (dut_if.HBURST),
        .HMASTLOCK    (dut_if.HMASTLOCK),
        .HPROT        (dut_if.HPROT),
        .HSIZE        (dut_if.HSIZE),
        .HTRANS       (dut_if.HTRANS),
        .HWDATA       (dut_if.HWDATA),
        .HWRITE       (dut_if.HWRITE),
        .HRDATA       (dut_if.HRDATA),
        .HREADYOUT    (dut_if.HREADYOUT),
        .HRESP        (dut_if.HRESP),
        .pac_enable   (dut_if.pac_enable),
        .bti_enable   (dut_if.bti_enable),
        .pac_key_lo   (dut_if.pac_key_lo),
        .pac_key_hi   (dut_if.pac_key_hi),
        .pac_valid    (dut_if.pac_valid),
        .bti_valid    (dut_if.bti_valid),
        .pac_auth_pass(dut_if.pac_auth_pass),
        .pac_auth_fail(dut_if.pac_auth_fail),
        .tz_enable    (dut_if.tz_enable),
        .ns_access    (dut_if.ns_access),
        .sau_base     (dut_if.sau_base),
        .sau_limit    (dut_if.sau_limit),
        .sau_nsc      (dut_if.sau_nsc),
        .tz_fault     (dut_if.tz_fault),
        .privilege_mode(dut_if.privilege_mode),
        .current_pc   (dut_if.current_pc),
        .lr_value     (dut_if.lr_value),
        .secure_state (dut_if.secure_state),
        .fault_active (dut_if.fault_active),
        .fault_code   (dut_if.fault_code)
    );

    // Register virtual interface in config_db
    initial begin
        uvm_config_db #(virtual v8m_if)::set(null, "uvm_test_top.*", "vif", dut_if);
    end

    // Start UVM test
    initial begin
        run_test();
    end

    // Simulation timeout watchdog
    // 50,000 transactions @ ~10 cycles each @ 10ns = ~5ms minimum
    // Set to 2,000ms (2 seconds simulation time) for publication run
    initial begin
        #2_000_000_000;
        `uvm_fatal("TIMEOUT", "Simulation timeout at 2s — check for deadlock")
    end

endmodule : tb_top