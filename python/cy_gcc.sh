bash cython_transpile.sh ${1} 
gcc -shared "${1}.c" -I'/usr/lib/python2.7/dist-packages/numpy/core/include' -I'/usr/include/python2.7' -L'/usr/lib/python2.7' -fPIC -pthread  -o "${1}.so"
