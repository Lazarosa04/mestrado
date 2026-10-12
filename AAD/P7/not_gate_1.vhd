--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- behavioral implementation of a not gate
--

library IEEE;
use IEEE.std_logic_1164.all;

entity not_gate_1 is
  port(input0  : in  std_logic;
       output0 : out std_logic);
end not_gate_1;

architecture behavioral of not_gate_1 is
begin
  output0 <= transport not input0 after 10 ps;
end behavioral;
