@echo off
call "D:\bin\Cython-0.22\bin\cython" "%1.pyx" -2
call gcc -c "%1.c" -I"C:\Program Files (x86)\Python27\include"
call gcc -shared "%1.c" -I"C:\Program Files (x86)\Python27\include" -L"C:\Program Files (x86)\Python27\libs" -lpython27 -o "%1.pyd"
