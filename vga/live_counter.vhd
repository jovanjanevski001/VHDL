library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;
 
-- The live value shown on the text screen: a decimal counter that goes up once a second.
-- Runs on the pixel clock (PIXEL_CLK_HZ in vga_pkg), so a second is exact.
-- digits is the number in BCD, LIVE_DIGITS digits, most significant digit in the top bits.
-- To show some other value instead, drive pattern_engine / text pattern live_digits from something else.
entity live_counter is
    port
    (
        clk    : in  std_logic;
        rst    : in  std_logic;                                  -- active high
        digits : out std_logic_vector(4*LIVE_DIGITS-1 downto 0)
    );
end live_counter;
 
architecture STR of live_counter is
    signal tick : std_logic;
begin
    U_SECOND : entity work.second_gen
        --generic map ( TICKS_PER_SEC => PIXEL_CLK_HZ )
        port map ( clk => clk, rst => rst, tick => tick );
 
    U_COUNT : entity work.bcd_counter
        generic map ( NUM_DIGITS => LIVE_DIGITS )
        port map ( clk => clk, rst => rst, en => tick, digits => digits );
end STR;
