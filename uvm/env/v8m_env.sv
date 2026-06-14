//=============================================================================
// File        : v8m_env.sv
// Description : UVM 1.2 Environment — ARMv8-M PACBTI/TrustZone
//=============================================================================
class v8m_env extends uvm_env;
    `uvm_component_utils(v8m_env)

    v8m_agent       agent;
    v8m_scoreboard  scoreboard;
    v8m_coverage    coverage;

    function new(string name = "v8m_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = v8m_agent::type_id::create("agent", this);
        scoreboard = v8m_scoreboard::type_id::create("scoreboard", this);
        coverage   = v8m_coverage::type_id::create("coverage", this);
        `uvm_info("ENV", "Environment built", UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(scoreboard.analysis_export);
        agent.ap.connect(coverage.analysis_export);
        `uvm_info("ENV", "Environment connected", UVM_MEDIUM)
    endfunction

endclass : v8m_env
