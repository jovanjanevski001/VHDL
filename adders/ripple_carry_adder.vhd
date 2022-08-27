library ieee;
use ieee.std_logic_1164.all;

entity ripple_carry_adder is
	generic
	(
		WIDTH	:	positive := 16
	);
	
	port
	(
		in1			:	in	std_logic_vector(WIDTH-1 downto 0);
		in2			:	in	std_logic_vector(WIDTH-1 downto 0);
		carry_in	:	in	std_logic;
		
		sum			:	out	std_logic_vector(WIDTH-1 downto 0);
		carry_out	:	out	std_logic
	);
	
end ripple_carry_adder;

architecture STR of ripple_carry_adder is

signal carrys	:	std_logic_vector(WIDTH downto 0) := (others => '0');

begin
	
	-- Generates all the FAs in the middle
	FOR_GEN: for i in 0 to WIDTH-1 generate
		
		FA : entity work.fa
			port map
			(
				in1			=>	in1(i),
				in2			=>	in2(i),
				carry_in	=>	carrys(i),
				
				sum			=>	sum(i),
				carry_out	=>	carrys(i+1)	
			);
		
	end generate;
	
	carrys(0) <= carry_in;
	carry_out <= carrys(WIDTH);
	
end STR;