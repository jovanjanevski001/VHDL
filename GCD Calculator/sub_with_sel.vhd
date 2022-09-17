library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sub_with_sel is
	generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		in1 	: in  std_logic_vector(WIDTH-1 downto 0);
		in2 	: in  std_logic_vector(WIDTH-1 downto 0);
		sub_sel	: in  std_logic;
		output 	: out std_logic_vector(WIDTH-1 downto 0)
	);
end sub_with_sel;

architecture BHV of sub_with_sel is
begin
	
	output <= std_logic_vector(unsigned(in1) - unsigned(in2)) when sub_sel = '0' else
			  std_logic_vector(unsigned(in2) - unsigned(in1));	-- sub_sel = '1' means x_lt_y = '1'
	
end BHV;