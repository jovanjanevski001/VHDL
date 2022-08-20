library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.decoder7seg_package.all;

entity decoder7seg_tb is
end decoder7seg_tb;

architecture TB of decoder7seg_tb is
	
	component decoder7seg
		port
		(
			input	:	in	std_logic_vector(3 downto 0);
			output	:	out	std_logic_vector(6 downto 0)
		);
	end component;
	
	signal input	:	std_logic_vector(3 downto 0) := (others => '0');
	signal output	:	std_logic_vector(6 downto 0);
	
	
begin -- TB
	
	U_7SEG	:	entity work.decoder7seg
		port map
		(
			input	=>	input,
			output	=>	output
		);
	
	process
		variable temp	:	std_logic_vector(3 downto 0);
			
	begin
		
		for i in 0 to 15 loop
		
			temp := std_logic_vector(to_unsigned(i, 4));
			input <= temp;
			wait for 20 ns;
			
			assert(std_match(output, decode7seg_func(input))) report "Error at input: " & integer'image(i) severity warning;
			
		end loop;
		
		report "Simulation Finished!" severity note;
		
		wait;
		
	end process;
end TB;