library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;
 
-- Puts one pixel layer over another: where the front pixel is the transparent colour
-- SPRITE_KEY the back pixel shows, everywhere else the front pixel wins.
-- Purely combinational; both pixels must already be lined up in time. Layers can be stacked by
-- feeding one compositor's output into the back input of the next.
entity compositor is
    port
    (
        front : in  std_logic_vector(11 downto 0);     -- r & g & b of the upper layer
        back  : in  std_logic_vector(11 downto 0);     -- r & g & b of the layer behind
        pix   : out std_logic_vector(11 downto 0)
    );
end compositor;
 
architecture STR of compositor is
    signal is_key : std_logic;
begin
    U_KEY_CMP : entity work.comparator_eq
        generic map ( WIDTH => 12 )
        port map ( in1 => front, in2 => SPRITE_KEY, eq => is_key );
 
    U_PICK : entity work.mux_2x1
        generic map ( WIDTH => 12 )
        port map ( in1 => front, in2 => back, sel => is_key, output => pix );
end STR;