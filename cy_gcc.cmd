@echo off
call cython_transpile %1
call gcc -shared "%1.c" -I"C:\Program Files (x86)\Python27\include" -I"C:\Program Files (x86)\Python27\Lib\site-packages\numpy\core\include" -L"C:\Program Files (x86)\Python27\libs" -lpython27 -openmp -o "%1.pyd"
