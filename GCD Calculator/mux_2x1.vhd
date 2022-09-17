library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1 is
    generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		in1		:	in	std_logic_vector(WIDTH-1 downto 0);
		in2		:	in	std_logic_vector(WIDTH-1 downto 0);
		sel		:	in	std_logic;
		output	:	out std_logic_vector(WIDTH-1 downto 0)
	);
end mux_2x1;

architecture BHV of mux_2x1 is
begin
	-- when-else approach
    output <= in1 when sel = '0' else
	          in2 when sel = '1';
end BHV;