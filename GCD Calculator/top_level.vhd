library ieee;
use ieee.std_logic_1164.all;

entity top_level is
	port
	(
		clk		:	in 	std_logic;
		switch	:	in	std_logic_vector(9 downto 0);
		button	:	in	std_logic_vector(1 downto 0);
				
		led0	:	out	std_logic_vector(6 downto 0);
		led1	:	out	std_logic_vector(6 downto 0);
		led2	:	out	std_logic_vector(6 downto 0);
		led3	:	out	std_logic_vector(6 downto 0);
		led4	:	out	std_logic_vector(6 downto 0);
		led5	:	out	std_logic_vector(6 downto 0);
		
		ledr	:	out	std_logic_vector(9 downto 0);
		
		led0_dp	:	out	std_logic;
		led1_dp	:	out	std_logic;
		led2_dp	:	out	std_logic;
		led3_dp	:	out	std_logic;
		led4_dp	:	out	std_logic;
		led5_dp	:	out	std_logic
	);
end top_level;

architecture STR of top_level is

	constant WIDTH : positive := 8;
	constant C_0   : std_logic_vector(3 downto 0)	:= "0000";	--	to display 0 on the unused 7segs
	
	signal rst	   : std_logic;
	signal go		: std_logic;
	signal x,y	   : std_logic_vector(WIDTH-1 downto 0);
	signal output  : std_logic_vector(WIDTH-1 downto 0);
	signal done	   : std_logic;
	
begin
	
	go <= button(1);
	rst <= not button(0);		--	buttons are active low, need to invert them
	
	-- hardcoded the upper 3 bits, not enough switches for 8 bits inputs
	x <= "000" & switch(4 downto 0);	
	y <= "000" & switch(9 downto 5);
	
	U_GCD : entity work.gcd(FSMD2)
		generic map ( WIDTH => WIDTH)
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst,		
			go		=>	go,
			x		=>	x,	
			y		=>	y,
			
			done	=>	done, 	-- tie to dp of a 7seg
			output	=>	output	-- tie to 2 of the 7segs
		);
	
	U_LED0 :	entity work.decoder7seg
		port map
		(
			input  =>  output(3 downto 0),
			output =>  led0
		);
	
	U_LED1 :	entity work.decoder7seg
		port map
		(
			input  =>  output(7 downto 4),
			output =>  led1
		);
	
	led1_dp <= not done;
	
	---------------------------------------
	---------------------------------------
	------	 UNUSED OUTPUTS BELOW	 ------
	---------------------------------------
	---------------------------------------
	U_LED2 :	entity work.decoder7seg
		port map
		(
			input  =>  C_0,
			output =>  led2
		);
	
	U_LED3 :	entity work.decoder7seg
		port map
		(
			input  =>  C_0,
			output =>  led3
		);
	
	U_LED4 :	entity work.decoder7seg
		port map
		(
			input  =>  C_0,
			output =>  led4
		);
	
	U_LED5 :	entity work.decoder7seg
		port map
		(
			input  =>  C_0,
			output =>  led5
		);
	
	ledr <= (others => '0');
	
	led0_dp <= '1';
	led2_dp <= '1';
	led3_dp <= '1';
	led4_dp <= '1';
	led5_dp <= '1';
	
end STR;