//=============================================================================
// File        : v8m_coverage.sv
// Description : UVM 1.2 Coverage Subscriber — PACBTI/TrustZone coverage model
//=============================================================================
class v8m_coverage extends uvm_subscriber #(v8m_pacbti_item);
    `uvm_component_utils(v8m_coverage)

    v8m_pacbti_item item;

    covergroup cg_transaction_types;
        cp_trans_type: coverpoint item.trans_type {
            bins rd        = {v8m_pacbti_item::TRANS_READ};
            bins wr        = {v8m_pacbti_item::TRANS_WRITE};
            bins pac_sign  = {v8m_pacbti_item::TRANS_PAC_SIGN};
            bins pac_auth  = {v8m_pacbti_item::TRANS_PAC_AUTH};
            bins bti_call  = {v8m_pacbti_item::TRANS_BTI_CALL};
            bins bti_jump  = {v8m_pacbti_item::TRANS_BTI_JUMP};
            bins tz_secure = {v8m_pacbti_item::TRANS_TZ_SECURE};
            bins tz_ns     = {v8m_pacbti_item::TRANS_TZ_NONSECURE};
            bins fault_inj = {v8m_pacbti_item::TRANS_FAULT_INJECT};
            bins priv      = {v8m_pacbti_item::TRANS_PRIVILEGE};
        }
        cp_priv_mode: coverpoint item.priv_mode {
            bins thread  = {v8m_pacbti_item::MODE_THREAD};
            bins handler = {v8m_pacbti_item::MODE_HANDLER};
            bins super_m = {v8m_pacbti_item::MODE_SUPER};
        }
        cx_type_x_priv: cross cp_trans_type, cp_priv_mode;
    endgroup

    covergroup cg_pac_coverage;
        cp_pac_en:   coverpoint item.pac_enable  { bins on={1}; bins off={0}; }
        cp_bti_en:   coverpoint item.bti_enable  { bins on={1}; bins off={0}; }
        cp_pac_pass: coverpoint item.exp_pac_pass { bins pass={1}; bins fail={0}; }
        cx_pac_bti:  cross cp_pac_en, cp_bti_en;
        cx_en_result: cross cp_pac_en, cp_pac_pass;
    endgroup

    covergroup cg_trustzone_coverage;
        cp_tz_en:    coverpoint item.tz_enable  { bins on={1}; bins off={0}; }
        cp_ns:       coverpoint item.ns_access  { bins secure={0}; bins nonsecure={1}; }
        cp_sau_nsc:  coverpoint item.sau_nsc    { bins normal={0}; bins callable={1}; }
        cp_tz_fault: coverpoint item.exp_tz_fault { bins fault={1}; bins ok={0}; }
        cx_tz_full:  cross cp_tz_en, cp_ns, cp_sau_nsc, cp_tz_fault;
    endgroup

    covergroup cg_fault_coverage;
        cp_fault_active: coverpoint item.exp_fault_active {
            bins active  = {1};
            bins inactive = {0};
        }
        cp_fault_code: coverpoint item.exp_fault_code {
            bins no_fault  = {8'h00};
            bins pac_fail  = {8'h01};
            bins tz_fault  = {8'h02};
            bins priv_viol = {8'h03};
        }
        cx_fault: cross cp_fault_active, cp_fault_code;
    endgroup

    covergroup cg_address_coverage;
        cp_addr_region: coverpoint item.address[31:28] {
            bins code_region   = {4'h0, 4'h1};
            bins sram_region   = {4'h2, 4'h3};
            bins periph_region = {4'h4, 4'h5};
            bins external_ram  = {4'h6, 4'h7};
            bins external_dev  = {4'h8, 4'h9, 4'hA, 4'hB};
            bins sys_region    = {4'hE};
        }
    endgroup

    function new(string name = "v8m_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_transaction_types = new();
        cg_pac_coverage      = new();
        cg_trustzone_coverage= new();
        cg_fault_coverage    = new();
        cg_address_coverage  = new();
    endfunction

    function void write(v8m_pacbti_item t);
        item = t;
        cg_transaction_types.sample();
        cg_pac_coverage.sample();
        cg_trustzone_coverage.sample();
        cg_fault_coverage.sample();
        cg_address_coverage.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf(
            "\n=== COVERAGE REPORT ===\n  Transaction Types : %0.1f%%\n  PAC Coverage      : %0.1f%%\n  TrustZone Coverage: %0.1f%%\n  Fault Coverage    : %0.1f%%\n  Address Coverage  : %0.1f%%\n=======================",
            cg_transaction_types.get_coverage(),
            cg_pac_coverage.get_coverage(),
            cg_trustzone_coverage.get_coverage(),
            cg_fault_coverage.get_coverage(),
            cg_address_coverage.get_coverage()), UVM_NONE)
    endfunction

endclass : v8m_coverage
