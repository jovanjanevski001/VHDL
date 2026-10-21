library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package vga_pkg is

    -- ============================================================
    -- VGA timing: 640 x 480 @ 60 Hz
    -- ============================================================

    constant H_VISIBLE : positive := 640;
    constant H_FRONT   : positive := 16;
    constant H_SYNC    : positive := 96;
    constant H_BACK    : positive := 48;
    constant H_TOTAL   : positive := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    constant V_VISIBLE : positive := 480;
    constant V_FRONT   : positive := 10;
    constant V_SYNC    : positive := 2;
    constant V_BACK    : positive := 33;
    constant V_TOTAL   : positive := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;


    -- ============================================================
    -- VGA data types
    -- ============================================================

    constant COOR_WIDTH : positive := 10;

    subtype coor_width_t  is std_logic_vector(COOR_WIDTH - 1 downto 0);
    subtype color_width_t is std_logic_vector(3 downto 0);
    subtype pattern_sel_t is std_logic_vector(2 downto 0);

    -- RGB data from the eight VGA pattern sources.
    type pixel_array_t is array (0 to 7) of std_logic_vector(11 downto 0);


    -- ============================================================
    -- VGA counter constants
    -- ============================================================

    constant C_ZERO : coor_width_t := std_logic_vector(to_unsigned(0, COOR_WIDTH));
    constant C_ONE  : coor_width_t := std_logic_vector(to_unsigned(1, COOR_WIDTH));

    constant H_VISIBLE_END : coor_width_t := std_logic_vector(to_unsigned(H_VISIBLE - 1, COOR_WIDTH));
    constant H_FRONT_END   : coor_width_t := std_logic_vector(to_unsigned(H_VISIBLE + H_FRONT - 1, COOR_WIDTH));
    constant H_SYNC_END    : coor_width_t := std_logic_vector(to_unsigned(H_VISIBLE + H_FRONT + H_SYNC - 1, COOR_WIDTH));
    constant H_END         : coor_width_t := std_logic_vector(to_unsigned(H_TOTAL - 1, COOR_WIDTH));

    constant V_VISIBLE_END : coor_width_t := std_logic_vector(to_unsigned(V_VISIBLE - 1, COOR_WIDTH));
    constant V_FRONT_END   : coor_width_t := std_logic_vector(to_unsigned(V_VISIBLE + V_FRONT - 1, COOR_WIDTH));
    constant V_SYNC_END    : coor_width_t := std_logic_vector(to_unsigned(V_VISIBLE + V_FRONT + V_SYNC - 1, COOR_WIDTH));
    constant V_END         : coor_width_t := std_logic_vector(to_unsigned(V_TOTAL - 1, COOR_WIDTH));


    -- ============================================================
    -- VGA pipeline
    -- ============================================================

    -- Every pixel source produces its color PIXEL_LATENCY clocks
    -- after receiving x and y. Sync and visible signals are delayed
    -- by the same amount so all pixel sources remain aligned.
    constant PIXEL_LATENCY : positive := 2;


    -- ============================================================
    -- Border pattern
    -- ============================================================

    constant BORDER : positive := 4;


    -- ============================================================
    -- Bouncing square
    -- ============================================================

    constant SQUARE_SIZE    : positive := 32;
    constant SQUARE_SPEED_X : positive := 3;
    constant SQUARE_SPEED_Y : positive := 2;

    constant SQUARE_START_X : natural := (H_VISIBLE - SQUARE_SIZE) / 2;
    constant SQUARE_START_Y : natural := (V_VISIBLE - SQUARE_SIZE) / 2;


    -- ============================================================
    -- ROM image
    -- ============================================================

    -- 160 x 120 image stored as 12-bit RGB words.
    -- A scale factor of 4 expands the image to 640 x 480.
    constant IMAGE_MIF        : string   := "image.mif";
    constant IMG_W            : positive := 160;
    constant IMG_H            : positive := 120;
    constant IMG_ADDR_W       : positive := 15;
    constant IMAGE_SCALE_LOG2 : positive := 2;


    -- ============================================================
    -- Sprite
    -- ============================================================

    -- The sprite uses the bouncing-square motion logic, so its size
    -- must match SQUARE_SIZE.
    constant SPRITE_MIF    : string   := "sprite.mif";
    constant SPRITE_LOG2   : positive := 5;
    constant SPRITE_SIZE   : positive := 2**SPRITE_LOG2;
    constant SPRITE_ADDR_W : positive := 2 * SPRITE_LOG2;

    -- Transparent sprite color: magenta.
    constant SPRITE_KEY : std_logic_vector(11 downto 0) := x"F0F";


    -- ============================================================
    -- Text display
    -- ============================================================

    -- Live counter displayed in the top-right area of the text screen.
    constant LIVE_DIGITS : positive := 6;
    constant LIVE_LABEL  : string   := "COUNT ";
    constant LIVE_COL    : natural  := 68;
    constant LIVE_ROW    : natural  := 0;

    -- Background = 4 (blue), foreground = 15 (white).
    constant LIVE_ATTR : std_logic_vector(7 downto 0) := x"4F";


    -- ============================================================
    -- Accelerometer / SPI
    -- ============================================================

    constant BOARD_CLK_HZ     : positive := 50_000_000;
    constant SPI_HZ           : positive := 800_000;
    constant SPI_HALF_CLKS    : positive := BOARD_CLK_HZ / (2 * SPI_HZ);
    constant ACCEL_POLL_HZ    : positive := 100;
    constant ACCEL_POLL_CLKS  : positive := BOARD_CLK_HZ / ACCEL_POLL_HZ;
    constant ACCEL_LOOP_START : natural  := 6;


    -- ============================================================
    -- ADXL345 registers and commands
    -- ============================================================

    constant ADXL_READ            : std_logic_vector(7 downto 0) := x"80";
    constant ADXL_MULTI           : std_logic_vector(7 downto 0) := x"40";
    constant ADXL_REG_DEVID       : std_logic_vector(7 downto 0) := x"00";
    constant ADXL_REG_POWER_CTL   : std_logic_vector(7 downto 0) := x"2D";
    constant ADXL_REG_DATA_FORMAT : std_logic_vector(7 downto 0) := x"31";
    constant ADXL_REG_DATAX0      : std_logic_vector(7 downto 0) := x"32";

    constant ADXL_MEASURE  : std_logic_vector(7 downto 0) := x"08";
    constant ADXL_FULL_RES : std_logic_vector(7 downto 0) := x"08";
    constant ADXL_DEVID    : std_logic_vector(7 downto 0) := x"E5";


    -- ============================================================
    -- Accelerometer tilt control
    -- ============================================================

    -- ADXL345 readings use approximately 256 counts per g.
    constant TILT_DEADZONE : natural := 12;
    constant TILT_SHIFT    : natural := 4;

    constant TILT_INVERT_X : boolean := false;
    constant TILT_INVERT_Y : boolean := false;
    constant TILT_SWAP_XY  : boolean := false;

end package vga_pkg;