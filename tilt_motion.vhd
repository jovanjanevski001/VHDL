library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- Position of a square driven by tilt: the tilt is the velocity. Each time tick = '1' (once per
-- frame) the position moves by a speed that follows the accelerometer reading, and it stops at
-- the edges of the visible area. pos_x / pos_y are the top-left corner, like bounce_motion.
--
--   speed = (|reading| - TILT_DEADZONE) / 2**TILT_SHIFT pixels per frame, toward the sign of the
--           reading; nothing inside the dead zone (the board lying flat does not creep).
--   TILT_INVERT_X / _Y flip a direction, TILT_SWAP_XY swaps the two axes (vga_pkg).
entity tilt_motion is
    port
    (
        clk    : in  std_logic;
        rst    : in  std_logic;
        tick   : in  std_logic;
        tilt_x : in  std_logic_vector(15 downto 0);		-- two's complement
        tilt_y : in  std_logic_vector(15 downto 0);
        pos_x  : out coor_width_t;
        pos_y  : out coor_width_t
    );
end tilt_motion;
 
architecture BHV of tilt_motion is
    constant MAX_X : natural := H_VISIBLE - SQUARE_SIZE;
    constant MAX_Y : natural := V_VISIBLE - SQUARE_SIZE;
 
    signal px : integer range 0 to MAX_X;
    signal py : integer range 0 to MAX_Y;
 
    -- reading -> pixels per frame (signed)
    function speed(reading : std_logic_vector(15 downto 0); invert : boolean) return integer is
        variable a   : integer := to_integer(signed(reading));
        variable mag : integer;
    begin
        if (a < 0) then
            mag := -a;
        else
            mag := a;
        end if;
 
        if (mag <= TILT_DEADZONE) then
            return 0;
        end if;
        mag := (mag - TILT_DEADZONE) / (2 ** TILT_SHIFT);
        if ((a < 0) /= invert) then
            return -mag;
        else
            return mag;
        end if;
    end function;
 
    signal vx, vy : integer range -4096 to 4096;
begin
    -- axes, optionally swapped
    vx <= speed(tilt_y, TILT_INVERT_X) when TILT_SWAP_XY else speed(tilt_x, TILT_INVERT_X);
    vy <= speed(tilt_x, TILT_INVERT_Y) when TILT_SWAP_XY else speed(tilt_y, TILT_INVERT_Y);
 
    process(clk, rst)
        variable nx : integer;
        variable ny : integer;
    begin
        if (rst = '1') then
            px <= SQUARE_START_X;
            py <= SQUARE_START_Y;
        elsif (rising_edge(clk)) then
            if (tick = '1') then
                nx := px + vx;
                ny := py + vy;
 
                if (nx < 0) then
                    nx := 0;
                elsif (nx > MAX_X) then
                    nx := MAX_X;
                end if;
 
                if (ny < 0) then
                    ny := 0;
                elsif (ny > MAX_Y) then
                    ny := MAX_Y;
                end if;
 
                px <= nx;
                py <= ny;
            end if;
        end if;
    end process;
 
    pos_x <= std_logic_vector(to_unsigned(px, coor_width_t'length));
    pos_y <= std_logic_vector(to_unsigned(py, coor_width_t'length));
end BHV;