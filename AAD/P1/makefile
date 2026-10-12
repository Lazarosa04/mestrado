#
# Tomás Oliveira e Silva,  September 2026
#
# Arquiteturas de Alto Desempenho 2026/2027
#
# makefile for the practical class AAD_P01 (2026/2027)
#
# if you don't have some compiler, say, gfortran, please adjust the make_all and run_all targets
#
# do
#   make run_all
# at least three times and record the best time of each program in the shared spreadsheet
#

SHELL=/bin/bash

clean:
	rm -f MandelbrotCountCgcc MandelbrotCountCOgcc
	rm -f MandelbrotCountCclang MandelbrotCountCOclang
	rm -f MandelbrotCount.class
	rm -f MandelbrotCount.pyc MandelbrotCountM.py MandelbrotCountM
	rm -f MandelbrotCountF MandelbrotCountFO
	rm -f MandelbrotCountR MandelbrotCountRO
	rm -f MandelbrotCountS MandelbrotCountSO
	rm -f MandelbrotCountZ MandelbrotCountZO
	rm -f MandelbrotCount.html MandelbrotCount.js MandelbrotCount.wasm
	rm -f MandelbrotSet.pgm MandelbrotSet.png
	rm -f a.out

#
# C
#
MandelbrotCountCgcc:	MandelbrotCount.c
	cc -Wall -Wextra -O0 MandelbrotCount.c -o MandelbrotCountCgcc

MandelbrotCountCOgcc:	MandelbrotCount.c
	cc -Wall -Wextra -O2 MandelbrotCount.c -o MandelbrotCountCOgcc

MandelbrotCountCclang:	MandelbrotCount.c
	clang -Wall -Wextra -O0 MandelbrotCount.c -o MandelbrotCountCclang

MandelbrotCountCOclang:	MandelbrotCount.c
	clang -Wall -Wextra -O2 MandelbrotCount.c -o MandelbrotCountCOclang

#
# Java
#
MandelbrotCount.class:	MandelbrotCount.java
	javac MandelbrotCount.java

#
# Python
#
# MandelbrotCountM requires a codon installation
#   in the teacher case, using a bash shell, do "export PATH=$PATH:/opt/codon/bin" before compiling
#
MandelbrotCount.pyc:	MandelbrotCount.py
	( echo 'import py_compile' ; echo 'py_compile.compile("MandelbrotCount.py","MandelbrotCount.pyc",None,False,2)' ) | python3

MandelbrotCountM.py:	MandelbrotCount.py
	rm -f MandelbrotCountM.py
	sed -e 's/time.process_time()/0/' -e 's/print.*/print(count,"--  ")/' MandelbrotCount.py >MandelbrotCountM.py

MandelbrotCountM:	MandelbrotCountM.py
	codon build -release MandelbrotCountM.py

run_codon:		MandelbrotCountM
	@TIMEFORMAT=%3R ; time ./MandelbrotCountM

#
# Fortran
#
MandelbrotCountF:	MandelbrotCount.f90
	gfortran -Wall -O0 MandelbrotCount.f90 -o MandelbrotCountF

MandelbrotCountFO:	MandelbrotCount.f90
	gfortran -Wall -O2 MandelbrotCount.f90 -o MandelbrotCountFO

#
# Rust
#
MandelbrotCountR:	MandelbrotCount.rs
	rustc    MandelbrotCount.rs -o MandelbrotCountR

MandelbrotCountRO:	MandelbrotCount.rs
	rustc -O MandelbrotCount.rs -o MandelbrotCountRO

#
# Swift
#
MandelbrotCountS:	MandelbrotCount.swift
	swiftc    MandelbrotCount.swift -o MandelbrotCountS

MandelbrotCountSO:	MandelbrotCount.swift
	swiftc -O MandelbrotCount.swift -o MandelbrotCountSO

#
# Zig
#
MandelbrotCountZ:	MandelbrotCount.zig
	zig build-exe                MandelbrotCount.zig -femit-bin=MandelbrotCountZ
	rm -f MandelbrotCountZ.o

MandelbrotCountZO:	MandelbrotCount.zig
	zig build-exe -O ReleaseFast MandelbrotCount.zig -femit-bin=MandelbrotCountZO
	rm -f MandelbrotCountZO.o

