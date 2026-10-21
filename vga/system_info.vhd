library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vga_pkg.all;


entity system_info is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        x : in coor_width_t;
        y : in coor_width_t;

        r : out color_width_t;
        g : out color_width_t;
        b : out color_width_t
    );
end system_info;


architecture rtl of system_info is

    --------------------------------------------------------------------
    -- Screen dimensions
    --------------------------------------------------------------------

    constant SCREEN_COLS : integer := 80;
    constant SCREEN_ROWS : integer := 60;


    --------------------------------------------------------------------
    -- One line of the VGA text screen
    --------------------------------------------------------------------

    subtype screen_line_t is string(1 to SCREEN_COLS);

    type screen_t is array(0 to SCREEN_ROWS - 1)
        of screen_line_t;


    --------------------------------------------------------------------
    -- Center a string on an 80-column line.
    --
    -- Example:
    --
    -- center("SYSTEM INFO")
    --
    -- produces an 80-character line with SYSTEM INFO centered.
    --------------------------------------------------------------------

    function center(
        text : string
    ) return screen_line_t is

        variable result : screen_line_t :=
            (others => ' ');

        variable start_pos : integer;

    begin

        if text'length >= SCREEN_COLS then

            -- If the text is too long, keep the first 80 characters.
            for i in 1 to SCREEN_COLS loop
                result(i) := text(text'low + i - 1);
            end loop;

        else

            -- Calculate the first character position.
            start_pos :=
                ((SCREEN_COLS - text'length) / 2) + 1;

            for i in 0 to text'length - 1 loop
                result(start_pos + i) :=
                    text(text'low + i);
            end loop;

        end if;

        return result;

    end function;


    --------------------------------------------------------------------
    -- System information screen
    --------------------------------------------------------------------

    constant SYSTEM_SCREEN : screen_t :=
    (
        8  => center("SYSTEM INFO"),

        14 => center("FPGA"),
        16 => center("MAX 10 10M50DAF484C7G"),
        19 => center("DE10-LITE"),

        23 => center("VIDEO"),
        25 => center("640 X 480 @ 60 HZ"),
        28 => center("80 X 60 TEXT"),
        31 => center("8 X 8 FONT"),

        35 => center("UART"),
        37 => center("115200 BAUD"),

        41 => center("ACCELEROMETER"),
        43 => center("STATUS: OK"),

        48 => center("ESC / LEFT: BACK"),

        others => (others => ' ')
    );


    --------------------------------------------------------------------
    -- Character coordinates
    --------------------------------------------------------------------

    signal cx : integer range 0 to 127;
    signal cy : integer range 0 to 63;


    --------------------------------------------------------------------
    -- Character / font signals
    --------------------------------------------------------------------

    signal char_code : std_logic_vector(7 downto 0);

    signal font_address : std_logic_vector(6 downto 0);
    signal font_data    : std_logic_vector(63 downto 0);


    --------------------------------------------------------------------
    -- Glyph coordinates
    --------------------------------------------------------------------

    signal glyph_x : unsigned(2 downto 0);
    signal glyph_y : unsigned(2 downto 0);

    signal glyph_x_d : unsigned(2 downto 0);
    signal glyph_y_d : unsigned(2 downto 0);


    --------------------------------------------------------------------
    -- RGB
    --------------------------------------------------------------------

    signal rgb_out : color_width_t;


begin

    --------------------------------------------------------------------
    -- Character-cell coordinates
    --------------------------------------------------------------------

    cx <= to_integer(unsigned(x(9 downto 3)));
    cy <= to_integer(unsigned(y(9 downto 3)));


    --------------------------------------------------------------------
    -- Pixel position within the 8 x 8 character
    --------------------------------------------------------------------

    glyph_x <= unsigned(x(2 downto 0));
    glyph_y <= unsigned(y(2 downto 0));


    --------------------------------------------------------------------
    -- Match existing font ROM timing
    --------------------------------------------------------------------

    process(clk, rst)
    begin

        if rst = '1' then

            glyph_x_d <= (others => '0');
            glyph_y_d <= (others => '0');

        elsif rising_edge(clk) then

            glyph_x_d <= glyph_x;
            glyph_y_d <= glyph_y;

        end if;

    end process;


    --------------------------------------------------------------------
    -- Existing font ROM
    --------------------------------------------------------------------

    U_FONT_ROM : entity work.font_rom
        port map
        (
            clock	=> clk,
            address => font_address,
            q       => font_data
        );


    --------------------------------------------------------------------
    -- ASCII -> font ROM address
    --
    -- Font ROM starts at ASCII 32 (space).
    --------------------------------------------------------------------

    font_address <= std_logic_vector(
        unsigned(char_code(6 downto 0)) - 32
    );


    --------------------------------------------------------------------
    -- Select the character for the current text cell
    --------------------------------------------------------------------

    process(clk, rst)

        variable ascii_value : integer;

    begin

        if rst = '1' then

            char_code <= x"20";

        elsif rising_edge(clk) then

            -- Default to space.
            char_code <= x"20";

            if (cx < SCREEN_COLS) and
               (cy < SCREEN_ROWS) then

                ascii_value :=
                    character'pos(
                        SYSTEM_SCREEN(cy)(cx + 1)
                    );

                char_code <= std_logic_vector(
                    to_unsigned(ascii_value, 8)
                );

            end if;

        end if;

    end process;


    --------------------------------------------------------------------
    -- Font pixel
    --------------------------------------------------------------------

    process(font_data, glyph_x_d, glyph_y_d)

        variable bit_index : integer;

    begin

        bit_index :=
            63
            - (to_integer(glyph_y_d) * 8)
            - to_integer(glyph_x_d);

        if font_data(bit_index) = '1' then
            rgb_out <= x"F";
        else
            rgb_out <= x"0";
        end if;

    end process;


    --------------------------------------------------------------------
    -- RGB output
    --------------------------------------------------------------------

    r <= rgb_out;
    g <= rgb_out;
    b <= rgb_out;


end rtl;