library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
 
-- Slow square wave for the text cursor: flips every 30 frame ticks (half a second at 60 Hz).
entity blink_gen is
	port
	(
		clk		: in  std_logic;
		rst		: in  std_logic;		-- active high, synchronous to clk
		tick	: in  std_logic;		-- one pulse per frame
		blink	: out std_logic
	);
end blink_gen;
 
 
architecture BHV of blink_gen is
	
	constant FRAMES_PER_HALF : positive := 30;
 
	signal count   : integer range 0 to FRAMES_PER_HALF-1 := 0;
	signal blink_r : std_logic := '1';

begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				count   <= 0;
				blink_r <= '1';
			elsif (tick = '1') then
				if (count = FRAMES_PER_HALF-1) then
					count   <= 0;
					blink_r <= not blink_r;
				else
					count <= count + 1;
				end if;
			end if;
		end if;
	end process;
 
	blink <= blink_r;
	
end BHV;