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
		subtype retType is std_logic_vector(6 downto 0);
		
		variable temp	:	std_logic_vector(3 downto 0);
		
		function decoder7seg_test
		(	
			signal input	:	std_logic_vector(3 downto 0)
		)
			return retType is
			
		begin
		
			case input is
				
				when "0000" =>
					return c_0;
				
				when "0001" =>
					return c_1;
					
				when "0010" =>
					return c_2;
					
				when "0011" =>
					return c_3;
					
				when "0100" =>
					return c_4;
					
				when "0101" =>
					return c_5;
				
				when "0110" =>
					return c_6;
					
				when "0111" =>
					return c_7;
					
				when "1000" =>
					return c_8;
					
				when "1001" =>
					return c_9;
					
				when "1010" =>
					return c_A;
					
				when "1011" =>
					return c_B;
					
				when "1100" =>
					return c_C;
					
				when "1101" =>
					return c_D;
					
				when "1110" =>
					return c_E;
				
				when "1111" => 
					return c_F;
				
				when others =>
					return "XXXXXXX";
			
			end case;
		end decoder7seg_test;
		
	begin
		
		for i in 0 to 15 loop
		
			temp := std_logic_vector(to_unsigned(i, 4));
			input <= temp;
			wait for 20 ns;
			
			assert(std_match(output, decoder7seg_test(input))) report "Error at input: " & integer'image(i) severity warning;
			
		end loop;
		
		report "Simulation Finished!" severity note;
		
		wait;
		
	end process;
end TB;