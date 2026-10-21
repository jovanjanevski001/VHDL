library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
-- Counts 0 .. PERIOD-1 over and over; tick is '1' while the count is PERIOD-1, so it is one
-- pulse every PERIOD clocks. clr restarts the count from 0 (tick can then not fire until PERIOD
-- clocks later). Same parts as second_gen, plus the clear: adder, mux_2x1, reg_en, comparator_eq.
entity period_counter is
    generic
    (
        PERIOD : positive := 16
    );
    port
    (
        clk  : in  std_logic;
        rst  : in  std_logic;       -- active high
        clr  : in  std_logic;       -- restart the count
        tick : out std_logic
    );
end period_counter;
 

architecture STR of period_counter is

    function bits_for(n : positive) return positive is
        variable w : positive := 1;
    begin
        while (2 ** w) < n loop
            w := w + 1;
        end loop;
        return w;
    end function;
 
    constant WIDTH : positive := bits_for(PERIOD);
 
    constant C_ZERO : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    constant C_ONE  : std_logic_vector(WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, WIDTH));
    constant C_LAST : std_logic_vector(WIDTH-1 downto 0) := std_logic_vector(to_unsigned(PERIOD - 1, WIDTH));
    constant ENABLE : std_logic := '1';
 
    signal cnt, cnt_1, cnt_nxt : std_logic_vector(WIDTH-1 downto 0);
    signal at_last, restart    : std_logic;
	
begin
	
    U_INC : entity work.adder
        generic map ( WIDTH => WIDTH )
        port map 
		( 
			in1 	=> 	cnt, 
			in2 	=> 	C_ONE, 
			output 	=> 	cnt_1
		);
	
    U_LAST : entity work.comparator_eq
        generic map ( WIDTH => WIDTH )
        port map 
		( 
			in1 => cnt, 
			in2 => C_LAST, 
			eq 	=> at_last
		);
	
    restart <= at_last or clr;
 
    U_CLR : entity work.mux_2x1
        generic map ( WIDTH => WIDTH )
        port map 
		( 
			in1 	=> 	cnt_1, 
			in2 	=>	C_ZERO,
			sel 	=> 	restart, 
			output 	=> 	cnt_nxt 
		);
 
    U_REG : entity work.reg_en
        generic map ( WIDTH => WIDTH )
        port map 
		( 
			clk 	=> clk,
			rst 	=> rst, 
			en 		=> ENABLE,
			input 	=> cnt_nxt, 
			output 	=> cnt 
		);
 
    tick <= at_last;
	
end STR;