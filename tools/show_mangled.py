"""
show_mangled.py -- Show the assembler-mangled name for one or more Forth words.
Usage: python show_mangled.py <word> [<word> ...]
"""
import sys
from forthc.codegen import _mangle

for word in sys.argv[1:]:
    print(f'{word:20} -> {_mangle(word)}')
