`timescale 1ns/1ps
//=============================================================================
// File        : v8m_pacbti_mock.sv
// Description : ARMv8-M PACBTI/TrustZone Mock DUT for Verification
//=============================================================================
module v8m_pacbti_mock (
    input  logic        clk,
    input  logic        rst_n,
    // AHB-Lite slave interface
    input  logic [31:0] HADDR,
    input  logic [2:0]  HBURST,
    input  logic        HMASTLOCK,
    input  logic [3:0]  HPROT,
    input  logic [2:0]  HSIZE,
    input  logic [1:0]  HTRANS,
    input  logic [31:0] HWDATA,
    input  logic        HWRITE,
    output logic [31:0] HRDATA,
    output logic        HREADYOUT,
    output logic        HRESP,
    // PAC/BTI signals
    input  logic        pac_enable,
    input  logic        bti_enable,
    input  logic [31:0] pac_key_lo,
    input  logic [31:0] pac_key_hi,
    output logic        pac_valid,
    output logic        bti_valid,
    output logic        pac_auth_pass,
    output logic        pac_auth_fail,
    // TrustZone signals
    input  logic        tz_enable,
    input  logic        ns_access,
    input  logic [31:0] sau_base,
    input  logic [31:0] sau_limit,
    input  logic        sau_nsc,
    output logic        tz_fault,
    // CPU state
    input  logic [3:0]  privilege_mode,
    input  logic [31:0] current_pc,
    input  logic [31:0] lr_value,
    output logic        secure_state,
    output logic        fault_active,
    output logic [7:0]  fault_code
);

    // Internal PAC engine — simplified QARMA-like hash
    logic [63:0] pac_key;
    logic [31:0] pac_signature;
    logic [31:0] mem [0:1023];  // 4KB mock memory
    logic [31:0] addr_reg;
    logic        write_reg;

    assign pac_key = {pac_key_hi, pac_key_lo};

    // PAC signature generation (simplified)
    assign pac_signature = current_pc ^ pac_key[31:0] ^ pac_key[63:32] ^ lr_value;

    // PAC valid/auth logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pac_valid      <= 1'b0;
            pac_auth_pass  <= 1'b0;
            pac_auth_fail  <= 1'b0;
            bti_valid      <= 1'b0;
        end else begin
            pac_valid     <= pac_enable;
            bti_valid     <= bti_enable;
            pac_auth_pass <= pac_enable && (pac_signature[7:0] != 8'hFF);
            pac_auth_fail <= pac_enable && (pac_signature[7:0] == 8'hFF);
        end
    end

    // TrustZone SAU region check
    logic in_sau_region;
    assign in_sau_region = (HADDR >= sau_base) && (HADDR <= sau_limit);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            secure_state <= 1'b1;   // Boot in Secure world
            tz_fault     <= 1'b0;
        end else if (tz_enable) begin
            secure_state <= ~ns_access;
            tz_fault     <= ns_access && in_sau_region && !sau_nsc;
        end else begin
            secure_state <= 1'b1;
            tz_fault     <= 1'b0;
        end
    end

    // Fault logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_active <= 1'b0;
            fault_code   <= 8'h00;
        end else begin
            if (pac_auth_fail) begin
                fault_active <= 1'b1;
                fault_code   <= 8'h01;  // PAC auth failure
            end else if (tz_fault) begin
                fault_active <= 1'b1;
                fault_code   <= 8'h02;  // TZ boundary fault
            end else if (privilege_mode == 4'h0 && HPROT[0]) begin
                fault_active <= 1'b1;
                fault_code   <= 8'h03;  // Privilege violation
            end else begin
                fault_active <= 1'b0;
                fault_code   <= 8'h00;
            end
        end
    end

    // AHB-Lite memory interface
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
            HRDATA    <= 32'h0;
            addr_reg  <= 32'h0;
            write_reg <= 1'b0;
        end else begin
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
            addr_reg  <= HADDR;
            write_reg <= HWRITE && (HTRANS != 2'b00);
            if (write_reg && addr_reg[11:2] < 1024)
                mem[addr_reg[11:2]] <= HWDATA;
            if (!HWRITE && HTRANS != 2'b00 && HADDR[11:2] < 1024)
                HRDATA <= mem[HADDR[11:2]];
            else
                HRDATA <= 32'hDEAD_BEEF;
        end
    end

endmodule : v8m_pacbti_mock
