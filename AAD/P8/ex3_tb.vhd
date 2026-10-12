--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- testbench for the third exercise
--

library IEEE;
use IEEE.std_logic_1164.all;

entity ex3_tb is
end ex3_tb;

architecture stimulus of ex3_tb is
  signal s_clock : std_logic;
  signal s_w_addr : std_logic_vector(3 downto 0);
  signal s_w_data : std_logic_vector(3 downto 0);
  signal s_w_en   : std_logic;
  signal s_r_addr : std_logic_vector(3 downto 0);
  signal s_r_data : std_logic_vector(3 downto 0);
begin
  uut : entity work.dual_port_ram(asynchronous_new)
               generic map(ADDR_BITS => 4,
                           DATA_BITS => 4)
               port map(clock      => s_clock,
                        write_addr => s_w_addr,
                        write_data => s_w_data,
                        write_en   => s_w_en,
                        read_addr  => s_r_addr,
                        read_data  => s_r_data);
  clock : process
  begin
    s_clock <= '0';
    wait for 500 ps;
    for cycle in 0 to 8 loop
      wait for 500 ps;
      s_clock <= '1';
      wait for 500 ps;
      s_clock <= '0';
    end loop;
    wait for 500 ps;
    wait;
  end process;
  w_en : process
  begin
    s_w_en <= '0';
    wait for 1500 ps;
    s_w_en <= '1';
    wait for 8000 ps;
    s_w_en <= '0';
    wait;
  end process;
  w_addr_and_data : process
  begin
    s_w_addr <= X"U"; s_w_data <= X"U";
    wait for 1500 ps;
    s_w_addr <= X"3"; s_w_data <= X"2";
    wait for 1000 ps;
    s_w_addr <= X"3"; s_w_data <= X"7";
    wait for 1000 ps;
    s_w_addr <= X"3"; s_w_data <= X"4";
    wait for 1000 ps;
    s_w_addr <= X"5"; s_w_data <= X"F";
    wait for 1000 ps;
    s_w_addr <= X"B"; s_w_data <= X"2";
    wait for 1000 ps;
    s_w_addr <= X"3"; s_w_data <= X"A";
    wait for 1000 ps;
    s_w_addr <= X"3"; s_w_data <= X"0";
    wait for 1000 ps;
    s_w_addr <= X"5"; s_w_data <= X"4";
    wait for 1000 ps;
    s_w_addr <= X"3"; s_w_data <= X"6";
    wait;
  end process;
  r_addr : process
  begin
    s_r_addr <= X"0";
    wait for 1500 ps;
    s_r_addr <= X"3";
    wait for 1000 ps;
    s_r_addr <= X"3";
    wait for 1000 ps;
    s_r_addr <= X"3";
    wait for 1000 ps;
    s_r_addr <= X"3";
    wait for 1000 ps;
    s_r_addr <= X"B";
    wait for 1000 ps;
    s_r_addr <= X"5";
    wait for 1000 ps;
    s_r_addr <= X"3";
    wait for 700 ps;
    s_r_addr <= X"B";
    wait for 600 ps;
    s_r_addr <= X"3";
    wait for 700 ps;
    s_r_addr <= X"5";
    wait;
  end process;
end stimulus;
