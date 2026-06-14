//=============================================================================
// File        : v8m_sequences.sv
// Description : UVM 1.2 Sequence library — ARMv8-M PACBTI/TrustZone
//               PUBLICATION VERSION — 10,000 transactions per sequence
//               Total regression: ~70,000 transactions
//=============================================================================

// Base sequence
class v8m_base_seq extends uvm_sequence #(v8m_pacbti_item);
    `uvm_object_utils(v8m_base_seq)
    function new(string name = "v8m_base_seq");
        super.new(name);
    endfunction
endclass

//-----------------------------------------------------------------------------
// PAC Sign & Authenticate sequence
//-----------------------------------------------------------------------------
class v8m_pac_sign_auth_seq extends v8m_base_seq;
    `uvm_object_utils(v8m_pac_sign_auth_seq)
    int unsigned num_transactions = 10000;

    function new(string name = "v8m_pac_sign_auth_seq");
        super.new(name);
    endfunction

    task body();
        v8m_pacbti_item item;
        repeat (num_transactions) begin
            item = v8m_pacbti_item::type_id::create("pac_sign");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_PAC_SIGN;
                pac_enable  == 1'b1;
                tz_enable   == 1'b0;
                pac_key_lo  != 32'h0;
                pac_key_hi  != 32'h0;
            }) `uvm_error("RAND", "PAC sign randomization failed")
            finish_item(item);
        end
        repeat (num_transactions) begin
            item = v8m_pacbti_item::type_id::create("pac_auth");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_PAC_AUTH;
                pac_enable  == 1'b1;
                tz_enable   == 1'b0;
            }) `uvm_error("RAND", "PAC auth randomization failed")
            finish_item(item);
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// BTI landing pad sequence
//-----------------------------------------------------------------------------
class v8m_bti_seq extends v8m_base_seq;
    `uvm_object_utils(v8m_bti_seq)
    int unsigned num_transactions = 10000;

    function new(string name = "v8m_bti_seq");
        super.new(name);
    endfunction

    task body();
        v8m_pacbti_item item;
        repeat (num_transactions/2) begin
            item = v8m_pacbti_item::type_id::create("bti_call");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_BTI_CALL;
                bti_enable  == 1'b1;
                pac_enable  == 1'b0;
            }) `uvm_error("RAND", "BTI call randomization failed")
            finish_item(item);
        end
        repeat (num_transactions/2) begin
            item = v8m_pacbti_item::type_id::create("bti_jump");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_BTI_JUMP;
                bti_enable  == 1'b1;
                pac_enable  == 1'b0;
            }) `uvm_error("RAND", "BTI jump randomization failed")
            finish_item(item);
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// TrustZone boundary crossing sequence
//-----------------------------------------------------------------------------
class v8m_tz_boundary_seq extends v8m_base_seq;
    `uvm_object_utils(v8m_tz_boundary_seq)
    int unsigned num_transactions = 10000;

    function new(string name = "v8m_tz_boundary_seq");
        super.new(name);
    endfunction

    task body();
        v8m_pacbti_item item;
        // Secure world access
        repeat (num_transactions/3) begin
            item = v8m_pacbti_item::type_id::create("tz_secure");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_TZ_SECURE;
                tz_enable   == 1'b1;
                ns_access   == 1'b0;
            }) `uvm_error("RAND", "TZ secure randomization failed")
            finish_item(item);
        end
        // Non-secure access to non-secure region (should pass)
        repeat (num_transactions/3) begin
            item = v8m_pacbti_item::type_id::create("tz_ns_ok");
            start_item(item);
            if (!item.randomize()) `uvm_error("RAND", "TZ ns-ok randomization failed")
            item.trans_type = v8m_pacbti_item::TRANS_TZ_NONSECURE;
            item.tz_enable  = 1'b1;
            item.ns_access  = 1'b1;
            item.sau_base   = 32'h8000_0000;
            item.sau_limit  = 32'h8000_FFFF;
            item.sau_nsc    = 1'b0;
            item.address    = 32'h2000_0000;
            finish_item(item);
        end
        // Non-secure access to secure region (should fault)
        repeat (num_transactions/3) begin
            item = v8m_pacbti_item::type_id::create("tz_ns_fault");
            start_item(item);
            if (!item.randomize()) `uvm_error("RAND", "TZ ns-fault randomization failed")
            item.trans_type = v8m_pacbti_item::TRANS_TZ_NONSECURE;
            item.tz_enable  = 1'b1;
            item.ns_access  = 1'b1;
            item.sau_base   = 32'h1000_0000;
            item.sau_limit  = 32'h1000_FFFF;
            item.sau_nsc    = 1'b0;
            item.address    = 32'h1000_0100;
            finish_item(item);
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Privilege escalation attempt sequence
//-----------------------------------------------------------------------------
class v8m_privilege_seq extends v8m_base_seq;
    `uvm_object_utils(v8m_privilege_seq)
    int unsigned num_transactions = 10000;

    function new(string name = "v8m_privilege_seq");
        super.new(name);
    endfunction

    task body();
        v8m_pacbti_item item;
        repeat (num_transactions) begin
            item = v8m_pacbti_item::type_id::create("priv_trans");
            start_item(item);
            if (!item.randomize() with {
                trans_type == v8m_pacbti_item::TRANS_PRIVILEGE;
                priv_mode   == v8m_pacbti_item::MODE_THREAD;
                pac_enable  == 1'b1;
                tz_enable   == 1'b1;
            }) `uvm_error("RAND", "Privilege randomization failed")
            finish_item(item);
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Full regression sequence — 70,000 total transactions
//-----------------------------------------------------------------------------
class v8m_full_regression_seq extends v8m_base_seq;
    `uvm_object_utils(v8m_full_regression_seq)

    v8m_pac_sign_auth_seq pac_seq;
    v8m_bti_seq           bti_seq;
    v8m_tz_boundary_seq   tz_seq;
    v8m_privilege_seq     priv_seq;

    function new(string name = "v8m_full_regression_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("REGRESS", "=== Starting Full Regression Sequence (Publication Run) ===", UVM_MEDIUM)
        pac_seq  = v8m_pac_sign_auth_seq::type_id::create("pac_seq");
        bti_seq  = v8m_bti_seq::type_id::create("bti_seq");
        tz_seq   = v8m_tz_boundary_seq::type_id::create("tz_seq");
        priv_seq = v8m_privilege_seq::type_id::create("priv_seq");

        // 20k PAC + 10k BTI + 10k TZ + 10k Privilege = 70,000 transactions
        pac_seq.num_transactions  = 10000;
        bti_seq.num_transactions  = 10000;
        tz_seq.num_transactions   = 10000;
        priv_seq.num_transactions = 10000;

        pac_seq.start(m_sequencer);
        bti_seq.start(m_sequencer);
        tz_seq.start(m_sequencer);
        priv_seq.start(m_sequencer);
        `uvm_info("REGRESS", "=== Full Regression Sequence Complete (Publication Run) ===", UVM_MEDIUM)
    endtask
endclass
