@echo off
call "D:\bin\Cython-0.22\bin\cython" "%1.pyx" -a -X nonecheck=False,boundscheck=False,wraparound=False,cdivision=True
