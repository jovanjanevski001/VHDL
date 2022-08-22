library ieee;
use ieee.std_logic_1164.all;

entity top_level is
	port
	(
		switch	:	in	std_logic_vector(9 downto 0);
		button	:	in	std_logic_vector(1 downto 0);
	
		ledr	:	out std_logic_vector(9 downto 0);		-- LEDs above the switches
		
		-- 7seg displays 
		led0	:	out std_logic_vector(6 downto 0);
		led1	:	out std_logic_vector(6 downto 0);
		led2	:	out std_logic_vector(6 downto 0);
		led3	:	out std_logic_vector(6 downto 0);
		led4	:	out std_logic_vector(6 downto 0);
		led5	:	out std_logic_vector(6 downto 0);
		
		-- 7seg dp displays
		led0_dp	:	out	std_logic;
		led1_dp	:	out	std_logic;
		led2_dp	:	out	std_logic;
		led3_dp	:	out	std_logic;
		led4_dp	:	out	std_logic;
		led5_dp	:	out	std_logic
	);
end top_level;

architecture STR of top_level is

constant WIDTH	:	positive := 4;

signal alu_out		:	std_logic_vector(WIDTH-1 downto 0);
signal alu_overflow	:	std_logic;
signal sel 			:	std_logic_vector(3 downto 0);

begin
	
	sel <= not(button) & switch(1 downto 0);
	
	U_ALU :	entity work.alu
		generic map
		(
			WIDTH	=>	WIDTH
		)
		
		port map
		(
			input1	 => 	switch(9 downto 6),
			input2	 => 	switch(5 downto 2),
			sel		 => 	sel,
			
			output	 => 	alu_out,
			overflow => 	alu_overflow
		);


	U_7SEG_INPUT1 :	entity work.decoder7seg
		port map
		(
			input	=>	switch(9 downto 6),
			output	=>	led0	
		);

	U_7SEG_INPUT2 :	entity work.decoder7seg
		port map
		(
			input	=>	switch(5 downto 2),
			output	=>	led1
		);
	
	
	U_7SEG_OUTPUT : entity work.decoder7seg
		port map
		(
			input	=>	alu_out,
			output	=>	led2	
		);


	led2_dp <= not alu_overflow;		--	since led2_dp is active low, invert alu_overflow
	
	
	-- 7segs and LEDS not in use below, turning them off...
	led3 <= (others => '1');
	led4 <= (others => '1');
	led5 <= (others => '1');
	
	led0_dp <= '1';
	led1_dp <= '1';
	led3_dp <= '1';
	led4_dp <= '1';
	led5_dp <= '1';
	
	ledr <= (others => '0');
	
end STR;