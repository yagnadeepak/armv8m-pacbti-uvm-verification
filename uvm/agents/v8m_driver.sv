//=============================================================================
// File        : v8m_driver.sv
// Description : UVM 1.2 Driver — drives v8m_pacbti_item onto v8m_if
//=============================================================================
class v8m_driver extends uvm_driver #(v8m_pacbti_item);
    `uvm_component_utils(v8m_driver)

    virtual v8m_if vif;

    function new(string name = "v8m_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual v8m_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "v8m_driver: virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        v8m_pacbti_item req;
        init_signals();
        @(posedge vif.clk);
        wait(vif.rst_n === 1'b1);
        @(posedge vif.clk);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task init_signals();
        vif.cb.HADDR        <= 32'h0;
        vif.cb.HBURST       <= 3'h0;
        vif.cb.HMASTLOCK    <= 1'b0;
        vif.cb.HPROT        <= 4'h0;
        vif.cb.HSIZE        <= 3'h2;
        vif.cb.HTRANS       <= 2'b00;
        vif.cb.HWDATA       <= 32'h0;
        vif.cb.HWRITE       <= 1'b0;
        vif.cb.pac_enable   <= 1'b0;
        vif.cb.bti_enable   <= 1'b0;
        vif.cb.pac_key_lo   <= 32'h0;
        vif.cb.pac_key_hi   <= 32'h0;
        vif.cb.tz_enable    <= 1'b0;
        vif.cb.ns_access    <= 1'b0;
        vif.cb.sau_base     <= 32'h0;
        vif.cb.sau_limit    <= 32'h0;
        vif.cb.sau_nsc      <= 1'b0;
        vif.cb.privilege_mode <= 4'h0;
        vif.cb.current_pc   <= 32'h0;
        vif.cb.lr_value     <= 32'h0;
    endtask

    task drive_item(v8m_pacbti_item item);
        `uvm_info("DRV", $sformatf("Driving: %s", item.convert2string()), UVM_HIGH)

        @(vif.cb);
        // Drive AHB signals
        vif.cb.HADDR      <= item.address;
        vif.cb.HSIZE      <= item.hsize;
        vif.cb.HTRANS     <= item.htrans;
        vif.cb.HWRITE     <= (item.trans_type == v8m_pacbti_item::TRANS_WRITE);
        vif.cb.HPROT      <= {1'b0, 1'b0, 1'b0, (item.priv_mode != v8m_pacbti_item::MODE_THREAD)};
        vif.cb.HWDATA     <= item.data;

        // Drive PAC/BTI signals
        vif.cb.pac_enable <= item.pac_enable;
        vif.cb.bti_enable <= item.bti_enable;
        vif.cb.pac_key_lo <= item.pac_key_lo;
        vif.cb.pac_key_hi <= item.pac_key_hi;

        // Drive TrustZone signals
        vif.cb.tz_enable    <= item.tz_enable;
        vif.cb.ns_access    <= item.ns_access;
        vif.cb.sau_base     <= item.sau_base;
        vif.cb.sau_limit    <= item.sau_limit;
        vif.cb.sau_nsc      <= item.sau_nsc;

        // Drive CPU state
        vif.cb.privilege_mode <= {2'b0, item.priv_mode};
        vif.cb.current_pc     <= item.current_pc;
        vif.cb.lr_value       <= item.lr_value;

        @(vif.cb);
        // Wait for ready
        while (!vif.cb.HREADYOUT) @(vif.cb);

        // Return to idle
        vif.cb.HTRANS <= 2'b00;
        @(vif.cb);
    endtask

endclass : v8m_driver
