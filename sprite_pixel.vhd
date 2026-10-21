library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- The sprite as a pixel source: for the screen position (x, y) it gives the sprite pixel that
-- belongs there when the sprite's top-left corner is at (pos_x, pos_y), and the transparent
-- colour SPRITE_KEY everywhere outside the sprite (so the compositor shows what is behind it).
--
-- The ROM is synchronous: the colour arrives ONE clock after x and y (latency 1).
entity sprite_pixel is
    port
    (
        clk   : in  std_logic;
        x     : in  coor_width_t;
        y     : in  coor_width_t;
        pos_x : in  coor_width_t;
        pos_y : in  coor_width_t;
        r     : out color_width_t;
        g     : out color_width_t;
        b     : out color_width_t
    );
end sprite_pixel;
 
architecture STR of sprite_pixel is
    signal inside   : std_logic;
    signal inside_d : std_logic_vector(0 downto 0);
    signal inside_v : std_logic_vector(0 downto 0);
 
    signal rel_x, rel_y : std_logic_vector(x'length-1 downto 0);
    signal addr         : std_logic_vector(SPRITE_ADDR_W-1 downto 0);
    signal rom_q        : std_logic_vector(11 downto 0);
    signal pixel        : std_logic_vector(11 downto 0);
begin
    -- is the screen position inside the sprite's box?
    inside <= '1' when (unsigned(x) >= unsigned(pos_x) and
                        unsigned(x) <  unsigned(pos_x) + SPRITE_SIZE and
                        unsigned(y) >= unsigned(pos_y) and
                        unsigned(y) <  unsigned(pos_y) + SPRITE_SIZE) else '0';
 
    -- position inside the sprite; the box is a power of two wide, so the low bits are the position
    rel_x <= std_logic_vector(unsigned(x) - unsigned(pos_x));
    rel_y <= std_logic_vector(unsigned(y) - unsigned(pos_y));
 
    -- ROM address = row * SPRITE_SIZE + column. Outside the box the address is held at 0 so it
    -- never depends on a wrapped-around subtraction.
    addr <= (rel_y(SPRITE_LOG2-1 downto 0) & rel_x(SPRITE_LOG2-1 downto 0)) when inside = '1'
            else (others => '0');
 
    U_ROM : entity work.sprite_rom
        port map ( clock => clk, address => addr, q => rom_q );
 
    -- "inside" has to arrive together with the ROM data
    inside_v(0) <= inside;
 
    U_INSIDE_DLY : entity work.delay_line
        generic map ( WIDTH => 1, STAGES => 1 )
        port map ( clk => clk, input => inside_v, output => inside_d );
 
    -- inside the box: the ROM pixel; outside: the transparent colour
    U_KEY_MUX : entity work.mux_2x1
        generic map ( WIDTH => 12 )
        port map ( in1 => SPRITE_KEY, in2 => rom_q, sel => inside_d(0), output => pixel );
 
    r <= pixel(11 downto 8);
    g <= pixel(7 downto 4);
    b <= pixel(3 downto 0);
end STR;