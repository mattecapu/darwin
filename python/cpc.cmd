@echo off
SETLOCAL ENABLEEXTENSIONS
IF "%1" == "g" (SET c_comp="cy_gcc")
IF "%1" == "gopt" (SET c_comp="cy_gcc_opt")
IF "%1" == "iopt" (SET c_comp="cy_icc_opt")
IF "%2" == "all" (
	call "%c_comp%" rnn
	call "%c_comp%" individual
	call "%c_comp%" simulation
) ELSE (
	call "%c_comp%" "%2"
)

ENDLOCAL
