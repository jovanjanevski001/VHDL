library ieee;
use ieee.std_logic_1164.all;
 

-- Two-flop synchronizer for slow, asynchronous inputs (switches) crossing into
-- the clk domain.
entity sync_2ff is
	generic
	(
		WIDTH : positive := 1
	);
	
	port
	(
		clk		: in  std_logic;
		input	: in  std_logic_vector(WIDTH-1 downto 0);
		output	: out std_logic_vector(WIDTH-1 downto 0)
	);
end sync_2ff;


architecture BHV of sync_2ff is

	signal meta : std_logic_vector(WIDTH-1 downto 0);
	
begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			meta   <= input;
			output <= meta;
		end if;
	end process;
	
end BHV;