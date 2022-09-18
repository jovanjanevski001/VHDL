library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator is
	generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		i     	:	in	std_logic_vector(WIDTH-1 downto 0);
		n     	:	in	std_logic_vector(WIDTH-1 downto 0);
		i_le_n	:	out	std_logic
	);
	
end comparator;

architecture BHV of comparator is
begin
	process(i, n)
	begin
		if (unsigned(i) <= unsigned(n)) then
			i_le_n <= '1';
		else
			i_le_n <= '0';
		end if;
	end process;
end BHV;