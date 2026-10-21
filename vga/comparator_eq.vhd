library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comparator_eq is
	generic
	(
		WIDTH : positive := 8
	);
	port
	(
		in1	: in  std_logic_vector(WIDTH-1 downto 0);
		in2	: in  std_logic_vector(WIDTH-1 downto 0);
		eq	: out std_logic
	);
end comparator_eq;
 
architecture BHV of comparator_eq is
begin

	eq <= '1' when unsigned(in1) = unsigned(in2) else '0';
	
end BHV;