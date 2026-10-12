#
# Tomás Oliveira e Silva,  September 2026
#
# Arquiteturas de Alto Desempenho 2026/2027
#
# makefile for the practical class AAD_P06 (2026/2027)
#

#
# CUDA installation directory
#
CUDA_DIR = /usr/local/cuda

#
# OpenCL installation directory (for a NVidia graphics card, sama as CUDA)
#
OPENCL_DIR = $(CUDA_DIR)

#
# CUDA device architecture (sm_75 for a GeForce GTX 1660 Ti)
#
CUDA_ARCH = sm_75


#
# clean up
#
clean:
	rm -f a.out hello
	rm -f hello_cuda_driver_api hello_cuda_driver_api.cubin
	rm -f hello_open_cl
	rm -f median_filter_cuda MandelbrotSetMedian.pgm


#
# compilation of the hello.cu program using the nvcc "high-level" compiler
#
hello:				hello.cu
	nvcc -O2 hello.cu -o hello


#
# compilation of the hello_cuda_driver_api program
#
hello_cuda_driver_api:		hello_cuda_driver_api.c hello_cuda_driver_api.cubin
	cc -Wall -O2 -std=c99 -I$(CUDA_DIR)/include hello_cuda_driver_api.c -o hello_cuda_driver_api -L$(CUDA_DIR)/lib64 -lcuda

hello_cuda_driver_api.cubin:	hello_cuda_driver_api.cu
	nvcc -arch=$(CUDA_ARCH) --compiler-options -O2,-Wall -I$(CUDA_DIR)/include --cubin hello_cuda_driver_api.cu -o hello_cuda_driver_api.cubin


#
# compilation of the hello_open_cl program
# note: the hello_open_cl.cl is loaded at run time and compiled on the fly
#
hello_open_cl:			hello_open_cl.c
	cc -Wall -O2 -std=c99 hello_open_cl.c -o hello_open_cl -L$(OPENCL_DIR)/lib64 -lOpenCL


#
# compilation of the median_filter_cuda program
#
median_filter_cuda:		median_filter_cuda.cu
	nvcc -O2 median_filter_cuda.cu -o median_filter_cuda
