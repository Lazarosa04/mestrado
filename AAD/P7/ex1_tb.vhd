--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- testbench for the first exercise
--

library IEEE;
use IEEE.std_logic_1164.all;

entity ex1_tb is
end ex1_tb;

architecture stimulus of ex1_tb is
  signal s_u,s_v : std_logic;
begin
  uut : entity work.ex1(structural)
               port map(a => s_u,
                        b => s_v);
  process
  begin
    for cycle in 0 to 4 loop
      s_u <= '0';
      wait for 50 ps;
      s_u <= '1';
      wait for 50 ps;
    end loop;
    wait;
  end process;
end stimulus;
