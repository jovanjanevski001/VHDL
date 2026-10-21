library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;


entity pattern_engine is
    port
    (
        clk        : in  std_logic;
        rst        : in  std_logic;

        x          : in  coor_width_t;
        y          : in  coor_width_t;

        square_x   : in  coor_width_t;
        square_y   : in  coor_width_t;

        sprite_x   : in  coor_width_t;
        sprite_y   : in  coor_width_t;

        frame_tick : in  std_logic;

        rx_data    : in  std_logic_vector(7 downto 0);
        rx_toggle  : in  std_logic;
        blink      : in  std_logic;

        live_bcd   : in  std_logic_vector(4*LIVE_DIGITS-1 downto 0);

        pix        : out pixel_array_t
    );
end pattern_engine;


architecture rtl of pattern_engine is

    ------------------------------------------------------------------------
    -- General pattern constants
    ------------------------------------------------------------------------

    constant BAR_W         : natural := H_VISIBLE / 8;
    constant CHECKER_LOG2  : natural := 5;
    constant THIRD         : natural := V_VISIBLE / 3;

    constant PIXEL_LATENCY : natural := 2;
    constant LIVE_LEN      : natural := LIVE_LABEL'length + LIVE_DIGITS;


    ------------------------------------------------------------------------
    -- Image constants
    ------------------------------------------------------------------------

    constant IMAGE_SCALE_LOG2 : natural := 2;
    constant IMG_W            : natural := 160;
    constant IMG_H            : natural := 120;
    constant IMG_ADDR_W       : natural := 15;


    ------------------------------------------------------------------------
    -- Image signals
    ------------------------------------------------------------------------

    signal image_addr  : integer range 0 to IMG_W * IMG_H - 1;
    signal image_data  : std_logic_vector(11 downto 0);
    signal image_pixel : std_logic_vector(11 downto 0);


    ------------------------------------------------------------------------
    -- Sprite signals
    ------------------------------------------------------------------------

    signal sprite_r     : color_width_t;
    signal sprite_g     : color_width_t;
    signal sprite_b     : color_width_t;

    signal sprite_color : std_logic_vector(11 downto 0);
    signal sprite_pixel : std_logic_vector(11 downto 0);
    signal sprite_mixed : std_logic_vector(11 downto 0);


    ------------------------------------------------------------------------
    -- Text position
    ------------------------------------------------------------------------

    signal char_x  : unsigned(6 downto 0);
    signal char_y  : unsigned(5 downto 0);

    signal glyph_x : unsigned(2 downto 0);
    signal glyph_y : unsigned(2 downto 0);


    ------------------------------------------------------------------------
    -- Text scrolling
    ------------------------------------------------------------------------

    signal top_v : unsigned(5 downto 0);


    ------------------------------------------------------------------------
    -- Text memory
    ------------------------------------------------------------------------

    signal screen_address : std_logic_vector(12 downto 0);
    signal screen_data    : std_logic_vector(15 downto 0);

    signal wr_en          : std_logic;
    signal wr_address     : std_logic_vector(12 downto 0);
    signal wr_data        : std_logic_vector(15 downto 0);


    ------------------------------------------------------------------------
    -- Text writer state
    ------------------------------------------------------------------------

    signal cur_col : std_logic_vector(6 downto 0);
    signal cur_row : std_logic_vector(5 downto 0);

    signal top_row : std_logic_vector(5 downto 0);


    ------------------------------------------------------------------------
    -- Text / font
    ------------------------------------------------------------------------

    signal ascii_code   : std_logic_vector(7 downto 0);
    signal attr         : std_logic_vector(7 downto 0);

    signal font_address : std_logic_vector(6 downto 0);
    signal font_data    : std_logic_vector(63 downto 0);


    ------------------------------------------------------------------------
    -- Text pipeline
    ------------------------------------------------------------------------

    signal attr_d : std_logic_vector(7 downto 0);

    signal pos    : std_logic_vector(18 downto 0);
    signal pos_d1 : std_logic_vector(18 downto 0);
    signal pos_d  : std_logic_vector(18 downto 0);

    signal char_x_d  : unsigned(6 downto 0);
    signal char_y_d  : unsigned(5 downto 0);
    signal glyph_x_d : unsigned(2 downto 0);
    signal glyph_y_d : unsigned(2 downto 0);


    ------------------------------------------------------------------------
    -- Cursor
    ------------------------------------------------------------------------

    signal cursor_here : std_logic;


    ------------------------------------------------------------------------
    -- Live overlay
    ------------------------------------------------------------------------

    signal live_here : std_logic;
    signal live_char : std_logic_vector(7 downto 0);

    signal live_chars :
        std_logic_vector((LIVE_LEN * 8) - 1 downto 0);


    ------------------------------------------------------------------------
    -- Text RGB
    ------------------------------------------------------------------------

    signal text_rgb : std_logic_vector(11 downto 0);


    ------------------------------------------------------------------------
    -- Palette
    ------------------------------------------------------------------------

    function palette(
        idx : std_logic_vector(3 downto 0)
    ) return std_logic_vector is
    begin
        case idx is
            when "0000" =>
                return x"000";

            when "0001" =>
                return x"A00";

            when "0010" =>
                return x"0A0";

            when "0011" =>
                return x"A50";

            when "0100" =>
                return x"00A";

            when "0101" =>
                return x"A0A";

            when "0110" =>
                return x"0AA";

            when "0111" =>
                return x"AAA";

            when "1000" =>
                return x"555";

            when "1001" =>
                return x"F55";

            when "1010" =>
                return x"5F5";

            when "1011" =>
                return x"FF5";

            when "1100" =>
                return x"55F";

            when "1101" =>
                return x"F5F";

            when "1110" =>
                return x"5FF";

            when others =>
                return x"FFF";
        end case;
    end function;


    ------------------------------------------------------------------------
    -- Convert a BCD nibble into an ASCII digit
    ------------------------------------------------------------------------

    function digit_char(
        nib : std_logic_vector(3 downto 0)
    ) return std_logic_vector is
    begin
        if unsigned(nib) <= 9 then
            return std_logic_vector(
                to_unsigned(
                    48 + to_integer(unsigned(nib)),
                    8
                )
            );
        else
            return x"3F";
        end if;
    end function;


    ------------------------------------------------------------------------
    -- Border
    --
    -- 4-pixel border:
    --   top    = red
    --   bottom = blue
    --   left   = green
    --   right  = white
    --
    -- Priority is top, bottom, left, right.
    ------------------------------------------------------------------------

    function border_pixel(
        px : coor_width_t;
        py : coor_width_t
    ) return std_logic_vector is

        variable xi : integer;
        variable yi : integer;

    begin
        xi := to_integer(unsigned(px));
        yi := to_integer(unsigned(py));

        if yi < BORDER then
            return x"F00";

        elsif yi >= V_VISIBLE - BORDER then
            return x"00F";

        elsif xi < BORDER then
            return x"0F0";

        elsif xi >= H_VISIBLE - BORDER then
            return x"FFF";

        else
            return x"000";
        end if;
    end function;


    ------------------------------------------------------------------------
    -- Color bars
    ------------------------------------------------------------------------

    function bars_pixel(
        px : coor_width_t
    ) return std_logic_vector is

        variable column : natural;

    begin
        column := to_integer(unsigned(px)) / BAR_W;

        case column is
            when 0 =>
                return x"FFF";

            when 1 =>
                return x"FF0";

            when 2 =>
                return x"0FF";

            when 3 =>
                return x"0F0";

            when 4 =>
                return x"F0F";

            when 5 =>
                return x"F00";

            when 6 =>
                return x"00F";

            when others =>
                return x"000";
        end case;
    end function;


    ------------------------------------------------------------------------
    -- Checkerboard
    ------------------------------------------------------------------------

    function checker_pixel(
        px : coor_width_t;
        py : coor_width_t
    ) return std_logic_vector is

        variable c : std_logic;

    begin
        c := px(CHECKER_LOG2) xor py(CHECKER_LOG2);

        if c = '1' then
            return x"FFF";
        else
            return x"000";
        end if;
    end function;


    ------------------------------------------------------------------------
    -- Gradient
    ------------------------------------------------------------------------

    function gradient_pixel(
        px : coor_width_t;
        py : coor_width_t
    ) return std_logic_vector is

        variable prod  : unsigned(15 downto 0);
        variable level : std_logic_vector(3 downto 0);
        variable rgb   : std_logic_vector(11 downto 0);

    begin
        prod := unsigned(px) * to_unsigned(51, 6);

        level := std_logic_vector(prod(14 downto 11));

        rgb := (others => '0');

        if unsigned(py) < THIRD then
            rgb(11 downto 8) := level;

        elsif unsigned(py) < 2 * THIRD then
            rgb(7 downto 4) := level;

        else
            rgb(3 downto 0) := level;
        end if;

        return rgb;
    end function;


    ------------------------------------------------------------------------
    -- Moving square
    --
    -- SQUARE_SIZE comes from vga_pkg.
    ------------------------------------------------------------------------

    function square_pixel(
        px    : coor_width_t;
        py    : coor_width_t;
        pos_x : coor_width_t;
        pos_y : coor_width_t
    ) return std_logic_vector is
    begin
        if
            unsigned(px) >= unsigned(pos_x) and
            unsigned(px) < unsigned(pos_x) + SQUARE_SIZE and
            unsigned(py) >= unsigned(pos_y) and
            unsigned(py) < unsigned(pos_y) + SQUARE_SIZE
        then
            return x"FFF";
        else
            return x"000";
        end if;
    end function;


