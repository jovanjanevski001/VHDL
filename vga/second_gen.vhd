library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
-- One pulse per second: tick is '1' for one clock out of every TICKS_PER_SEC clocks, so
-- TICKS_PER_SEC is the clock frequency in Hz. Built from the reusable parts (adder, mux_2x1,
-- reg_en, comparator_eq): the counter counts 0 .. TICKS_PER_SEC-1 and clears after the last one.
entity second_gen is
    generic
    (
        TICKS_PER_SEC : positive := 25_175_000
    );
    port
    (
        clk  : in  std_logic;
        rst  : in  std_logic;                   -- active high
        tick : out std_logic
    );
end second_gen;
 
architecture STR of second_gen is
    -- bits needed to count 0 .. TICKS_PER_SEC-1
    function bits_for(n : positive) return positive is
        variable w : positive := 1;
    begin
        while (2 ** w) < n loop
            w := w + 1;
        end loop;
        return w;
    end function;
 
    constant W : positive := bits_for(TICKS_PER_SEC);
 
    constant C_ZERO : std_logic_vector(W-1 downto 0) := (others => '0');
    constant C_ONE  : std_logic_vector(W-1 downto 0) := std_logic_vector(to_unsigned(1, W));
    constant C_LAST : std_logic_vector(W-1 downto 0) := std_logic_vector(to_unsigned(TICKS_PER_SEC - 1, W));
    constant ENABLE : std_logic := '1';
 
    signal cnt, cnt_1, cnt_nxt : std_logic_vector(W-1 downto 0);
    signal at_last             : std_logic;
begin
    U_INC : entity work.adder
        generic map ( WIDTH => W )
        port map ( in1 => cnt, in2 => C_ONE, output => cnt_1 );
 
    U_LAST : entity work.comparator_eq
        generic map ( WIDTH => W )
        port map ( in1 => cnt, in2 => C_LAST, eq => at_last );
 
    U_CLR : entity work.mux_2x1
        generic map ( WIDTH => W )
        port map ( in1 => cnt_1, in2 => C_ZERO, sel => at_last, output => cnt_nxt );
 
    U_REG : entity work.reg_en
        generic map ( WIDTH => W )
        port map ( clk => clk, rst => rst, en => ENABLE, input => cnt_nxt, output => cnt );
 
    tick <= at_last;
end STR;