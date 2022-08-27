library ieee;
use ieee.std_logic_1164.all;

entity cla4 is
	port
	(
		x		:	in	std_logic_vector(3 downto 0);
		y		:	in	std_logic_vector(3 downto 0);
		cin		:	in	std_logic;
		
		s		:	out	std_logic_vector(3 downto 0);
		cout	:	out	std_logic;
		BP		:	out	std_logic;
		BG		:	out	std_logic
	);
end cla4;

architecture STR of cla4 is

signal carry	:	std_logic;
signal p0, g0	:	std_logic;
signal p1, g1	:	std_logic;

begin	
	
	U_CLA2_0	:	entity work.cla2
		port map 
		(
			x		=>	x(1 downto 0),
			y		=>	y(1 downto 0),
			cin		=>	cin,
			
			s		=>	s(1 downto 0),
			BP		=>	p0,
			BG		=>	g0
		);
	
	U_CLA2_1	:	entity work.cla2
		port map 
		(
			x		=>	x(3 downto 2),
			y		=>	y(3 downto 2),
			cin		=>	carry,
			
			s		=>	s(3 downto 2),
			BP		=>	p1,
			BG		=>	g1
		);
			
	U_CGEN		:	entity work.cgen2
		port map
		(
			carry	=>	cin,
			pi		=>	p0,
			gi		=>	g0,
			pi_1	=>	p1,
			gi_1	=>	g1,

			ci_1	=>	carry,
			ci_2	=>	cout,
			BP		=>	BP,
			BG		=>	BG
		);
end STR;