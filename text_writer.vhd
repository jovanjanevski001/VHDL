library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Text terminal engine: turns received UART bytes into writes to the text memory.
--
--   rx_data   : received UART byte
--   rx_toggle : toggles once per received byte
--
-- Every memory word is 16 bits:
--   bits 15..12 : background colour
--   bits 11..8  : foreground colour
--   bits 7..0   : character
--
-- Characters:
--   32..95      written as is
--   97..122     lower case converted to upper case
--   13          carriage return
--   8 / 127     backspace
--   10          line feed, ignored
--
-- Scrolling uses the text memory as a 60-row ring buffer.
--
-- ANSI parsing is handled by text_ansi.
-- FIFO buffering is handled by fifo.
-- Cursor movement is handled by text_cursor.
-- Ring-buffer scrolling is handled by text_scroll.

entity text_writer is
    generic
    (
        CLEAR_ON_RESET : boolean := true
    );
    port
    (
        clk       : in  std_logic;
        rst       : in  std_logic;
        rx_data   : in  std_logic_vector(7 downto 0);
        rx_toggle : in  std_logic;

        wr_en      : out std_logic;
        wr_address : out std_logic_vector(12 downto 0);
        wr_data    : out std_logic_vector(15 downto 0);

        cur_col : out std_logic_vector(6 downto 0);
        cur_row : out std_logic_vector(5 downto 0);
        top_row : out std_logic_vector(5 downto 0)
    );
end text_writer;

architecture BHV of text_writer is

    constant COLS  : positive := 80;
    constant ROWS  : positive := 60;
    constant CELLS : positive := COLS * ROWS;
    constant SPACE : std_logic_vector(7 downto 0) := x"20";

    signal toggle_in : std_logic_vector(0 downto 0);
    signal toggle_s  : std_logic_vector(0 downto 0);
    signal toggle_d  : std_logic := '0';
    signal new_byte  : std_logic;

    signal fifo_push  : std_logic;
    signal fifo_pop   : std_logic;
    signal fifo_empty : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_data  : std_logic_vector(7 downto 0);

    signal col : integer range 0 to COLS - 1 := 0;
    signal row : integer range 0 to ROWS - 1 := 0;
    signal top : integer range 0 to ROWS - 1 := 0;

    signal fg : unsigned(3 downto 0) := to_unsigned(7, 4);
    signal bg : unsigned(3 downto 0) := to_unsigned(0, 4);
	
	signal clearing : std_logic := '1';
	signal clr_addr : integer range 0 to CELLS - 1 := 0;
	signal clr_end  : integer range 0 to CELLS - 1 := CELLS - 1;

    signal cursor_advance : std_logic;
    signal cursor_cr      : std_logic;
    signal cursor_back    : std_logic;

    signal cursor_next_col : integer range 0 to COLS - 1;
    signal cursor_next_row : integer range 0 to ROWS - 1;
    signal cursor_scroll   : std_logic;

    signal phys_row : integer range 0 to ROWS - 1;

    signal scroll_next_top : integer range 0 to ROWS - 1;

    signal scroll_clear_start : integer range 0 to CELLS - 1;
    signal scroll_clear_end   : integer range 0 to CELLS - 1;

    signal ansi_char_valid : std_logic;
    signal ansi_char       : std_logic_vector(7 downto 0);

    signal ansi_sgr_valid   : std_logic;
    signal ansi_sgr_p1      : integer range 0 to 999;
    signal ansi_sgr_p2      : integer range 0 to 999;
    signal ansi_sgr_param   : integer range 0 to 999;
    signal ansi_sgr_have_p1 : std_logic;
    signal ansi_sgr_have_p2 : std_logic;

    signal ansi_clear_screen : std_logic;
    signal ansi_clear_line   : std_logic;

    signal ansi_cursor_pos     : std_logic;
    signal ansi_cursor_p1      : integer range 0 to 999;
    signal ansi_cursor_param  : integer range 0 to 999;
    signal ansi_cursor_have_p1 : std_logic;

