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
  signal s_clock,s_d,s_q,s_en : std_logic;
begin
  uut : entity work.d_flip_flop(behavioral)
               port map(clock => s_clock,
                        d     => s_d,
                        q     => s_q,
                        en    => s_en);
  clock : process
  begin
    s_clock <= '0';
    wait for 50 ps;
    for cycle in 0 to 8 loop
      wait for 50 ps;
      s_clock <= '1';
      wait for 50 ps;
      s_clock <= '0';
    end loop;
    wait for 50 ps;
    wait;
  end process;
  enable : process
  begin
    s_en <= '0';
    wait for 150 ps;
    s_en <= '1';
    wait for 700 ps;
    s_en <= '0';
    wait;
  end process;
  d : process
  begin
    s_d <= 'U';
    wait for 150 ps;
    s_d <= '1';
    wait for 300 ps;
    s_d <= '0';
    wait for 100 ps;
    s_d <= '1';
    wait for 100 ps;
    s_d <= 'U';
    wait for 100 ps;
    s_d <= '1';
    wait;
  end process;
end stimulus;
