# =============================================================================
#  regress.tcl - Run full regression via Tcl
#  Usage from sim/: vivado -mode batch -source regress.tcl
# =============================================================================

set rtl_files {
    ../rtl/v8m_if.sv
    ../rtl/v8m_pacbti_mock.sv
}

set tb_files {
    ../tb/tb_top.sv
}

set tests {
    v8m_test
    v8m_pac_test
    v8m_tz_test
    v8m_privilege_test
    v8m_full_regression_test
}

set pass_list {}
set fail_list {}

proc compile_design {} {
    global rtl_files tb_files

    puts "\n[string repeat = 70]"
    puts "  Compiling RTL"
    puts "[string repeat = 70]"
    foreach f $rtl_files {
        if {![file exists $f]} {
            error "Missing RTL file: $f"
        }
    }
    set rtl_rc [catch {
        exec xvlog --sv --relax -L uvm {*}$rtl_files 2>@stdout
    } rtl_out]
    puts $rtl_out
    if {$rtl_rc != 0} {
        error "RTL compilation failed"
    }

    puts "\n[string repeat = 70]"
    puts "  Compiling Testbench and UVM Environment"
    puts "[string repeat = 70]"
    foreach f $tb_files {
        if {![file exists $f]} {
            error "Missing testbench file: $f"
        }
    }
    set tb_rc [catch {
        exec xvlog --sv --relax -L uvm {*}$tb_files 2>@stdout
    } tb_out]
    puts $tb_out
    if {$tb_rc != 0} {
        error "Testbench compilation failed"
    }
}

proc run_one_test {test_name} {
    global pass_list fail_list

    puts "\n[string repeat = 70]"
    puts "  Running: $test_name"
    puts "[string repeat = 70]"

    set elab_rc [catch {
        exec xelab -debug all --relax -L uvm -timescale 1ns/1ps \
                   tb_top -s v8m_sim_${test_name} \
                   2>@stdout
    } elab_out]
    puts $elab_out
    if {$elab_rc != 0} {
        puts "ELAB FAILED: $test_name"
        lappend fail_list $test_name
        return
    }

    set log_file "sim_${test_name}.log"
    set sim_rc [catch {
        exec xsim v8m_sim_${test_name} --runall \
                  --testplusarg "UVM_TESTNAME=${test_name}" \
                  --testplusarg "UVM_VERBOSITY=UVM_MEDIUM" \
                  --log $log_file \
                  2>@stdout
    } sim_out]
    puts $sim_out

    if {$sim_rc != 0} {
        puts "  RESULT: FAIL (xsim returned non-zero)"
        lappend fail_list $test_name
        return
    }

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

if {[catch {compile_design} compile_error]} {
    puts "\nCOMPILE FAILED: $compile_error"
    exit 1
}

foreach t $tests {
    run_one_test $t
}

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
    exit 1
}
puts "[string repeat = 70]\n"