begin

    ------------------------------------------------------------------------
    -- Cursor outputs.
    ------------------------------------------------------------------------

    cur_col <= std_logic_vector(to_unsigned(col, 7));
    cur_row <= std_logic_vector(to_unsigned(row, 6));
    top_row <= std_logic_vector(to_unsigned(top, 6));

    ------------------------------------------------------------------------
    -- Synchronize the UART receive toggle.
    ------------------------------------------------------------------------

    toggle_in(0) <= rx_toggle;

    U_SYNC : entity work.sync_2ff
        generic map
        (
            WIDTH => 1
        )
        port map
        (
            clk    => clk,
            input  => toggle_in,
            output => toggle_s
        );

    new_byte <= toggle_s(0) xor toggle_d;

    ------------------------------------------------------------------------
    -- FIFO control.
    ------------------------------------------------------------------------

    fifo_pop <= '1'
        when clearing = '0' and fifo_empty = '0'
        else '0';

    fifo_push <= '1'
        when new_byte = '1' and
             (fifo_full = '0' or fifo_pop = '1')
        else '0';

    U_FIFO : entity work.fifo
        generic map
        (
            WIDTH => 8,
            DEPTH => 16
        )
        port map
        (
            clk    => clk,
            rst    => rst,
            push   => fifo_push,
            pop    => fifo_pop,
            input  => rx_data,
            output => fifo_data,
            empty  => fifo_empty,
            full   => fifo_full
        );

    ------------------------------------------------------------------------
    -- ANSI parser.
    ------------------------------------------------------------------------

    U_ANSI : entity work.text_ansi
        port map
        (
            clk            => clk,
            rst            => rst,
            enable         => fifo_pop,
            input          => fifo_data,

            char_valid     => ansi_char_valid,
            char           => ansi_char,

            sgr_valid      => ansi_sgr_valid,
            sgr_p1         => ansi_sgr_p1,
            sgr_p2         => ansi_sgr_p2,
            sgr_param      => ansi_sgr_param,
            sgr_have_p1    => ansi_sgr_have_p1,
            sgr_have_p2    => ansi_sgr_have_p2,

            clear_screen   => ansi_clear_screen,
            clear_line     => ansi_clear_line,

            cursor_pos     => ansi_cursor_pos,
            cursor_p1      => ansi_cursor_p1,
            cursor_param   => ansi_cursor_param,
            cursor_have_p1 => ansi_cursor_have_p1
        );

    ------------------------------------------------------------------------
    -- Cursor control.
    ------------------------------------------------------------------------

    cursor_advance <= '1'
        when ansi_char_valid = '1' and
             ((to_integer(unsigned(ansi_char)) >= 32 and
               to_integer(unsigned(ansi_char)) <= 95) or
              (to_integer(unsigned(ansi_char)) >= 97 and
               to_integer(unsigned(ansi_char)) <= 122))
        else '0';

    cursor_cr <= '1'
        when ansi_char_valid = '1' and
             to_integer(unsigned(ansi_char)) = 13
        else '0';

    cursor_back <= '1'
        when ansi_char_valid = '1' and
             (to_integer(unsigned(ansi_char)) = 8 or
              to_integer(unsigned(ansi_char)) = 127)
        else '0';

    U_CURSOR : entity work.text_cursor
        generic map
        (
            COLS => COLS,
            ROWS => ROWS
        )
        port map
        (
            col      => col,
            row      => row,
            advance  => cursor_advance,
            cr       => cursor_cr,
            back     => cursor_back,
            next_col => cursor_next_col,
            next_row => cursor_next_row,
            scroll   => cursor_scroll
        );

    ------------------------------------------------------------------------
    -- Text-memory ring-buffer management.
    ------------------------------------------------------------------------

    U_SCROLL : entity work.text_scroll
        generic map
        (
            COLS => COLS,
            ROWS => ROWS
        )
        port map
        (
            row         => row,
            top         => top,
            scroll      => cursor_scroll,
            phys_row    => phys_row,
            next_top    => scroll_next_top,
            clear_start => scroll_clear_start,
            clear_end   => scroll_clear_end
        );

    ------------------------------------------------------------------------
    -- Terminal state and memory writer.
    ------------------------------------------------------------------------

    process(clk)

        variable b       : integer;
        variable v_col   : integer range 0 to COLS - 1;
        variable v_row   : integer range 0 to ROWS - 1;
        variable v_fg    : unsigned(3 downto 0);
        variable v_bg    : unsigned(3 downto 0);
        variable v_scrl  : boolean;
        variable ch      : std_logic_vector(7 downto 0);
        variable r       : integer;
        variable c       : integer;

        procedure sgr
        (
            p : in integer;
            f : inout unsigned(3 downto 0);
            g : inout unsigned(3 downto 0)
        ) is
        begin
            if p = 0 then
                f := to_unsigned(7, 4);
                g := to_unsigned(0, 4);

            elsif p = 1 then
                f(3) := '1';

            elsif p = 22 then
                f(3) := '0';

            elsif p >= 30 and p <= 37 then
                f := f(3) & to_unsigned(p - 30, 3);

            elsif p = 39 then
                f := to_unsigned(7, 4);

            elsif p >= 40 and p <= 47 then
                g := '0' & to_unsigned(p - 40, 3);

            elsif p = 49 then
                g := to_unsigned(0, 4);

            elsif p >= 90 and p <= 97 then
                f := '1' & to_unsigned(p - 90, 3);

            elsif p >= 100 and p <= 107 then
                g := '1' & to_unsigned(p - 100, 3);
            end if;
        end procedure;

    begin

        if rising_edge(clk) then

            toggle_d <= toggle_s(0);
            wr_en    <= '0';

            if rst = '1' then

                col <= 0;
                row <= 0;
                top <= 0;

                fg <= to_unsigned(7, 4);
                bg <= to_unsigned(0, 4);

                clr_addr <= 0;
                clr_end  <= CELLS - 1;

                if CLEAR_ON_RESET then
                    clearing <= '1';
                else
                    clearing <= '0';
                end if;

            else

                ----------------------------------------------------------------
                -- Screen clearing.
                ----------------------------------------------------------------

                if clearing = '1' then

                    wr_en      <= '1';
                    wr_address <= std_logic_vector(to_unsigned(clr_addr, 13));
                    wr_data    <= std_logic_vector(bg & fg) & SPACE;

                    if clr_addr = clr_end then
                        clearing <= '0';
                    else
                        clr_addr <= clr_addr + 1;
                    end if;

                elsif fifo_pop = '1' then

                    b := to_integer(unsigned(fifo_data));

                    v_col  := col;
                    v_row  := row;
                    v_fg   := fg;
                    v_bg   := bg;
                    v_scrl := false;

                    ----------------------------------------------------------------
                    -- Normal character/control handling.
                    ----------------------------------------------------------------

                    if ansi_char_valid = '1' then

                        b := to_integer(unsigned(ansi_char));

                        if b = 13 then

                            v_col := cursor_next_col;
                            v_row := cursor_next_row;

                            if cursor_scroll = '1' then
                                v_scrl := true;
                            end if;

                        elsif b = 8 or b = 127 then

                            v_col := cursor_next_col;
                            v_row := cursor_next_row;

                            if col /= 0 or row /= 0 then

                                wr_en <= '1';

                                wr_address <=
                                    std_logic_vector(
                                        to_unsigned(
                                            phys_row * COLS + v_col,
                                            13
                                        )
                                    );

                                wr_data <=
                                    std_logic_vector(bg & fg) & SPACE;

                            end if;

                        elsif (b >= 32 and b <= 95) or
                              (b >= 97 and b <= 122) then

                            if b >= 97 then
                                ch := std_logic_vector(
                                    to_unsigned(b - 32, 8)
                                );
                            else
                                ch := std_logic_vector(
                                    to_unsigned(b, 8)
                                );
                            end if;

                            wr_en <= '1';

                            wr_address <=
                                std_logic_vector(
                                    to_unsigned(
                                        phys_row * COLS + col,
                                        13
                                    )
                                );

                            wr_data <=
                                std_logic_vector(bg & fg) & ch;

                            v_col := cursor_next_col;
                            v_row := cursor_next_row;

                            if cursor_scroll = '1' then
                                v_scrl := true;
                            end if;

                        end if;

                    ----------------------------------------------------------------
                    -- ANSI Select Graphic Rendition.
                    ----------------------------------------------------------------

                    elsif ansi_sgr_valid = '1' then

                        if ansi_sgr_have_p1 = '1' then
                            sgr(ansi_sgr_p1, v_fg, v_bg);
                        end if;

                        if ansi_sgr_have_p2 = '1' then
                            sgr(ansi_sgr_p2, v_fg, v_bg);
                        end if;

                        sgr(ansi_sgr_param, v_fg, v_bg);

                    ----------------------------------------------------------------
                    -- ANSI clear screen.
                    ----------------------------------------------------------------

                    elsif ansi_clear_screen = '1' then

                        clearing <= '1';
                        clr_addr <= 0;
                        clr_end  <= CELLS - 1;

                    ----------------------------------------------------------------
                    -- ANSI clear line.
                    ----------------------------------------------------------------

                    elsif ansi_clear_line = '1' then

                        clearing <= '1';
                        clr_addr <= phys_row * COLS + col;
                        clr_end  <= phys_row * COLS + COLS - 1;

                    ----------------------------------------------------------------
                    -- ANSI cursor positioning.
                    ----------------------------------------------------------------

                    elsif ansi_cursor_pos = '1' then

                        if ansi_cursor_have_p1 = '1' then
                            r := ansi_cursor_p1;
                            c := ansi_cursor_param;
                        else
                            r := ansi_cursor_param;
                            c := 1;
                        end if;

                        if r < 1 then
                            r := 1;
                        end if;

                        if r > ROWS then
                            r := ROWS;
                        end if;

                        if c < 1 then
                            c := 1;
                        end if;

                        if c > COLS then
                            c := COLS;
                        end if;

                        v_row := r - 1;
                        v_col := c - 1;

                    end if;

                    col <= v_col;
                    row <= v_row;

                    fg <= v_fg;
                    bg <= v_bg;

                    ----------------------------------------------------------------
                    -- Cursor reached the bottom of the screen.
                    ----------------------------------------------------------------

                    if v_scrl then

                        top <= scroll_next_top;

                        clearing <= '1';

                        clr_addr <= scroll_clear_start;
                        clr_end  <= scroll_clear_end;

                    end if;

                end if;

            end if;

        end if;

    end process;

end BHV;