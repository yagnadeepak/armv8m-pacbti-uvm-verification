//=============================================================================
// File        : v8m_agent.sv
// Description : UVM 1.2 Agent — ARMv8-M PACBTI/TrustZone
//=============================================================================
class v8m_agent extends uvm_agent;
    `uvm_component_utils(v8m_agent)

    v8m_driver                    drv;
    v8m_monitor                   mon;
    uvm_sequencer #(v8m_pacbti_item) seqr;
    uvm_analysis_port #(v8m_pacbti_item) ap;

    function new(string name = "v8m_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap   = new("ap", this);
        mon  = v8m_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = v8m_driver::type_id::create("drv", this);
            seqr = uvm_sequencer #(v8m_pacbti_item)::type_id::create("seqr", this);
        end
        `uvm_info("AGENT", $sformatf("Built agent, active=%0d", get_is_active()), UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(ap);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(seqr.seq_item_export);
        `uvm_info("AGENT", "Connected agent sub-components", UVM_MEDIUM)
    endfunction

endclass : v8m_agent
