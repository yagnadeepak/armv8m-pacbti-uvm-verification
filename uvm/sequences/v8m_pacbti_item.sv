//=============================================================================
// File        : v8m_pacbti_item.sv
// Description : UVM 1.2 Sequence Item — ARMv8-M PACBTI/TrustZone transactions
//=============================================================================
class v8m_pacbti_item extends uvm_sequence_item;
    `uvm_object_utils(v8m_pacbti_item)

    // Transaction type enum
    typedef enum logic [3:0] {
        TRANS_READ        = 4'h0,
        TRANS_WRITE       = 4'h1,
        TRANS_PAC_SIGN    = 4'h2,
        TRANS_PAC_AUTH    = 4'h3,
        TRANS_BTI_CALL    = 4'h4,
        TRANS_BTI_JUMP    = 4'h5,
        TRANS_TZ_SECURE   = 4'h6,
        TRANS_TZ_NONSECURE= 4'h7,
        TRANS_FAULT_INJECT= 4'h8,
        TRANS_PRIVILEGE   = 4'h9
    } trans_type_e;

    typedef enum logic [1:0] {
        MODE_THREAD   = 2'h0,
        MODE_HANDLER  = 2'h1,
        MODE_SUPER    = 2'h2
    } priv_mode_e;

    // Randomizable fields
    rand trans_type_e  trans_type;
    rand logic [31:0]  address;
    rand logic [31:0]  data;
    rand logic [31:0]  pac_key_lo;
    rand logic [31:0]  pac_key_hi;
    rand logic [31:0]  current_pc;
    rand logic [31:0]  lr_value;
    rand logic [31:0]  sau_base;
    rand logic [31:0]  sau_limit;
    rand priv_mode_e   priv_mode;
    rand logic         pac_enable;
    rand logic         bti_enable;
    rand logic         tz_enable;
    rand logic         ns_access;
    rand logic         sau_nsc;
    rand logic [2:0]   hsize;
    rand logic [1:0]   htrans;

    // Expected response (set by predictor)
    logic              exp_pac_pass;
    logic              exp_tz_fault;
    logic              exp_fault_active;
    logic [7:0]        exp_fault_code;

    // Constraints
    constraint c_address_aligned {
        (hsize == 3'h2) -> (address[1:0] == 2'b00);
        (hsize == 3'h1) -> (address[0]   == 1'b0);
    }

    constraint c_sau_region {
        sau_limit >= sau_base;
        sau_limit - sau_base <= 32'hFFFF;
        sau_base[1:0]  == 2'b00;
        sau_limit[1:0] == 2'b00;
    }

    constraint c_htrans_valid {
        htrans inside {2'b00, 2'b10};  // IDLE or NONSEQ
    }

    constraint c_pac_key_nonzero {
        pac_key_lo != 32'h0;
        pac_key_hi != 32'h0;
    }

    constraint c_pc_aligned {
        current_pc[0] == 1'b0;
        lr_value[0]   == 1'b0;
    }

    constraint c_trans_dist {
        trans_type dist {
            TRANS_READ         := 15,
            TRANS_WRITE        := 15,
            TRANS_PAC_SIGN     := 15,
            TRANS_PAC_AUTH     := 15,
            TRANS_BTI_CALL     := 10,
            TRANS_BTI_JUMP     := 5,
            TRANS_TZ_SECURE    := 10,
            TRANS_TZ_NONSECURE := 10,
            TRANS_FAULT_INJECT := 3,
            TRANS_PRIVILEGE    := 2
        };
    }

    function new(string name = "v8m_pacbti_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "type=%-16s addr=0x%08h data=0x%08h pc=0x%08h mode=%s pac=%0b tz=%0b ns=%0b",
            trans_type.name(), address, data, current_pc,
            priv_mode.name(), pac_enable, tz_enable, ns_access);
    endfunction

    function void do_copy(uvm_object rhs);
        v8m_pacbti_item rhs_;
        if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy cast failed")
        super.do_copy(rhs);
        trans_type  = rhs_.trans_type;
        address     = rhs_.address;
        data        = rhs_.data;
        pac_key_lo  = rhs_.pac_key_lo;
        pac_key_hi  = rhs_.pac_key_hi;
        current_pc  = rhs_.current_pc;
        lr_value    = rhs_.lr_value;
        sau_base    = rhs_.sau_base;
        sau_limit   = rhs_.sau_limit;
        priv_mode   = rhs_.priv_mode;
        pac_enable  = rhs_.pac_enable;
        bti_enable  = rhs_.bti_enable;
        tz_enable   = rhs_.tz_enable;
        ns_access   = rhs_.ns_access;
        sau_nsc     = rhs_.sau_nsc;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        v8m_pacbti_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                address    == rhs_.address &&
                trans_type == rhs_.trans_type);
    endfunction

endclass : v8m_pacbti_item
