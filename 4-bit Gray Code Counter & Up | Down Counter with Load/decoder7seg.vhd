library ieee;
use ieee.std_logic_1164.all;

entity decoder7seg is
	port
	(
		input	:	in	std_logic_vector(3 downto 0);
		output	:	out	std_logic_vector(6 downto 0)
	);
end decoder7seg;

architecture BHV of decoder7seg is 
	
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

begin
	
	with input select
		output <=
		c_0 when "0000",
		c_1 when "0001",
		c_2 when "0010",
		c_3 when "0011",
		c_4 when "0100",
		c_5 when "0101",
		c_6 when "0110",
		c_7 when "0111",
		c_8 when "1000",
		c_9 when "1001",
		c_A when "1010",
		c_B when "1011",
		c_C when "1100",
		c_D when "1101",
		c_E when "1110",
		c_F when "1111",
		c_F when others;
	
end BHV;