library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_en_tb is 
end reg_en_tb;

architecture TB of reg_en_tb is 

	constant TEST_WIDTH : positive := 16;
	
	signal clk		: std_logic := '0';
	signal rst		: std_logic;
	signal en		: std_logic := '0';
	signal input	: std_logic_vector(TEST_WIDTH-1 downto 0) := (others => '0');
	signal output	: std_logic_vector(TEST_WIDTH-1 downto 0);
	
begin	-- TB
	
	U_REG	:	entity work.reg_en
		generic map
		(
			WIDTH	=>	TEST_WIDTH
		)
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst,
			en		=>	en,
			input	=>	input,
			output	=>	output
		);
	
	clk <= not clk after 10 ns;
	
	process
	begin
		rst <= '1';
		wait for 100 ns;
		rst <= '0';
		
		for i in 0 to 2**(TEST_WIDTH-1) loop
			if (i > 50) then
				en <= '1';
			end if;
			
			input <= std_logic_vector(to_unsigned(i, TEST_WIDTH));
			wait until rising_edge(clk);			
		end loop;
		
		report "SIMULATION FINISHED!!!";
		wait;
	end process;
end TB;