--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- behavioral implementation of a D flip-flop
--

library IEEE;
use IEEE.std_logic_1164.all;

entity d_flip_flop is
  port(
        clock : in  std_logic;
        d     : in  std_logic;
        q     : out std_logic;
        en    : in  std_logic
      );
end d_flip_flop;

architecture behavioral of d_flip_flop is
begin
  process(clock) is
  begin
    if rising_edge(clock) and en = '1' then
      q <= transport d after 10 ps;
    end if;
  end process;
end behavioral;
