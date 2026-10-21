library ieee;
use ieee.std_logic_1164.all;
 
-- Takes a held bus across from another clock using a toggle bit: the toggle is synchronized,
-- and when it changes the bus (which is steady by then) is stored. Use it for data that
-- changes rarely, with the toggle flipping at the same time the data changes.
entity toggle_capture is
    generic
    (
        WIDTH : positive := 32
    );
    port
    (
        clk       : in  std_logic;                              -- the receiving clock
        rst       : in  std_logic;                              -- active high
        data_in   : in  std_logic_vector(WIDTH-1 downto 0);     -- from the other clock, held
        toggle_in : in  std_logic;                              -- from the other clock
        data_out  : out std_logic_vector(WIDTH-1 downto 0)
    );
end toggle_capture;
 
architecture STR of toggle_capture is
    constant ENABLE : std_logic := '1';
    signal tog_in, tog_s, tog_d : std_logic_vector(0 downto 0);
    signal new_data             : std_logic;
begin
    tog_in(0) <= toggle_in;
 
    U_SYNC : entity work.sync_2ff
        generic map ( WIDTH => 1 )
        port map ( clk => clk, input => tog_in, output => tog_s );
 
    U_PREV : entity work.reg_en
        generic map ( WIDTH => 1 )
        port map ( clk => clk, rst => rst, en => ENABLE, input => tog_s, output => tog_d );
 
    new_data <= tog_s(0) xor tog_d(0);
 
    U_DATA : entity work.reg_en
        generic map ( WIDTH => WIDTH )
        port map ( clk => clk, rst => rst, en => new_data, input => data_in, output => data_out );
end STR;