--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- structural implementation of the first exercise
--

library IEEE;
use IEEE.std_logic_1164.all;

entity ex1 is
  port(a : in  std_logic;
       b : out std_logic);
end ex1;

architecture structural of ex1 is
  signal s_not_a : std_logic;
begin
  my_not : entity work.not_gate_1(behavioral)
           port map(input0  => a,
                    output0 => s_not_a);
  my_and : entity work.and_gate_2(behavioral)
           port map(input0  => a,
                    input1  => s_not_a,
                    output0 => b);
end structural;
