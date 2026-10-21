library ieee;
use ieee.std_logic_1164.all;
 
-- STAGES clock cycles of delay for a WIDTH-bit bus (a shift register). No reset: it
-- carries a continuous stream, and the first STAGES outputs after start-up are don't-care.
entity delay_line is
	generic
	(
		WIDTH  : positive := 1;
		STAGES : positive := 1
	);
	
	port
	(
		clk		: in  std_logic;
		input	: in  std_logic_vector(WIDTH-1 downto 0);
		output	: out std_logic_vector(WIDTH-1 downto 0)
	);
end delay_line;
 
architecture BHV of delay_line is

	type stage_array_t is array (0 to STAGES-1) of std_logic_vector(WIDTH-1 downto 0);
	signal stage : stage_array_t;
	
begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			stage(0) <= input;
			for i in 1 to STAGES-1 loop
				stage(i) <= stage(i-1);
			end loop;
		end if;
	end process;
	
	output <= stage(STAGES-1);
	
end BHV;