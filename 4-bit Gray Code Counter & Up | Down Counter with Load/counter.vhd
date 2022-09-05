library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    port
	(
        clk    : in  std_logic;
        rst    : in  std_logic;
        up_n   : in  std_logic;         -- active low
        load_n : in  std_logic;         -- active low
        input  : in  std_logic_vector(3 downto 0);
        output : out std_logic_vector(3 downto 0)
	);
end counter;

architecture BHV of counter is

	signal count, next_count : unsigned(3 downto 0);

begin
	process(clk, rst)
	begin
		if (rst = '1') then
			count <= (others => '0');
		elsif (rising_edge(clk)) then
			count <= next_count;			
		end if;
	end process;
	
	process(up_n, load_n, input, count)
	begin
		next_count <= count;				--	default value
		
		if (load_n = '0') then	
			next_count <= unsigned(input);	--	loads input from switches
		else
			if (up_n = '0') then			
				next_count <= count - 1;	--	unsigned will wrap count around if < 0
			else
				next_count <= count + 1;	--	unsigned will wrap to 0 if overflow occurs, i.e. > 15
			end if;
		end if;
	end process;
	
	output <= std_logic_vector(count);
end BHV;