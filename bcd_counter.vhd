library ieee;
use ieee.std_logic_1164.all;
 
-- A NUM_DIGITS-digit decimal counter, one bcd_digit per digit, wrapping to 0 after all nines.
-- It counts once for every clock edge on which en = '1'.
-- digits holds the number in BCD, the most significant digit in the top four bits:
--     digits(3 downto 0) is the ones, digits(7 downto 4) the tens, ...
entity bcd_counter is
    generic
    (
        NUM_DIGITS : positive := 6
    );
    port
    (
        clk    : in  std_logic;
        rst    : in  std_logic;
        en     : in  std_logic;
        digits : out std_logic_vector(4*NUM_DIGITS-1 downto 0)
    );
end bcd_counter;
 
architecture STR of bcd_counter is
    signal step : std_logic_vector(NUM_DIGITS downto 0);      -- step(k) = digit k counts now
begin
    step(0) <= en;
 
    G_DIGIT : for k in 0 to NUM_DIGITS-1 generate
        U_DIGIT : entity work.bcd_digit
            port map
            (
                clk   => clk,
                rst   => rst,
                en    => step(k),
                digit => digits(4*k+3 downto 4*k),
                carry => step(k+1)
            );
    end generate G_DIGIT;
end STR;