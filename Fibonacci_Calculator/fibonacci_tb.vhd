library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fibonacci_tb is
end fibonacci_tb;

architecture TB of fibonacci_tb is

	constant WIDTH 	 : positive := 8;
	constant TIMEOUT : time 	:= 1 ms;

	signal clkEn  : std_logic	:= '1';	
	signal clk    : std_logic   := '0';
	signal rst    : std_logic   := '1';
	signal go     : std_logic   := '0';
	signal done   : std_logic;
	signal n	  : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal result : std_logic_vector(WIDTH-1 downto 0);


begin	-- TB
	
	UUT : entity work.fibonacci(FSMD2)		--	change to test different architectures
        generic map ( WIDTH => WIDTH )
        
		port map 
		(
            clk    => clk,
            rst    => rst,
            go     => go,
            done   => done,
			n	   => n,
            result => result
		);

    clk <= not clk and clkEn after 20 ns;

	process
	
		function FIB (n : integer)
			return std_logic_vector is
			
			variable i, x, y, temp, temp_n : integer;
		begin
			temp_n := n;
			i := 3;
			x := 1;
			y := 1;
			
			while(i <= temp_n) loop
				temp := x + y;
				x := y;
				y := temp;
				i := i + 1;
			end loop;
			
			return std_logic_vector(to_unsigned(y, WIDTH));
			
		end FIB;
		
	begin
		
		clkEn <= '1';
        rst   <= '1';
        go    <= '0';
		n	  <= (others => '0');
		wait for 200 ns;
		
		rst <= '0';
		for i in 0 to 5 loop
            wait until clk'event and clk = '1';
        end loop;  -- i
		
		for i in 0 to 15 loop
			
			go <= '1';
			n <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait until done = '1' for TIMEOUT;
			assert(done = '1') report "Done never asserted." severity warning;
			assert(result = FIB(i)) report "Incorrect FIB" severity warning;
			go <= '0';
			wait until clk'event and clk = '1';
			
		end loop; -- i
		
		clkEn <= '0';
		report "DONE!!!!!!" severity note;
		
		wait;
	end process;
end TB;