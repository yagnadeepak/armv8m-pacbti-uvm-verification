# =============================================================================
#  Makefile — ARMv8-M PACBTI/TrustZone UVM Simulation
#  For: AMD Vivado ML xsim  (Linux / WSL users)
#  Usage:
#    make               # compile + run default test (v8m_test)
#    make TEST=v8m_pac_test
#    make regression
#    make clean
# =============================================================================

VIVADO_PATH ?= /tools/Xilinx/Vivado/2024.2
XVLOG        = $(VIVADO_PATH)/bin/xvlog
XELAB        = $(VIVADO_PATH)/bin/xelab
XSIM         = $(VIVADO_PATH)/bin/xsim
UVM_INC      = $(VIVADO_PATH)/data/system_verilog/uvm_1_2/src

TEST        ?= v8m_test
VERBOSITY   ?= UVM_MEDIUM
SIM_SNAP     = v8m_sim_$(TEST)
LOG_FILE     = sim_$(TEST).log

# File lists
RTL_FILES = \
    ../rtl/v8m_if.sv \
    ../rtl/v8m_pacbti_mock.sv

TB_FILES = \
    ../tb/tb_top.sv

XVLOG_OPTS = --sv --relax --include $(UVM_INC) -L uvm
XELAB_OPTS = -debug all --relax -L uvm -timescale 1ns/1ps
XSIM_OPTS  = --runall \
             --testplusarg "UVM_TESTNAME=$(TEST)" \
             --testplusarg "UVM_VERBOSITY=$(VERBOSITY)" \
             --log $(LOG_FILE)

# Regression test list
TESTS = v8m_test v8m_pac_test v8m_tz_test v8m_privilege_test v8m_full_regression_test

.PHONY: all compile elaborate sim regression clean

all: compile elaborate sim

compile:
	@echo "=== [1/3] Compiling RTL ==="
	$(XVLOG) $(XVLOG_OPTS) $(RTL_FILES)
	@echo "=== [2/3] Compiling Testbench ==="
	$(XVLOG) $(XVLOG_OPTS) $(TB_FILES)

elaborate:
	@echo "=== [3/3] Elaborating ==="
	$(XELAB) $(XELAB_OPTS) tb_top -s $(SIM_SNAP)

sim:
	@echo "=== Running: $(TEST) ==="
	$(XSIM) $(SIM_SNAP) $(XSIM_OPTS)
	@echo ""
	@grep -E "TEST PASSED|TEST FAILED|UVM_ERROR|UVM_FATAL" $(LOG_FILE) || true

regression: compile
	@echo ""
	@echo "=== REGRESSION: running $(words $(TESTS)) tests ==="
	@PASS=0; FAIL=0; \
	for t in $(TESTS); do \
	    echo "\n--- $$t ---"; \
	    $(XELAB) $(XELAB_OPTS) tb_top -s v8m_sim_$$t 2>&1 | tail -3; \
	    $(XSIM) v8m_sim_$$t --runall \
	            --testplusarg "UVM_TESTNAME=$$t" \
	            --testplusarg "UVM_VERBOSITY=UVM_MEDIUM" \
	            --log sim_$$t.log 2>&1; \
	    if grep -q "TEST PASSED" sim_$$t.log 2>/dev/null; then \
	        echo "  PASS: $$t"; PASS=$$((PASS+1)); \
	    else \
	        echo "  FAIL: $$t"; FAIL=$$((FAIL+1)); \
	    fi; \
	done; \
	echo ""; \
	echo "=== RESULT: $$PASS passed, $$FAIL failed ==="

clean:
	@echo "Cleaning simulation artefacts..."
	rm -rf xsim.dir xvlog.pb xelab.pb xsim.jou *.log *.wdb webtalk*
	@echo "Done."
