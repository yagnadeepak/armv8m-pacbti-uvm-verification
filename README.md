# ARMv8-M PACBTI and TrustZone UVM Verification

A UVM 1.2 verification environment for a simplified ARMv8-M security mock
design. The project exercises Pointer Authentication Code (PAC), Branch Target
Identification (BTI), TrustZone boundary checks, privilege faults, and basic
AHB-Lite transfers using AMD Vivado XSim.

> This is an educational verification project, not a complete ARM processor or
> an architecturally compliant PAC implementation. The current mock DUT uses a
> lightweight XOR-based PAC model.

## Publication Status

This project is associated with the accepted conference paper:

```text
A UVM 1.2 Verification Environment for ARMv8-M PACBTI and TrustZone Security
Architecture: Implementation and Coverage Analysis
```

Paper ID `749` was accepted for presentation at the 2026 IEEE 6th International
Conference on VLSI Systems, Architecture, Technology and Applications
(VLSI SATA 2026), according to the conference acceptance notification.

The IEEE copyright and consent form for the paper was completed by Yagna Deepak
Dhulipala on `11-05-2026`. Copyright for the paper has therefore been
transferred to IEEE under the terms of the IEEE copyright form. This repository
contains the SystemVerilog/UVM project files only; it does not redistribute the
IEEE paper manuscript or copyright form.

## Project Structure

```text
armv8m_vivado/
|-- rtl/
|   |-- v8m_if.sv
|   `-- v8m_pacbti_mock.sv
|-- tb/
|   `-- tb_top.sv
|-- uvm/
|   |-- agents/
|   |-- coverage/
|   |-- env/
|   |-- scoreboard/
|   |-- sequences/
|   `-- tests/
|-- sim/
|   |-- Makefile
|   |-- regress.tcl
|   `-- run_xsim.bat
`-- README.md
```

## Verification Flow

```text
Test -> Sequence -> Sequencer -> Driver -> Interface -> DUT
                                                |
                                                v
                           Coverage <- Monitor -> Scoreboard
```

- `rtl/v8m_if.sv` defines the AHB-Lite, PACBTI, TrustZone, and CPU-state signals.
- `rtl/v8m_pacbti_mock.sv` is the behavioral mock DUT.
- `tb/tb_top.sv` creates clock/reset, connects the DUT, and starts UVM.
- `uvm/sequences/` defines transaction items and constrained-random stimulus.
- `uvm/agents/` contains the sequencer, driver, and monitor.
- `uvm/scoreboard/` checks observed DUT behavior.
- `uvm/coverage/` records functional coverage.
- `uvm/tests/` provides selectable UVM tests.

## Available Tests

| Test | Purpose |
|---|---|
| `v8m_test` | Small smoke test across PAC, BTI, and TrustZone |
| `v8m_pac_test` | PAC-focused transactions |
| `v8m_tz_test` | TrustZone boundary scenarios |
| `v8m_privilege_test` | Privilege-violation scenarios |
| `v8m_full_regression_test` | Combined large regression |

## Requirements

- AMD Vivado ML with Vivado Simulator/XSim
- UVM 1.2, supplied with Vivado
- Windows Command Prompt, or GNU Make on Linux/WSL

The Windows runner currently expects Vivado under:

```text
C:\Xilinx\Vivado\2024.2
```

Update `VIVADO_PATH` in `sim/run_xsim.bat` if your installation differs.

## Running A Test

From Windows Command Prompt:

```bat
cd sim
run_xsim.bat v8m_test
run_xsim.bat v8m_pac_test
run_xsim.bat v8m_tz_test
run_xsim.bat v8m_privilege_test
run_xsim.bat v8m_full_regression_test
```

Run the regression script with:

```bat
cd sim
vivado -mode batch -source regress.tcl
```

The regression script compiles the RTL/testbench first, then elaborates and runs
each test snapshot.

A successful test reports:

```text
*** TEST PASSED ***
UVM_ERROR : 0
UVM_FATAL : 0
```

## Current Model Limitations

- PAC generation uses XOR rather than QARMA5-64.
- PAC keys are modeled as 64 bits rather than the 128-bit Armv8.1-M key banks.
- BTI behavior and checking are intentionally minimal.
- The scoreboard does not yet use an independent PAC reference model.
- The DUT models selected security behavior, not a full ARMv8-M pipeline.

## Suggested Extensions

1. Add a QARMA5-64 PAC engine and 128-bit PAC keys.
2. Add an independent reference model to the scoreboard.
3. Strengthen BTI and privilege-fault checking.
4. Add known-answer tests and negative authentication scenarios.
5. Improve protocol assertions and coverage closure.

## License

This repository is source-available for academic viewing, personal educational
review, and reference only under the
[`Research Viewing and Reference License`](LICENSE).

You may view, clone, and run the code for personal educational review. You may
not redistribute, modify, extend, create derivative works, or use this repository
as the basis for another paper, thesis, report, publication, or research project
without prior written permission from the author.

This license applies to the repository source files only. It does not apply to
the associated IEEE paper manuscript, IEEE copyright form, or any IEEE-published
version of the paper.
