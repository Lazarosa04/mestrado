--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- behavioral and structural implementations of a one bit full adder slice
--

library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder is
   port(a     : in  std_logic;
        b     : in  std_logic;
        c_in  : in  std_logic;
        s     : out std_logic;
        c_out : out std_logic);
end full_adder;

architecture behavioral of full_adder is
begin
  s <= a xor b xor c_in;
  c_out <= (a and b) or (a and c_in) or (b and c_in);
end behavioral;

architecture structural of full_adder is
  signal s_and_ab : std_logic;
  signal s_and_ac : std_logic;
  signal s_and_bc : std_logic;
begin
  -- s <= a xor b xor c_in;
  my_xor :    entity work.xor_gate_3(behavioral)
                     port map(input0  => a,
                              input1  => b,
                              input2  => c_in,
                              output0 => s);
  -- c_out <= (a and b) or (a and c_in) or (b and c_in);
  my_and_ab : entity work.and_gate_2(behavioral)
                     port map(input0  => a,
                              input1  => b,
                              output0 => s_and_ab);
  my_and_ac : entity work.and_gate_2(behavioral)
                     port map(input0  => a,
                              input1  => c_in,
                              output0 => s_and_ac);
  my_and_bc : entity work.and_gate_2(behavioral)
                     port map(input0  => b,
                              input1  => c_in,
                              output0 => s_and_bc);
  my_or     : entity work.or_gate_3(behavioral)
                     port map(input0  => s_and_ab,
                              input1  => s_and_ac,
                              input2  => s_and_bc,
                              output0 => c_out);
end structural;
