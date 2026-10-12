#
# Tomás Oliveira e Silva,  September 2026
#
# Arquiteturas de Alto Desempenho 2026/2027
#
# makefile for the practical class AAD_P05 (2026/2027)
#

clean:
	rm -f a.out hello one_to_one one_to_all

hello:		hello_world_mpi.c
	mpicc -Wall -O2 hello_world_mpi.c -o hello

.PHONY:		run_hello
run_hello:	hello
	mpirun -np 4 ./hello

one_to_one:	one_to_one_communication_mpi.c
	mpicc -Wall -O2 one_to_one_communication_mpi.c -o one_to_one

one_to_all:	one_to_all_communication_mpi.c
	mpicc -Wall -O2 one_to_all_communication_mpi.c -o one_to_all
