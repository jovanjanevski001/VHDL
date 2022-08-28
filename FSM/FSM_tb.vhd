library ieee;
use ieee.std_logic_1164.all;

entity FSM_tb is
end FSM_tb;

architecture TB of FSM_tb is

signal clk		:	std_logic := '0';
signal rst		:	std_logic;
signal en   	:	std_logic := '0';
signal output_1p:	std_logic_vector(3 downto 0);
signal output_2p:	std_logic_vector(3 downto 0);

begin	-- TB
	
	U_FSM_1P	:	entity work.FSM(PROC1)
		port map
		(
			clk		=>	clk,
			rst		=>	rst,		
			en		=>	en,		
			output	=>	output_1p	
		);
	
	U_FSM_2P	:	entity work.FSM(PROC2)
		port map
		(
			clk		=>	clk,
			rst		=>	rst,		
			en		=>	en,		
			output	=>	output_2p	
		);
		
		
	clk <= not clk after 10 ns;
		
	process
	begin
		
		rst <= '1';
		wait for 50 ns;
		rst <= '0';
		
		en <= '1';
		wait for 20 ns;
		
		while (true) loop
			wait until rising_edge(clk);
		end loop;
		wait;
	
	end process;
end TB;