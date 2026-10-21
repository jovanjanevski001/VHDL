library ieee;
use ieee.std_logic_1164.all;
 
-- One decimal digit that counts 0 to 9 and wraps back to 0. It steps when en = '1'; carry is '1'
-- while en = '1' and the digit is 9 (the next digit up steps at the same clock edge).
-- Built from the small reusable parts: the next value is digit + 1, or 0 when the digit is 9.
entity bcd_digit is
    port
    (
        clk   : in  std_logic;
        rst   : in  std_logic;                       -- active high
        en    : in  std_logic;
        digit : out std_logic_vector(3 downto 0);
        carry : out std_logic
    );
end bcd_digit;
 
architecture STR of bcd_digit is
    constant D_ONE  : std_logic_vector(3 downto 0) := "0001";
    constant D_NINE : std_logic_vector(3 downto 0) := "1001";
    constant D_ZERO : std_logic_vector(3 downto 0) := "0000";
 
    signal cur, cur_1, nxt : std_logic_vector(3 downto 0);
    signal is_nine         : std_logic;
begin
    U_INC : entity work.adder
        generic map ( WIDTH => 4 )
        port map ( in1 => cur, in2 => D_ONE, output => cur_1 );
 
    U_NINE : entity work.comparator_eq
        generic map ( WIDTH => 4 )
        port map ( in1 => cur, in2 => D_NINE, eq => is_nine );
 
    U_WRAP : entity work.mux_2x1
        generic map ( WIDTH => 4 )
        port map ( in1 => cur_1, in2 => D_ZERO, sel => is_nine, output => nxt );
 
    U_REG : entity work.reg_en
        generic map ( WIDTH => 4 )
        port map ( clk => clk, rst => rst, en => en, input => nxt, output => cur );
 
    digit <= cur;
    carry <= en and is_nine;
end STR;