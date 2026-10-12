--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- behavioral implementation of a three-port exclusive or (xor) gate
--

library IEEE;
use IEEE.std_logic_1164.all;

entity xor_gate_3 is
  port(input0  : in  std_logic;
       input1  : in  std_logic;
       input2  : in  std_logic;
       output0 : out std_logic);
end xor_gate_3;

architecture behavioral of xor_gate_3 is
begin
  output0 <= transport input0 xor input1 xor input2 after 20 ps;
end behavioral;