#
# tests
#
compile_all:		MandelbrotCountCgcc MandelbrotCountCOgcc \
			MandelbrotCount.py MandelbrotCount.pyc

ifneq ($(shell command -v clang 2>/dev/null),)
compile_all: MandelbrotCountCclang MandelbrotCountCOclang
endif

ifneq ($(shell command -v javac 2>/dev/null),)
compile_all: MandelbrotCount.class
endif

ifneq ($(shell command -v gfortran 2>/dev/null),)
compile_all: MandelbrotCountF MandelbrotCountFO
endif

ifneq ($(shell command -v codon 2>/dev/null),)
compile_all: MandelbrotCountM
endif

ifneq ($(shell command -v rustc 2>/dev/null),)
compile_all: MandelbrotCountR MandelbrotCountRO
endif

ifneq ($(shell command -v swiftc 2>/dev/null),)
compile_all: MandelbrotCountS MandelbrotCountSO
endif

ifneq ($(shell command -v zig 2>/dev/null),)
compile_all: MandelbrotCountZ MandelbrotCountZO
endif

run_all:		compile_all
	@set -e ; \
	if [ -x ./MandelbrotCountCgcc    ]; then echo -n "C (gcc)             " ; ./MandelbrotCountCgcc ;                       fi ; \
	if [ -x ./MandelbrotCountCOgcc   ]; then echo -n "C -O2 (gcc)         " ; ./MandelbrotCountCOgcc ;                      fi ; \
	if [ -x ./MandelbrotCountCclang  ]; then echo -n "C (clang)           " ; ./MandelbrotCountCclang ;                     fi ; \
	if [ -x ./MandelbrotCountCOclang ]; then echo -n "C -O2 (clang)       " ; ./MandelbrotCountCOclang ;                    fi ; \
	if [ -e ./MandelbrotCount.class  ]; then echo -n "java                " ; java MandelbrotCount ;                        fi ; \
	if [ -e ./MandelbrotCount.py     ]; then echo -n "python              " ; python3 MandelbrotCount.py ;                  fi ; \
	if [ -e ./MandelbrotCount.pyc    ]; then echo -n "python (byte code)  " ; python3 MandelbrotCount.pyc ;                 fi ; \
	if command -v codon >/dev/null 2>&1; then \
		if [ -x ./MandelbrotCountM ]; then echo -n "python (codon)      " ; make -s run_codon 2>&1 | tr '\n' ' ' ; echo ; fi ; \
	else echo "python (codon)      skipped (codon not installed)" ; fi ; \
	if [ -x ./MandelbrotCountF       ]; then echo -n "fortran             " ; ./MandelbrotCountF ;                          fi ; \
	if [ -x ./MandelbrotCountFO      ]; then echo -n "fortran -O2         " ; ./MandelbrotCountFO ;                         fi ; \
	if [ -x ./MandelbrotCountR       ]; then echo -n "rust                " ; ./MandelbrotCountR ;                          fi ; \
	if [ -x ./MandelbrotCountRO      ]; then echo -n "rust -O             " ; ./MandelbrotCountRO ;                         fi ; \
	if [ -x ./MandelbrotCountS       ]; then echo -n "swift               " ; ./MandelbrotCountS ;                          fi ; \
	if [ -x ./MandelbrotCountSO      ]; then echo -n "swift -O            " ; ./MandelbrotCountSO ;                         fi ; \
	if [ -x ./MandelbrotCountZ       ]; then echo -n "zig                 " ; ./MandelbrotCountZ ;                          fi ; \
	if [ -x ./MandelbrotCountZO      ]; then echo -n "zig -O              " ; ./MandelbrotCountZO ;                         fi ; \
	echo "All done!"


#
# web assembly
#
# this requires an emscripten installation
#   in the teacher case, using a bash shell, do "source /opt/emscripten/emsdk/emsdk_env.sh" before compiling
#
WebAssembly:			MandelbrotCount.c
	emcc -Wall -O2 MandelbrotCount.c -o MandelbrotCount.html

#
# image
#
MandelbrotSet.png:		MandelbrotImage.c
	cc -Wall -O2 MandelbrotImage.c -o a.out
	./a.out
	convert MandelbrotSet.pgm MandelbrotSet.png
	rm -f a.out
