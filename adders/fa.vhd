library ieee;
use ieee.std_logic_1164.all;

entity fa is
	port
	(
		in1			:	in	std_logic;
		in2			:	in	std_logic;
		carry_in	:	in	std_logic;
		
		sum			:	out	std_logic;
		carry_out	:	out	std_logic
    );
end fa;

architecture BHV of fa is
begin
	
	sum <= in1 xor in2 xor carry_in;
	carry_out <= (in1 and carry_in) or (in2 and carry_in) or (in1 and in2);
	
end BHV;