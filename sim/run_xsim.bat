@echo off
REM =============================================================================
REM  run_xsim.bat - ARMv8-M PACBTI/TrustZone UVM Simulation
REM  Requires: AMD Vivado ML Standard (free) - https://xilinx.com/vivado
REM  Place this file in: armv8m_vivado\sim\
REM  Run from cmd.exe inside that folder.
REM =============================================================================

REM ---- USER SETTINGS: edit VIVADO_PATH to match your install ----------------
set VIVADO_PATH=C:\Xilinx\Vivado\2024.2
REM If you installed to a different drive or version, update the line above.
REM Example: set VIVADO_PATH=C:\Xilinx\Vivado\2024.1
REM ---------------------------------------------------------------------------

where xvlog >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Sourcing Vivado environment from %VIVADO_PATH%...
    call "%VIVADO_PATH%\settings64.bat"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Could not source Vivado settings.
        echo        Check VIVADO_PATH in this script.
        pause
        exit /b 1
    )
)

set TEST_NAME=v8m_test
set VERBOSITY=UVM_MEDIUM
if not "%~1"=="" set TEST_NAME=%~1
if not "%~2"=="" set VERBOSITY=%~2

echo.
echo =============================================================================
echo   ARMv8-M PACBTI/TrustZone UVM Simulation
echo   Test      : %TEST_NAME%
echo   Verbosity : %VERBOSITY%
echo =============================================================================
echo.

if not exist xsim.dir mkdir xsim.dir

set UVM_INC=%VIVADO_PATH%\data\system_verilog\uvm_1_2\src

echo [1/3] Compiling RTL...
xvlog --sv --relax ^
      --include "%UVM_INC%" ^
      -L uvm ^
      ..\rtl\v8m_if.sv ^
      ..\rtl\v8m_pacbti_mock.sv

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo COMPILE ERROR in RTL files. Check errors above.
    pause
    exit /b 1
)
echo RTL compile OK.

echo.
echo [2/3] Compiling Testbench + UVM environment...
xvlog --sv --relax ^
      --include "%UVM_INC%" ^
      -L uvm ^
      ..\tb\tb_top.sv

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo COMPILE ERROR in testbench. Check errors above.
    pause
    exit /b 1
)
echo Testbench compile OK.

echo.
echo [3/3] Elaborating...
xelab ^
      -debug all ^
      --relax ^
      -L uvm ^
      -L unisims_ver ^
      -L secureip ^
      -timescale 1ns/1ps ^
      tb_top ^
      -s v8m_sim_%TEST_NAME%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ELABORATION ERROR. Check errors above.
    pause
    exit /b 1
)
echo Elaboration OK.

echo.
echo Running simulation: %TEST_NAME%
echo -----------------------------------------------
xsim v8m_sim_%TEST_NAME% ^
     --runall ^
     --testplusarg "UVM_TESTNAME=%TEST_NAME%" ^
     --testplusarg "UVM_VERBOSITY=%VERBOSITY%" ^
     --log ..\sim\sim_%TEST_NAME%.log

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo SIMULATION FAILED or ended with errors.
    echo Check: sim\sim_%TEST_NAME%.log
    pause
    exit /b 1
)

echo.
echo =============================================================================
echo  Simulation complete. Log saved to: sim\sim_%TEST_NAME%.log
echo =============================================================================
echo.

findstr /C:"TEST PASSED" ..\sim\sim_%TEST_NAME%.log >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  RESULT: *** TEST PASSED ***
) else (
    echo  RESULT: *** CHECK LOG - no PASS string found ***
)
findstr /C:"UVM_ERROR" ..\sim\sim_%TEST_NAME%.log 2>nul | findstr /V "count" | findstr /V " 0"
echo.
pause
