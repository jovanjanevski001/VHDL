library ieee;
use ieee.std_logic_1164.all;

package decoder7seg_package is 
	
	subtype retType is std_logic_vector(6 downto 0);
	
	constant	c_0	:	std_logic_vector(6 downto 0)	:= "1000000";
	constant	c_1	:	std_logic_vector(6 downto 0)	:= "1111001";
	constant	c_2	:	std_logic_vector(6 downto 0)	:= "0100100";
	constant	c_3	:	std_logic_vector(6 downto 0)	:= "0110000";
	constant	c_4	:	std_logic_vector(6 downto 0)	:= "0011001";
	constant	c_5	:	std_logic_vector(6 downto 0)	:= "0010010";
	constant	c_6	:	std_logic_vector(6 downto 0)	:= "0000010";
	constant	c_7	:	std_logic_vector(6 downto 0)	:= "1111000";
	constant	c_8	:	std_logic_vector(6 downto 0)	:= "0000000";
	constant	c_9	:	std_logic_vector(6 downto 0)	:= "0011000";
	constant	c_A	:	std_logic_vector(6 downto 0)	:= "0001000";
	constant	c_B	:	std_logic_vector(6 downto 0)	:= "0000011";
	constant	c_C	:	std_logic_vector(6 downto 0)	:= "0100111";
	constant	c_D	:	std_logic_vector(6 downto 0)	:= "0100001";
	constant	c_E	:	std_logic_vector(6 downto 0)	:= "0000110";
	constant	c_F	:	std_logic_vector(6 downto 0)	:= "0001110";
	
	pure function decode7seg_func
		(input : std_logic_vector(3 downto 0))
			return retType;
	
end package decoder7seg_package;

package body decoder7seg_package is
	
	pure function decode7seg_func
		(input : std_logic_vector(3 downto 0))
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
	end;	--	decode7seg_func
	
end package body decoder7seg_package;