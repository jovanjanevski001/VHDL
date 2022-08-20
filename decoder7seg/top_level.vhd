library ieee;
use ieee.std_logic_1164.all;

-- This top level entity tests the functionality of all the 7seg displays, switches, buttons and LEDs.
entity top_level is
	port
	(
		switch	:	in	std_logic_vector(9 downto 0);		
		button	:	in	std_logic_vector(1 downto 0);
	
	
		ledr	:	out std_logic_vector(9 downto 0);		-- LEDs above the switches
		
		-- 7seg displays 
		led0	:	out	std_logic_vector(6 downto 0);
		led1	:	out	std_logic_vector(6 downto 0);
		led2	:	out	std_logic_vector(6 downto 0);
		led3	:	out	std_logic_vector(6 downto 0);
		led4	:	out	std_logic_vector(6 downto 0);
		led5	:	out	std_logic_vector(6 downto 0);
		
		-- 7seg dp displays
		led0_dp	:	out std_logic;
		led1_dp	:	out std_logic;
		led2_dp	:	out std_logic;
		led3_dp	:	out std_logic;
		led4_dp	:	out std_logic;
		led5_dp	:	out std_logic
		
	);
end top_level;

architecture STR of top_level is
		
	component decoder7seg
		port
		(
			input	:	in	std_logic_vector(3 downto 0);
			output	:	out	std_logic_vector(6 downto 0)
		);
	end component;
	
begin -- STR

	U_LED0 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led0
		);
		
	U_LED1 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led1
		);
	
	U_LED2 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led2
		);
	
	U_LED3 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led3
		);
	
	U_LED4 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led4
		);
	
	U_LED5 : decoder7seg 
		port map
		(
			input 	=> switch(3 downto 0),
			output	=> led5
		);
	
	
	led0_dp <= '0' when button(0) = '0' else
			   '1' when button(0) = '1';
	
	led1_dp <= '0' when button(0) = '0' else
			   '1' when button(0) = '1';
			   
	led2_dp <= '0' when button(0) = '0' else
			   '1' when button(0) = '1';
	
	
	led3_dp <= '0' when button(1) = '0' else
			   '1' when button(1) = '1';
	
	led4_dp <= '0' when button(1) = '0' else
			   '1' when button(1) = '1';
			   
	led5_dp <= '0' when button(1) = '0' else
			   '1' when button(1) = '1';
	
	
	-- Connecting the LEDs above the switches, 
	--	if switch is flipped on, then the LED above it will turn on
	ledr(0) <= '1' when switch(0) = '1' else
			   '0' when switch(0) = '0';
	
	ledr(1) <= '1' when switch(1) = '1' else
			   '0' when switch(1) = '0';
			  
	ledr(2) <= '1' when switch(2) = '1' else
			   '0' when switch(2) = '0';
			  
	ledr(3) <= '1' when switch(3) = '1' else
			   '0' when switch(3) = '0';	
			  
	ledr(4) <= '1' when switch(4) = '1' else
			   '0' when switch(4) = '0';
	
	ledr(5) <= '1' when switch(5) = '1' else
			   '0' when switch(5) = '0';
			  
	ledr(6) <= '1' when switch(6) = '1' else
			   '0' when switch(6) = '0';
			  
	ledr(7) <= '1' when switch(7) = '1' else
			   '0' when switch(7) = '0';		
			  
	ledr(8) <= '1' when switch(8) = '1' else
			   '0' when switch(8) = '0';
			  
	ledr(9) <= '1' when switch(9) = '1' else
			   '0' when switch(9) = '0';	

			   
end STR;