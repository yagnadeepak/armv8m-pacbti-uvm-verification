//=============================================================================
// File        : v8m_monitor.sv
// Description : UVM 1.2 Monitor — samples DUT responses from v8m_if
//=============================================================================
class v8m_monitor extends uvm_monitor;
    `uvm_component_utils(v8m_monitor)

    virtual v8m_if vif;
    uvm_analysis_port #(v8m_pacbti_item) ap;

    function new(string name = "v8m_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual v8m_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "v8m_monitor: virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        v8m_pacbti_item observed;
        wait(vif.rst_n === 1'b1);
        forever begin
            @(vif.cb);
            if (vif.HTRANS != 2'b00) begin
                observed = v8m_pacbti_item::type_id::create("observed");
                capture_transaction(observed);
                ap.write(observed);
            end
        end
    endtask

    task capture_transaction(v8m_pacbti_item item);
        // Capture driven values
        item.address     = vif.HADDR;
        item.data        = vif.HWDATA;
        item.pac_enable  = vif.pac_enable;
        item.bti_enable  = vif.bti_enable;
        item.pac_key_lo  = vif.pac_key_lo;
        item.pac_key_hi  = vif.pac_key_hi;
        item.tz_enable   = vif.tz_enable;
        item.ns_access   = vif.ns_access;
        item.sau_base    = vif.sau_base;
        item.sau_limit   = vif.sau_limit;
        item.sau_nsc     = vif.sau_nsc;
        item.current_pc  = vif.current_pc;
        item.lr_value    = vif.lr_value;

        // Capture DUT response (next cycle)
        @(vif.cb);
        item.exp_pac_pass     = vif.cb.pac_auth_pass;
        item.exp_tz_fault     = vif.cb.tz_fault;
        item.exp_fault_active = vif.cb.fault_active;
        item.exp_fault_code   = vif.cb.fault_code;

        // Decode observed transaction type
        if (item.pac_enable && item.tz_enable)
            item.trans_type = v8m_pacbti_item::TRANS_PAC_AUTH;
        else if (item.pac_enable)
            item.trans_type = v8m_pacbti_item::TRANS_PAC_SIGN;
        else if (item.bti_enable)
            item.trans_type = v8m_pacbti_item::TRANS_BTI_CALL;
        else if (item.tz_enable && item.ns_access)
            item.trans_type = v8m_pacbti_item::TRANS_TZ_NONSECURE;
        else if (item.tz_enable)
            item.trans_type = v8m_pacbti_item::TRANS_TZ_SECURE;
        else if (vif.HWRITE)
            item.trans_type = v8m_pacbti_item::TRANS_WRITE;
        else
            item.trans_type = v8m_pacbti_item::TRANS_READ;

        `uvm_info("MON", $sformatf("Observed: %s | pac_pass=%0b tz_fault=%0b fault=%0b[%02h]",
            item.convert2string(),
            item.exp_pac_pass, item.exp_tz_fault,
            item.exp_fault_active, item.exp_fault_code), UVM_HIGH)
    endtask

endclass : v8m_monitor
