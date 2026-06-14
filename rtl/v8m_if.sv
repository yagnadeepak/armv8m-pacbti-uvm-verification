`timescale 1ns/1ps
//=============================================================================
// File        : v8m_if.sv
// Description : ARMv8-M PACBTI/TrustZone AHB-Lite Interface
//=============================================================================
interface v8m_if (input logic clk, input logic rst_n);

    // AHB-Lite signals
    logic [31:0]  HADDR;
    logic [2:0]   HBURST;
    logic         HMASTLOCK;
    logic [3:0]   HPROT;
    logic [2:0]   HSIZE;
    logic [1:0]   HTRANS;
    logic [31:0]  HWDATA;
    logic         HWRITE;
    logic [31:0]  HRDATA;
    logic         HREADYOUT;
    logic         HRESP;

    // PACBTI control signals
    logic         pac_enable;
    logic         bti_enable;
    logic         pac_valid;
    logic         bti_valid;
    logic [31:0]  pac_key_lo;
    logic [31:0]  pac_key_hi;
    logic         pac_auth_pass;
    logic         pac_auth_fail;

    // TrustZone signals
    logic         tz_enable;
    logic         ns_access;       // 0=Secure, 1=Non-Secure
    logic [31:0]  sau_base;
    logic [31:0]  sau_limit;
    logic         sau_nsc;         // Non-Secure Callable
    logic         tz_fault;

    // CPU state signals
    logic [3:0]   privilege_mode;  // 0=Thread, 1=Handler, 2=Supervisor
    logic         secure_state;    // 1=Secure world
    logic [31:0]  current_pc;
    logic [31:0]  lr_value;
    logic         fault_active;
    logic [7:0]   fault_code;

    // Clocking block for testbench
    clocking cb @(posedge clk);
        default input #1step output #1;
        input  HRDATA, HREADYOUT, HRESP;
        input  pac_auth_pass, pac_auth_fail, tz_fault;
        input  secure_state, fault_active, fault_code;
        output HADDR, HBURST, HMASTLOCK, HPROT, HSIZE, HTRANS, HWDATA, HWRITE;
        output pac_enable, bti_enable, pac_key_lo, pac_key_hi;
        output tz_enable, ns_access, sau_base, sau_limit, sau_nsc;
        output privilege_mode, current_pc, lr_value;
    endclocking

    modport master (clocking cb, input clk, rst_n);
    modport slave  (input HADDR, HBURST, HMASTLOCK, HPROT, HSIZE, HTRANS, HWDATA, HWRITE,
                          pac_enable, bti_enable, pac_key_lo, pac_key_hi,
                          tz_enable, ns_access, sau_base, sau_limit, sau_nsc,
                          privilege_mode, current_pc, lr_value,
                    output HRDATA, HREADYOUT, HRESP,
                           pac_valid, bti_valid, pac_auth_pass, pac_auth_fail,
                           tz_fault, secure_state, fault_active, fault_code);

endinterface : v8m_if