begin

    ------------------------------------------------------------------------
    -- Pattern 0 : Border
    ------------------------------------------------------------------------

    pix(0) <= border_pixel(x, y);


    ------------------------------------------------------------------------
    -- Pattern 1 : Color bars
    ------------------------------------------------------------------------

    pix(1) <= bars_pixel(x);


    ------------------------------------------------------------------------
    -- Pattern 2 : Checkerboard
    ------------------------------------------------------------------------

    pix(2) <= checker_pixel(x, y);


    ------------------------------------------------------------------------
    -- Pattern 3 : Gradient
    ------------------------------------------------------------------------

    pix(3) <= gradient_pixel(x, y);


    ------------------------------------------------------------------------
    -- Pattern 4 : Moving square
    ------------------------------------------------------------------------

    pix(4) <= square_pixel(x, y, square_x, square_y);


    ------------------------------------------------------------------------
    -- Pattern 5 : Image
    ------------------------------------------------------------------------

    process(x, y)
        variable xi : integer;
        variable yi : integer;
    begin
        xi := to_integer(
            unsigned(
                x(COOR_WIDTH - 1 downto IMAGE_SCALE_LOG2)
            )
        );

        yi := to_integer(
            unsigned(
                y(COOR_WIDTH - 1 downto IMAGE_SCALE_LOG2)
            )
        );

        if (xi < IMG_W and yi < IMG_H) then
            image_addr <= yi * IMG_W + xi;
        else
            image_addr <= 0;
        end if;
    end process;


    U_IMAGE_ROM : entity work.image_rom
        port map
        (
            clock   => clk,
            address => std_logic_vector(
                to_unsigned(image_addr, IMG_ADDR_W)
            ),
            q       => image_data
        );


    U_IMAGE_DLY : entity work.delay_line
        generic map
        (
            WIDTH  => 12,
            STAGES => PIXEL_LATENCY - 1
        )
        port map
        (
            clk    => clk,
            input  => image_data,
            output => image_pixel
        );


    pix(5) <= image_pixel;


    ------------------------------------------------------------------------
    -- Pattern 6 : Text
    --
    -- Complete text rendering pipeline.
    --
    -- Text memory : 1 clock
    -- Font ROM    : 1 clock
    -- Total       : 2 clocks
    ------------------------------------------------------------------------


    ------------------------------------------------------------------------
    -- Character / glyph coordinates
    ------------------------------------------------------------------------

    char_x <= unsigned(x(9 downto 3));
    char_y <= unsigned(y(8 downto 3));

    glyph_x <= unsigned(x(2 downto 0));
    glyph_y <= unsigned(y(2 downto 0));


    ------------------------------------------------------------------------
    -- Scrolling screen address
    ------------------------------------------------------------------------

    process(char_y, char_x, top_v)
        variable mem_row : integer;
    begin
        mem_row :=
            to_integer(char_y) +
            to_integer(top_v);

        if mem_row >= 60 then
            mem_row := mem_row - 60;
        end if;

        screen_address <= std_logic_vector(
            to_unsigned(
                mem_row * 80 + to_integer(char_x),
                13
            )
        );
    end process;


    ------------------------------------------------------------------------
    -- Latch scroll position once per frame
    ------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                top_v <= (others => '0');

            elsif frame_tick = '1' then
                top_v <= unsigned(top_row);
            end if;
        end if;
    end process;


    ------------------------------------------------------------------------
    -- UART text writer
    ------------------------------------------------------------------------

    U_WRITER : entity work.text_writer
        port map
        (
            clk        => clk,
            rst        => rst,

            rx_data    => rx_data,
            rx_toggle  => rx_toggle,

            wr_en      => wr_en,
            wr_address => wr_address,
            wr_data    => wr_data,

            cur_col    => cur_col,
            cur_row    => cur_row,
            top_row    => top_row
        );


    ------------------------------------------------------------------------
    -- Text memory
    ------------------------------------------------------------------------

    U_TEXT_RAM : entity work.text_memory
        port map
        (
            clock      => clk,

            wr_en      => wr_en,
            wr_address => wr_address,
            wr_data    => wr_data,

            address    => screen_address,
            q          => screen_data
        );


    ------------------------------------------------------------------------
    -- Live overlay
    ------------------------------------------------------------------------

    ascii_code <=
        live_char
        when live_here = '1'
        else screen_data(7 downto 0);


    attr <=
        LIVE_ATTR
        when live_here = '1'
        else screen_data(15 downto 8);


    font_address <= std_logic_vector(
        unsigned(ascii_code(6 downto 0)) - 32
    );


    ------------------------------------------------------------------------
    -- Font ROM
    ------------------------------------------------------------------------

    U_FONT_ROM : entity work.font_rom
        port map
        (
            clock  => clk,
            address => font_address,
            q      => font_data
        );


    ------------------------------------------------------------------------
    -- Attribute delay
    --
    -- Text memory produces screen_data one clock after the address.
    -- Font ROM adds another clock.
    ------------------------------------------------------------------------

    U_ATTR_DLY : entity work.delay_line
        generic map
        (
            WIDTH  => 8,
            STAGES => 1
        )
        port map
        (
            clk    => clk,
            input  => attr,
            output => attr_d
        );


    ------------------------------------------------------------------------
    -- Position pipeline
    --
    -- Match the two-clock RAM + font latency.
    ------------------------------------------------------------------------

    pos <=
        std_logic_vector(char_y) &
        std_logic_vector(char_x) &
        std_logic_vector(glyph_y) &
        std_logic_vector(glyph_x);


    U_POS_DLY1 : entity work.delay_line
        generic map
        (
            WIDTH  => 19,
            STAGES => 1
        )
        port map
        (
            clk    => clk,
            input  => pos,
            output => pos_d1
        );


    U_POS_DLY2 : entity work.delay_line
        generic map
        (
            WIDTH  => 19,
            STAGES => 1
        )
        port map
        (
            clk    => clk,
            input  => pos_d1,
            output => pos_d
        );


    ------------------------------------------------------------------------
    -- Live overlay character generation
    ------------------------------------------------------------------------

    G_LABEL : for k in 0 to LIVE_LABEL'length - 1 generate

        live_chars(8*k + 7 downto 8*k) <=
            std_logic_vector(
                to_unsigned(
                    character'pos(
                        LIVE_LABEL(LIVE_LABEL'low + k)
                    ),
                    8
                )
            );

    end generate;


    G_DIGITS : for d in 0 to LIVE_DIGITS - 1 generate

        live_chars(
            8*(LIVE_LABEL'length + d) + 7 downto
            8*(LIVE_LABEL'length + d)
        ) <=
            digit_char(
                live_bcd(
                    4*(LIVE_DIGITS - 1 - d) + 3 downto
                    4*(LIVE_DIGITS - 1 - d)
                )
            );

    end generate;


    ------------------------------------------------------------------------
    -- Live overlay position detection
    ------------------------------------------------------------------------

    process(pos_d1, live_chars)
        variable cx  : integer;
        variable cy  : integer;
        variable idx : integer;
    begin
        cx := to_integer(unsigned(pos_d1(12 downto 6)));
        cy := to_integer(unsigned(pos_d1(18 downto 13)));

        live_here <= '0';
        live_char <= x"20";

        if
            cy = LIVE_ROW and
            cx >= LIVE_COL and
            cx < LIVE_COL + LIVE_LEN
        then
            idx := cx - LIVE_COL;

            live_here <= '1';

            live_char <=
                live_chars(
                    8*idx + 7 downto
                    8*idx
                );
        end if;
    end process;


    ------------------------------------------------------------------------
    -- Delayed coordinates
    ------------------------------------------------------------------------

    char_y_d <= unsigned(pos_d(18 downto 13));
    char_x_d <= unsigned(pos_d(12 downto 6));

    glyph_y_d <= unsigned(pos_d(5 downto 3));
    glyph_x_d <= unsigned(pos_d(2 downto 0));


    ------------------------------------------------------------------------
    -- Cursor
    ------------------------------------------------------------------------

    cursor_here <=
        '1'
        when
            blink = '1' and
            std_logic_vector(char_x_d) = cur_col and
            std_logic_vector(char_y_d) = cur_row
        else
            '0';


    ------------------------------------------------------------------------
    -- Final text pixel
    ------------------------------------------------------------------------

    process(
        font_data,
        glyph_x_d,
        glyph_y_d,
        attr_d,
        cursor_here
    )
        variable bit_index : integer;
        variable use_fg    : boolean;
    begin
        bit_index :=
            63 -
            (to_integer(glyph_y_d) * 8) -
            to_integer(glyph_x_d);

        use_fg :=
            (font_data(bit_index) = '1') /=
            (cursor_here = '1');

        if use_fg then
            text_rgb <= palette(attr_d(3 downto 0));
        else
            text_rgb <= palette(attr_d(7 downto 4));
        end if;
    end process;


    pix(6) <= text_rgb;


    ------------------------------------------------------------------------
    -- Pattern 7 : Sprite over image
    ------------------------------------------------------------------------

    U_SPRITE_PIXEL : entity work.sprite_pixel
        port map
        (
            clk   => clk,
            x     => x,
            y     => y,
            pos_x => sprite_x,
            pos_y => sprite_y,

            r     => sprite_r,
            g     => sprite_g,
            b     => sprite_b
        );


    sprite_color <= sprite_r & sprite_g & sprite_b;


    U_SPRITE_DLY : entity work.delay_line
        generic map
        (
            WIDTH  => 12,
            STAGES => PIXEL_LATENCY - 1
        )
        port map
        (
            clk    => clk,
            input  => sprite_color,
            output => sprite_pixel
        );


    U_COMPOSE : entity work.compositor
        port map
        (
            front => sprite_pixel,
            back  => image_pixel,
            pix   => sprite_mixed
        );


    pix(7) <= sprite_mixed;


end rtl;