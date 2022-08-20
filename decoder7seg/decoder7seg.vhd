library ieee;
use ieee.std_logic_1164.all;
use work.decoder7seg_package.all;

entity decoder7seg is
	port
	(
		input	:	in	std_logic_vector(3 downto 0);
		output	:	out	std_logic_vector(6 downto 0)
	);
end decoder7seg;


architecture BHV of decoder7seg is
begin

	process(input)
	begin
		output <= decode7seg_func(input);
	end process;
	
end BHV;