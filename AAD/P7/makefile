#
# Tomás Oliveira e Silva,  September 2026
#
# Arquiteturas de Alto Desempenho 2026/2027
#
# makefile for the practical class AAD_P10 (2026/2027)
#

clean:
	rm -f work-*.cf ex1.vcd ex2.vcd

.PHONY:	ex1.vcd
ex1.vcd:
	rm -f work-*.cf
	ghdl -i --std=08 not_gate_1.vhd and_gate_2.vhd ex1.vhd ex1_tb.vhd
	ghdl -m --std=08 ex1_tb
	ghdl -r --std=08 ex1_tb --stop-time=10000ps --vcd=ex1.vcd

.PHONY:	ex2.vcd
ex2.vcd:
	rm -f work-*.cf
	ghdl -i --std=08 and_gate_2.vhd or_gate_3.vhd xor_gate_3.vhd full_adder.vhd adder_n.vhd ex2_tb.vhd
	ghdl -m --std=08 ex2_tb
	ghdl -r --std=08 ex2_tb --stop-time=10000ps --vcd=ex2.vcd
