library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level is
	port
	(
		clk50MHz :	in 	std_logic;
		switch	 :	in	std_logic_vector(9 downto 0);
		button	 :	in	std_logic_vector(1 downto 0);
				
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

constant C_0 : std_logic_vector(3 downto 0)	:= "0000";	--	to display 0 on the unused 7segs

signal clk_gen_out 	:	std_logic;
signal graycode_out	:	std_logic_vector(3 downto 0);		--	output of graycode FSM
signal counter_out	:	std_logic_vector(3 downto 0);		--	output of counter

begin
		
	U_CLK_GEN : entity work.clk_gen
		generic map
		(
			ms_period	=>	100		--	seconds the button needs to be pressed to generate
		)
		
		port map
		(
			clk50MHz	=>	clk50MHz,
			rst			=>	switch(0),
			button_n	=>	button(1),
			clk_out 	=>	clk_gen_out
		);
	
	
	U_GRAY_COUNTER :	entity work.gray_counter
		port map
		(
			clk    =>	clk_gen_out,
			rst    =>	switch(0),
			output =>	graycode_out
		);
	
	
	U_COUNTER :	entity work.counter
		port map
		(
			clk    =>	clk_gen_out,
			rst    =>	switch(0),
			up_n   =>	switch(5),
			load_n =>	switch(4),
			input  =>	switch(9 downto 6),
			output =>	counter_out
		);
	
	
	U_LED0 :	entity work.decoder7seg
		port map
		(
			input  =>  graycode_out,
			output =>  led0
		);
	
	U_LED1 :	entity work.decoder7seg
		port map
		(
			input  =>  counter_out,
			output =>  led1
		);
	
	
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
	led1_dp <= '1';
	led2_dp <= '1';
	led3_dp <= '1';
	led4_dp <= '1';
	led5_dp <= '1';
	
end STR;