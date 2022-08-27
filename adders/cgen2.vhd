library ieee;
use ieee.std_logic_1164.all;

entity cgen2 is
	port
	(
		carry	:	in	std_logic;
		pi		:	in	std_logic;
		gi		:	in	std_logic;
		pi_1	:	in	std_logic;		--	pi+1
		gi_1	:	in	std_logic;		--	gi+1
		
		ci_1	:	out	std_logic;		--	ci+1
		ci_2	:	out std_logic;		--	ci+2
		BP		:	out	std_logic;
		BG		:	out	std_logic
	);
end cgen2;

architecture BHV of cgen2 is

begin
	
	ci_1 <= gi or (pi and carry);
	ci_2 <= gi_1 or (pi_1 and (gi or (pi and carry)));
	
	BP <= pi and pi_1;
	BG <= gi_1 or (pi_1 and gi);
	
end BHV;