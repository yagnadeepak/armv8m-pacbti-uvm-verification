//=============================================================================
// File        : v8m_tests.sv
// Description : UVM 1.2 Tests — ARMv8-M PACBTI/TrustZone test library
//=============================================================================

//-----------------------------------------------------------------------------
// Base test
//-----------------------------------------------------------------------------
class v8m_base_test extends uvm_test;
    `uvm_component_utils(v8m_base_test)

    v8m_env env;

    function new(string name = "v8m_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = v8m_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_report_server svr;
        svr = uvm_report_server::get_server();
        phase.raise_objection(this);
        run_test_body(phase);
        phase.drop_objection(this);
        if (svr.get_severity_count(UVM_ERROR) == 0 &&
            svr.get_severity_count(UVM_FATAL) == 0)
            `uvm_info("TEST", "\n\n*** TEST PASSED ***\n", UVM_NONE)
        else
            `uvm_error("TEST", "\n\n*** TEST FAILED ***\n")
    endtask

    virtual task run_test_body(uvm_phase phase);
        // Override in derived tests
    endtask
endclass

//-----------------------------------------------------------------------------
// v8m_test — smoke test running all sequence types
//-----------------------------------------------------------------------------
class v8m_test extends v8m_base_test;
    `uvm_component_utils(v8m_test)

    function new(string name = "v8m_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_test_body(uvm_phase phase);
        v8m_pac_sign_auth_seq pac_seq;
        v8m_bti_seq           bti_seq;
        v8m_tz_boundary_seq   tz_seq;
        pac_seq = v8m_pac_sign_auth_seq::type_id::create("pac_seq");
        bti_seq = v8m_bti_seq::type_id::create("bti_seq");
        tz_seq  = v8m_tz_boundary_seq::type_id::create("tz_seq");
        `uvm_info("TEST", "=== v8m_test: Smoke Test Starting ===", UVM_MEDIUM)
        pac_seq.num_transactions = 5;
        bti_seq.num_transactions = 4;
        tz_seq.num_transactions  = 6;
        pac_seq.start(env.agent.seqr);
        bti_seq.start(env.agent.seqr);
        tz_seq.start(env.agent.seqr);
        `uvm_info("TEST", "=== v8m_test: Smoke Test Complete ===", UVM_MEDIUM)
    endtask
endclass

//-----------------------------------------------------------------------------
// v8m_pac_test — focused PAC verification
//-----------------------------------------------------------------------------
class v8m_pac_test extends v8m_base_test;
    `uvm_component_utils(v8m_pac_test)

    function new(string name = "v8m_pac_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_test_body(uvm_phase phase);
        v8m_pac_sign_auth_seq seq;
        seq = v8m_pac_sign_auth_seq::type_id::create("seq");
        seq.num_transactions = 30;
        `uvm_info("TEST", "=== v8m_pac_test: PAC Focused Test ===", UVM_MEDIUM)
        seq.start(env.agent.seqr);
        `uvm_info("TEST", "=== v8m_pac_test: Complete ===", UVM_MEDIUM)
    endtask
endclass

//-----------------------------------------------------------------------------
// v8m_tz_test — focused TrustZone verification
//-----------------------------------------------------------------------------
class v8m_tz_test extends v8m_base_test;
    `uvm_component_utils(v8m_tz_test)

    function new(string name = "v8m_tz_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_test_body(uvm_phase phase);
        v8m_tz_boundary_seq seq;
        seq = v8m_tz_boundary_seq::type_id::create("seq");
        seq.num_transactions = 30;
        `uvm_info("TEST", "=== v8m_tz_test: TrustZone Focused Test ===", UVM_MEDIUM)
        seq.start(env.agent.seqr);
        `uvm_info("TEST", "=== v8m_tz_test: Complete ===", UVM_MEDIUM)
    endtask
endclass

//-----------------------------------------------------------------------------
// v8m_privilege_test — privilege escalation verification
//-----------------------------------------------------------------------------
class v8m_privilege_test extends v8m_base_test;
    `uvm_component_utils(v8m_privilege_test)

    function new(string name = "v8m_privilege_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_test_body(uvm_phase phase);
        v8m_privilege_seq seq;
        seq = v8m_privilege_seq::type_id::create("seq");
        seq.num_transactions = 20;
        `uvm_info("TEST", "=== v8m_privilege_test: Privilege Test ===", UVM_MEDIUM)
        seq.start(env.agent.seqr);
        `uvm_info("TEST", "=== v8m_privilege_test: Complete ===", UVM_MEDIUM)
    endtask
endclass

//-----------------------------------------------------------------------------
// v8m_full_regression_test — runs everything
//-----------------------------------------------------------------------------
class v8m_full_regression_test extends v8m_base_test;
    `uvm_component_utils(v8m_full_regression_test)

    function new(string name = "v8m_full_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_test_body(uvm_phase phase);
        v8m_full_regression_seq seq;
        seq = v8m_full_regression_seq::type_id::create("seq");
        `uvm_info("TEST", "=== v8m_full_regression_test: Full Regression ===", UVM_MEDIUM)
        seq.start(env.agent.seqr);
        `uvm_info("TEST", "=== v8m_full_regression_test: Complete ===", UVM_MEDIUM)
    endtask
endclass
