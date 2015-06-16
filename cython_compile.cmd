@echo off
call "D:\bin\Cython-0.22\bin\cython" "%1.pyx" -a
call gcc -shared "%1.c" -I"C:\Program Files (x86)\Python27\include" -I"C:\Program Files (x86)\Python27\Lib\site-packages\numpy\core\include" -L"C:\Program Files (x86)\Python27\libs" -lpython27 -O3 -ffast-math -fno-signed-zeros -fno-trapping-math -fassociative-math -fwhole-program -flto -march=native -o "%1.pyd"
