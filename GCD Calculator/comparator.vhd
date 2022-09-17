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
	    x : in std_logic_vector(WIDTH-1 downto 0);
	    y : in std_logic_vector(WIDTH-1 downto 0);
		
		x_lt_y	: out std_logic;
		x_ne_y	: out std_logic
	);
end comparator;

architecture BHV of comparator is
begin
	process(x, y)
	begin
	    x_lt_y <= '0';
		x_ne_y <= '0';
		
		if (unsigned(x) < unsigned(y)) then
			x_lt_y <= '1';
		end if;
		
		if (unsigned(x) /= unsigned(y)) then
			x_ne_y <= '1';
		end if;
	end process;
end BHV;