--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- behavioral implementation of a two-port and gate
--

library IEEE;
use IEEE.std_logic_1164.all;

entity and_gate_2 is
  port(input0  : in  std_logic;
       input1  : in  std_logic;
       output0 : out std_logic);
end and_gate_2;

architecture behavioral of and_gate_2 is
begin
  output0 <= transport input0 and input1 after 10 ps;
end behavioral;
