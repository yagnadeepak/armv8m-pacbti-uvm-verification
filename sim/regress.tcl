# =============================================================================
#  regress.tcl — Run full regression via Tcl (call from Vivado Tcl console
#                or batch: vivado -mode batch -source regress.tcl)
# =============================================================================

set tests {
    v8m_test
    v8m_pac_test
    v8m_tz_test
    v8m_privilege_test
    v8m_full_regression_test
}

set pass_list {}
set fail_list {}

proc run_one_test {test_name} {
    global pass_list fail_list

    puts "\n[string repeat = 70]"
    puts "  Running: $test_name"
    puts "[string repeat = 70]"

    # Elaborate per-test snapshot
    set elab_rc [catch {
        exec xelab -debug all --relax -L uvm -timescale 1ns/1ps \
                   tb_top -s v8m_sim_${test_name} \
                   2>@stdout
    } elab_out]
    if {$elab_rc != 0} {
        puts "ELAB FAILED: $test_name"
        lappend fail_list $test_name
        return
    }

    # Run simulation, capture log
    set log_file "sim_${test_name}.log"
    set sim_rc [catch {
        exec xsim v8m_sim_${test_name} --runall \
                  --testplusarg "UVM_TESTNAME=${test_name}" \
                  --testplusarg "UVM_VERBOSITY=UVM_MEDIUM" \
                  --log $log_file \
                  2>@stdout
    } sim_out]

    # Parse log for result
    if {[file exists $log_file]} {
        set fh [open $log_file r]
        set log_content [read $fh]
        close $fh
        if {[string match "*TEST PASSED*" $log_content]} {
            puts "  RESULT: PASS"
            lappend pass_list $test_name
        } else {
            puts "  RESULT: FAIL (see $log_file)"
            lappend fail_list $test_name
        }
    } else {
        puts "  RESULT: FAIL (no log produced)"
        lappend fail_list $test_name
    }
}

# --- Run all tests -----------------------------------------------------------
foreach t $tests {
    run_one_test $t
}

# --- Summary -----------------------------------------------------------------
puts "\n[string repeat = 70]"
puts "  REGRESSION SUMMARY"
puts "[string repeat = 70]"
puts "  PASSED ([llength $pass_list]): $pass_list"
puts "  FAILED ([llength $fail_list]): $fail_list"
set total [expr {[llength $pass_list] + [llength $fail_list]}]
puts "  TOTAL : $total tests"
if {[llength $fail_list] == 0} {
    puts "\n  *** ALL TESTS PASSED ***"
} else {
    puts "\n  *** [llength $fail_list] TEST(S) FAILED ***"
}
puts "[string repeat = 70]\n"
