library ieee;
use ieee.std_logic_1164.all;

entity clk_gen is
	generic
	(
		ms_period	:	positive		--	amount of time button is pressed down for to create a clock pulse
	);
	
	port
	(
		clk50MHz	:	in	std_logic;
		rst			:	in	std_logic;
		button_n	:	in	std_logic;
		clk_out 	:	out	std_logic
	);	
end clk_gen;

architecture STR of clk_gen is
	
	signal pulse		:	std_logic;	--	output of clk_div, generates 1 clk pulse
	signal count		:	integer := 0;
	signal next_count 	:	integer := 0;
	
begin
	
	U_CLK_DIV :	entity work.clk_div
		generic map
		(
			clk_in_freq		=>	50000000,
			clk_out_freq	=>	1000
		)
		
		port map
		(
			clk_in		=>	clk50MHz,
			rst 		=>	rst,
			clk_out		=>	pulse
		);
	
	-- Sequential Logic
	process(pulse, rst)
	begin
		if (rst = '1') then
			count <= 0;
		elsif (rising_edge(pulse)) then
			count <= next_count;
		end if;
	end process;
	
	-- Combinatorial Logic
	process(button_n, count)
	begin
		if (button_n = '0') then	-- button pressed			
			if ((count = ms_period-1)) then		
				clk_out <= '1';
				next_count <= 0;
			else
				clk_out <= '0';
				next_count <= count + 1;
			end if;
		else
			clk_out <= '0';	
			next_count <= 0;
		end if;
	end process;
end STR;