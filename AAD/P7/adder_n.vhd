--
-- Tomás Oliveira e Silva,  September 2026
--
-- Arquiteturas de Alto Desempenho 2026/2027
--
-- VHDL
--
-- structural implementation of a generic N-bit full adder
--

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;

entity adder_n is
  generic(N     : positive := 8);
     port(a     : in  std_logic_vector(N-1 downto 0);
          b     : in  std_logic_vector(N-1 downto 0);
          c_in  : in  std_logic;
          s     : out std_logic_vector(N-1 downto 0);
          c_out : out std_logic);
end adder_n;

architecture structural of adder_n is
  signal s_carry_in  : std_logic_vector(N-1 downto 0);
  signal s_carry_out : std_logic_vector(N-1 downto 0);
begin
  s_carry_in(0) <= c_in;
  c_out <= s_carry_out(N-1);
  gen_adder : for i in 0 to (N-1) generate
       adder:   entity work.full_adder(structural)
                       port map(a     => a(i),
                                b     => b(i),
                                c_in  => s_carry_in(i),
                                s     => s(i),
                                c_out => s_carry_out(i));
  end generate;
  gen_carry : for i in 1 to (N-1) generate
    s_carry_in(i) <= s_carry_out(i-1);
  end generate;
end structural;
