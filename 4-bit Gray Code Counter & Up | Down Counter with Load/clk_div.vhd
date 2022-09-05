library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity clk_div is
    generic
	(
		clk_in_freq		:	natural;
		clk_out_freq 	:	natural
	);
	
	port
	(
		clk_in	:	in std_logic;
		rst 	:	in std_logic;
		clk_out	:	out std_logic
	);

end clk_div;

architecture BHV of clk_div is

constant NUM_BITS :	positive := integer(ceil(log2(real(clk_in_freq))));
constant PERIOD : unsigned(NUM_BITS-1 downto 0) := to_unsigned(clk_in_freq, NUM_BITS) / to_unsigned(clk_out_freq, NUM_BITS);

signal count, next_count  :	unsigned(NUM_BITS-1 downto 0) := (others => '0');

begin
	-- sequential logic
	process(clk_in, rst)
	begin
		if (rst = '1') then
			count <= (others => '0');
		elsif (rising_edge(clk_in)) then
			count <= next_count;
		end if;
	end process;
	
	-- combinatorial logic
	process(count)
	begin
		if (count = PERIOD) then
			clk_out <= '1';
			next_count <= (others => '0');
		else
			clk_out <= '0';
			next_count <= count + 1;
		end if;
	end process;
end BHV;