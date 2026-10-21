library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vga_pkg.all;


entity pattern_menu is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        x : in coor_width_t;
        y : in coor_width_t;

        menu_next  : in std_logic;
        menu_prev  : in std_logic;
        menu_enter : in std_logic;
        menu_back  : in std_logic;

        application_sel : out std_logic_vector(2 downto 0);
        menu_active     : out std_logic;

        vga_pattern_sel : out std_logic_vector(2 downto 0);
        vga_menu_active : out std_logic;

        r : out color_width_t;
        g : out color_width_t;
        b : out color_width_t
    );
end pattern_menu;


architecture rtl of pattern_menu is

    ----------------------------------------------------------------
    -- Main application selections
    ----------------------------------------------------------------
    constant APP_PONG   : integer := 0;
    constant APP_UART   : integer := 1;
    constant APP_VGA    : integer := 2;
    constant APP_ACCEL  : integer := 3;
    constant APP_SYSTEM : integer := 4;

    constant APP_FIRST : integer := APP_PONG;
    constant APP_LAST  : integer := APP_SYSTEM;


    ----------------------------------------------------------------
    -- VGA pattern selections
    ----------------------------------------------------------------
    constant VGA_BORDER  : integer := 0;
    constant VGA_BARS    : integer := 1;
    constant VGA_CHECKER : integer := 2;
    constant VGA_GRADIENT : integer := 3;
    constant VGA_SQUARE  : integer := 4;
    constant VGA_IMAGE   : integer := 5;
    constant VGA_SPRITE  : integer := 6;

    constant VGA_FIRST : integer := VGA_BORDER;
    constant VGA_LAST  : integer := VGA_SPRITE;


    ----------------------------------------------------------------
    -- Menu state
    ----------------------------------------------------------------
    signal menu_selection : integer range APP_FIRST to APP_LAST := APP_PONG;
    signal vga_selection  : integer range VGA_FIRST to VGA_LAST := VGA_BORDER;

    signal active_application : integer range APP_FIRST to APP_LAST := APP_PONG;

    signal menu_active_i      : std_logic := '1';
    signal vga_submenu_active : std_logic := '0';


    ----------------------------------------------------------------
    -- Character generator
    ----------------------------------------------------------------
    signal font_address : std_logic_vector(6 downto 0);
    signal font_data    : std_logic_vector(63 downto 0);

    signal char_code : std_logic_vector(7 downto 0);

    signal cx : integer range 0 to 127;
    signal cy : integer range 0 to 63;

    signal glyph_x : unsigned(2 downto 0);
    signal glyph_y : unsigned(2 downto 0);

    signal glyph_x_d : unsigned(2 downto 0);
    signal glyph_y_d : unsigned(2 downto 0);

    signal rgb_out : color_width_t;


    ----------------------------------------------------------------
    -- Convert an ASCII character to an 8-bit character code.
    ----------------------------------------------------------------
    function ascii(c : character) return std_logic_vector is
    begin
        return std_logic_vector(
            to_unsigned(character'pos(c), 8)
        );
    end function;


    ----------------------------------------------------------------
    -- Return one character from a string at a screen column.
    --
    -- start_col = screen column where the string begins.
    ----------------------------------------------------------------
    function text_char(
        text      : string;
        column    : integer;
        start_col : integer
    ) return std_logic_vector is

        variable index : integer;

    begin
        index := column - start_col + text'low;

        if index >= text'low and index <= text'high then
            return ascii(text(index));
        end if;

        return x"20";
    end function;


    ----------------------------------------------------------------
    -- Return the selection arrow.
    ----------------------------------------------------------------
    function selection_arrow(
        column      : integer;
        selected    : boolean
    ) return std_logic_vector is
    begin
        if (column = 28) and selected then
            return x"3E";
        end if;

        return x"20";
    end function;


begin

    ----------------------------------------------------------------
    -- Character coordinates
    ----------------------------------------------------------------
    cx <= to_integer(unsigned(x(9 downto 3)));
    cy <= to_integer(unsigned(y(9 downto 3)));

    glyph_x <= unsigned(x(2 downto 0));
    glyph_y <= unsigned(y(2 downto 0));


    ----------------------------------------------------------------
    -- Glyph timing
    --
    -- Keep the existing one-cycle coordinate delay to match the
    -- registered character code and one-clock font ROM.
    ----------------------------------------------------------------
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


    ----------------------------------------------------------------
    -- Font ROM
    ----------------------------------------------------------------
    U_FONT_ROM : entity work.font_rom
        port map
        (
            clock   => clk,
            address => font_address,
            q       => font_data
        );


    ----------------------------------------------------------------
    -- Font address
    --
    -- The font contains ASCII characters starting at space (32).
    ----------------------------------------------------------------
    font_address <= std_logic_vector(
        unsigned(char_code(6 downto 0)) - 32
    );


    ----------------------------------------------------------------
    -- Character generator
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            char_code <= x"20";

        elsif rising_edge(clk) then

            -- Default to space.
            char_code <= x"20";


            ----------------------------------------------------------------
            -- MAIN MENU
            ----------------------------------------------------------------
            if menu_active_i = '1' and vga_submenu_active = '0' then

                case cy is

                    --------------------------------------------------------
                    -- Title
                    --------------------------------------------------------
                    when 8 =>
                        char_code <= text_char(
                            "MAIN MENU",
                            cx,
                            35
                        );


                    --------------------------------------------------------
                    -- PONG
                    --------------------------------------------------------
                    when 16 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                menu_selection = APP_PONG
                            );
                        else
                            char_code <= text_char(
                                "PONG",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- UART TERMINAL
                    --------------------------------------------------------
                    when 19 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                menu_selection = APP_UART
                            );
                        else
                            char_code <= text_char(
                                "UART TERMINAL",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- VGA PATTERNS
                    --------------------------------------------------------
                    when 22 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                menu_selection = APP_VGA
                            );
                        else
                            char_code <= text_char(
                                "VGA PATTERNS",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- ACCELEROMETER
                    --------------------------------------------------------
                    when 25 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                menu_selection = APP_ACCEL
                            );
                        else
                            char_code <= text_char(
                                "ACCELEROMETER",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- SYSTEM INFO
                    --------------------------------------------------------
                    when 28 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                menu_selection = APP_SYSTEM
                            );
                        else
                            char_code <= text_char(
                                "SYSTEM INFO",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- Instructions
                    --------------------------------------------------------
                    when 31 =>
                        char_code <= text_char(
                            "UP/DOWN: SELECT ENTER: OPEN ESC: BACK",
                            cx,
                            28
                        );


                    when others =>
                        null;

                end case;


            ----------------------------------------------------------------
            -- VGA SUBMENU
            ----------------------------------------------------------------
            elsif vga_submenu_active = '1' then

                case cy is

                    --------------------------------------------------------
                    -- Title
                    --------------------------------------------------------
                    when 8 =>
                        char_code <= text_char(
                            "VGA PATTERNS",
                            cx,
                            34
                        );


                    --------------------------------------------------------
                    -- BORDER
                    --------------------------------------------------------
                    when 16 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_BORDER
                            );
                        else
                            char_code <= text_char(
                                "0  BORDER",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- BARS
                    --------------------------------------------------------
                    when 19 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_BARS
                            );
                        else
                            char_code <= text_char(
                                "1  BARS",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- CHECKER
                    --------------------------------------------------------
                    when 22 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_CHECKER
                            );
                        else
                            char_code <= text_char(
                                "2  CHECKER",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- GRADIENT
                    --------------------------------------------------------
                    when 25 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_GRADIENT
                            );
                        else
                            char_code <= text_char(
                                "3  GRADIENT",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- MOVING SQUARE
                    --------------------------------------------------------
                    when 28 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_SQUARE
                            );
                        else
                            char_code <= text_char(
                                "4  MOVING SQUARE",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- IMAGE
                    --------------------------------------------------------
                    when 31 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_IMAGE
                            );
                        else
                            char_code <= text_char(
                                "5  IMAGE",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- IMAGE + SPRITE
                    --------------------------------------------------------
                    when 34 =>
                        if cx = 28 then
                            char_code <= selection_arrow(
                                cx,
                                vga_selection = VGA_SPRITE
                            );
                        else
                            char_code <= text_char(
                                "6  IMAGE + SPRITE",
                                cx,
                                30
                            );
                        end if;


                    --------------------------------------------------------
                    -- Instructions
                    --------------------------------------------------------
                    when 39 =>
                        char_code <= text_char(
                            "UP/DOWN: SELECT ENTER: OPEN ESC: BACK",
                            cx,
                            28
                        );


                    when others =>
                        null;

                end case;

            end if;

        end if;
    end process;


    ----------------------------------------------------------------
    -- Font pixel
    ----------------------------------------------------------------
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


    ----------------------------------------------------------------
    -- RGB output
    ----------------------------------------------------------------
    r <= rgb_out;
    g <= rgb_out;
    b <= rgb_out;


    ----------------------------------------------------------------
    -- Menu state machine
    ----------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then

            menu_selection     <= APP_PONG;
            vga_selection      <= VGA_BORDER;
            active_application <= APP_PONG;

            menu_active_i      <= '1';
            vga_submenu_active <= '0';

        elsif rising_edge(clk) then

            ------------------------------------------------------------
            -- Main menu
            ------------------------------------------------------------
            if menu_active_i = '1' and vga_submenu_active = '0' then

                if menu_next = '1' then

                    if menu_selection = APP_LAST then
                        menu_selection <= APP_FIRST;
                    else
                        menu_selection <= menu_selection + 1;
                    end if;


                elsif menu_prev = '1' then

                    if menu_selection = APP_FIRST then
                        menu_selection <= APP_LAST;
                    else
                        menu_selection <= menu_selection - 1;
                    end if;


                elsif menu_enter = '1' then

                    active_application <= menu_selection;

                    if menu_selection = APP_VGA then

                        -- Open VGA submenu.
                        vga_submenu_active <= '1';

                    else

                        -- Open selected application.
                        menu_active_i      <= '0';
                        vga_submenu_active <= '0';

                    end if;


                elsif menu_back = '1' then

                    -- Already at the main menu.
                    menu_active_i      <= '1';
                    vga_submenu_active <= '0';

                end if;


            ------------------------------------------------------------
            -- VGA submenu
            ------------------------------------------------------------
            elsif vga_submenu_active = '1' then

                if menu_next = '1' then

                    if vga_selection = VGA_LAST then
                        vga_selection <= VGA_FIRST;
                    else
                        vga_selection <= vga_selection + 1;
                    end if;


                elsif menu_prev = '1' then

                    if vga_selection = VGA_FIRST then
                        vga_selection <= VGA_LAST;
                    else
                        vga_selection <= vga_selection - 1;
                    end if;


                elsif menu_enter = '1' then

                    -- Enter selected VGA pattern.
                    active_application <= APP_VGA;
                    menu_active_i      <= '0';
                    vga_submenu_active <= '0';


                elsif menu_back = '1' then

                    -- VGA submenu -> main menu.
                    menu_active_i      <= '1';
                    vga_submenu_active <= '0';

                end if;


            ------------------------------------------------------------
            -- Active application
            ------------------------------------------------------------
            else

                if menu_back = '1' then

                    menu_active_i <= '1';

                    if active_application = APP_VGA then

                        -- VGA pattern -> VGA submenu.
                        vga_submenu_active <= '1';

                    else

                        -- Other application -> main menu.
                        vga_submenu_active <= '0';

                    end if;

                end if;

            end if;

        end if;
    end process;


    ----------------------------------------------------------------
    -- Outputs
    ----------------------------------------------------------------
    application_sel <= std_logic_vector(
        to_unsigned(active_application, 3)
    );

    menu_active <= menu_active_i;

    vga_menu_active <= vga_submenu_active;

    vga_pattern_sel <= std_logic_vector(
        to_unsigned(vga_selection, 3)
    );

end rtl;