@echo off
call cython_transpile %1
call icc -shared "%1.c" -I"C:\Program Files (x86)\Python27\include" -I"C:\Program Files (x86)\Python27\Lib\site-packages\numpy\core\include" -L"C:\Program Files (x86)\Python27\libs" -lpython27 -O3 -march=native -pc64 -fast-transcendentals -unroll-aggressive -parallel -fp-model fast -ftz -ipo -std=c99 -o "%1.pyd"
