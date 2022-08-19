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

		case input is
			
			when "0000" =>
				output <= c_0;
				
			when "0001" =>
				output <= c_1;
				
			when "0010" =>
				output <= c_2;
				
			when "0011" =>
				output <= c_3;
				
			when "0100" =>
				output <= c_4;
				
			when "0101" =>
				output <= c_5;
			
			when "0110" =>
				output <= c_6;
				
			when "0111" =>
				output <= c_7;
				
			when "1000" =>
				output <= c_8;
				
			when "1001" =>
				output <= c_9;
				
			when "1010" =>
				output <= c_A;
				
			when "1011" =>
				output <= c_B;
				
			when "1100" =>
				output <= c_C;
				
			when "1101" =>
				output <= c_D;
				
			when "1110" =>
				output <= c_E;
			
			when "1111" => 
				output <= c_F;
			
			when others =>
				output <= "XXXXXXX";
			
		end case;
	end process;
end BHV;