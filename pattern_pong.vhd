library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;


entity pattern_pong is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        x : in coor_width_t;
        y : in coor_width_t;

        ball_x : in coor_width_t;
        ball_y : in coor_width_t;

        player_y   : in coor_width_t;
        computer_y : in coor_width_t;

        player_score   : in std_logic_vector(3 downto 0);
        computer_score : in std_logic_vector(3 downto 0);

        game_over : in std_logic;
        winner    : in std_logic;

        r : out color_width_t;
        g : out color_width_t;
        b : out color_width_t
    );
end pattern_pong;


architecture BHV of pattern_pong is

    -- ============================================================
    -- Pong geometry
    -- ============================================================

    constant PADDLE_WIDTH  : integer := 12;
    constant PADDLE_HEIGHT : integer := 72;
    constant BALL_SIZE     : integer := 8;

    constant PLAYER_X : integer := 32;

    constant COMPUTER_X : integer :=
        H_VISIBLE - 32 - PADDLE_WIDTH;

    constant BORDER_WIDTH : integer := 4;
    constant CENTER_X     : integer := H_VISIBLE / 2;

    constant DASH_LENGTH : integer := 16;
    constant GAP_LENGTH  : integer := 16;


    -- ============================================================
    -- Score text positions
    -- ============================================================

    constant SCORE_ROW : integer := 1;

    constant PLAYER_COL       : integer := 26;
    constant PLAYER_SCORE_COL : integer := 34;
    constant COLON_COL        : integer := 39;

    constant COMPUTER_SCORE_COL : integer := 44;
    constant COMPUTER_COL       : integer := 46;


    -- ============================================================
    -- Winner message positions
    --
    -- PLAYER WINS   = 11 characters
    -- COMPUTER WINS = 13 characters
    -- ============================================================

    constant PLAYER_WIN_COL   : integer := 35;
    constant COMPUTER_WIN_COL : integer := 33;
    constant WINNER_ROW       : integer := 31;


    -- ============================================================
    -- Character arrays
    -- ============================================================

    type char_array_t is array (natural range <>) of
        std_logic_vector(7 downto 0);

    signal pong_chars   : char_array_t(0 to 16);
    signal winner_chars : char_array_t(0 to 12);


    -- ============================================================
    -- Character / font addressing
    -- ============================================================

    signal char_code    : std_logic_vector(7 downto 0);
    signal font_address : std_logic_vector(6 downto 0);
    signal font_data    : std_logic_vector(63 downto 0);


    -- ============================================================
    -- Glyph coordinates
    --
    -- Font ROM has one clock of latency.
    -- ============================================================

    signal glyph_x_d : unsigned(2 downto 0);
    signal glyph_y_d : unsigned(2 downto 0);

    signal glyph_bit : std_logic;


    -- ============================================================
    -- Character conversion helper
    -- ============================================================

    function ascii(c : character) return std_logic_vector is
    begin
        return std_logic_vector(
            to_unsigned(character'pos(c), 8)
        );
    end function;


begin

    -- ============================================================
    -- Score text
    --
    -- 0..5  = PLAYER
    -- 6     = player score
    -- 7     = :
    -- 8     = computer score
    -- 9..16 = COMPUTER
    -- ============================================================

    pong_chars(0) <= ascii('P');
    pong_chars(1) <= ascii('L');
    pong_chars(2) <= ascii('A');
    pong_chars(3) <= ascii('Y');
    pong_chars(4) <= ascii('E');
    pong_chars(5) <= ascii('R');

    pong_chars(6) <= std_logic_vector(
        to_unsigned(
            character'pos('0') +
            to_integer(unsigned(player_score)),
            8
        )
    );

    pong_chars(7) <= ascii(':');

    pong_chars(8) <= std_logic_vector(
        to_unsigned(
            character'pos('0') +
            to_integer(unsigned(computer_score)),
            8
        )
    );

    pong_chars(9)  <= ascii('C');
    pong_chars(10) <= ascii('O');
    pong_chars(11) <= ascii('M');
    pong_chars(12) <= ascii('P');
    pong_chars(13) <= ascii('U');
    pong_chars(14) <= ascii('T');
    pong_chars(15) <= ascii('E');
    pong_chars(16) <= ascii('R');


    -- ============================================================
    -- Winner message
    --
    -- Stored message:
    --     COMPUTER WINS
    --
    -- PLAYER WINS is generated directly when required.
    -- ============================================================

    winner_chars(0)  <= ascii('C');
    winner_chars(1)  <= ascii('O');
    winner_chars(2)  <= ascii('M');
    winner_chars(3)  <= ascii('P');
    winner_chars(4)  <= ascii('U');
    winner_chars(5)  <= ascii('T');
    winner_chars(6)  <= ascii('E');
    winner_chars(7)  <= ascii('R');
    winner_chars(8)  <= ascii(' ');
    winner_chars(9)  <= ascii('W');
    winner_chars(10) <= ascii('I');
    winner_chars(11) <= ascii('N');
    winner_chars(12) <= ascii('S');


    -- ============================================================
    -- Character selection
    --
    -- Character selection is combinational.
    -- The font ROM supplies the glyph one clock later.
    -- ============================================================

    process(
        x,
        y,
        game_over,
        winner,
        player_score,
        computer_score
    )

        variable cell_x : integer;
        variable cell_y : integer;
        variable index  : integer;

    begin

        cell_x := to_integer(unsigned(x)) / 8;
        cell_y := to_integer(unsigned(y)) / 8;

        -- Default character = space.
        char_code <= ascii(' ');


        -- ========================================================
        -- GAME OVER
        -- ========================================================

        if game_over = '1' then

            -- ----------------------------------------------------
            -- PLAYER WINS
            -- ----------------------------------------------------

            if winner = '0' then

                if
                (
                    cell_y = WINNER_ROW and
                    cell_x >= PLAYER_WIN_COL and
                    cell_x < PLAYER_WIN_COL + 11
                )
                then

                    index := cell_x - PLAYER_WIN_COL;

                    case index is
                        when 0  => char_code <= ascii('P');
                        when 1  => char_code <= ascii('L');
                        when 2  => char_code <= ascii('A');
                        when 3  => char_code <= ascii('Y');
                        when 4  => char_code <= ascii('E');
                        when 5  => char_code <= ascii('R');
                        when 6  => char_code <= ascii(' ');
                        when 7  => char_code <= ascii('W');
                        when 8  => char_code <= ascii('I');
                        when 9  => char_code <= ascii('N');
                        when 10 => char_code <= ascii('S');
                        when others => char_code <= ascii(' ');
                    end case;

                end if;


            -- ----------------------------------------------------
            -- COMPUTER WINS
            -- ----------------------------------------------------

            else

                if
                (
                    cell_y = WINNER_ROW and
                    cell_x >= COMPUTER_WIN_COL and
                    cell_x < COMPUTER_WIN_COL + 13
                )
                then

                    index := cell_x - COMPUTER_WIN_COL;

                    if index >= 0 and index <= 12 then
                        char_code <= winner_chars(index);
                    end if;

                end if;

            end if;


        -- ========================================================
        -- NORMAL SCORE DISPLAY
        -- ========================================================

        else

            if cell_y = SCORE_ROW then

                -- ------------------------------------------------
                -- PLAYER
                -- ------------------------------------------------

                if
                (
                    cell_x >= PLAYER_COL and
                    cell_x < PLAYER_COL + 6
                )
                then

                    index := cell_x - PLAYER_COL;
                    char_code <= pong_chars(index);


                -- ------------------------------------------------
                -- Player score
                -- ------------------------------------------------

                elsif cell_x = PLAYER_SCORE_COL then

                    char_code <= pong_chars(6);


                -- ------------------------------------------------
                -- Colon
                -- ------------------------------------------------

                elsif cell_x = COLON_COL then

                    char_code <= pong_chars(7);


                -- ------------------------------------------------
                -- Computer score
                -- ------------------------------------------------

                elsif cell_x = COMPUTER_SCORE_COL then

                    char_code <= pong_chars(8);


                -- ------------------------------------------------
                -- COMPUTER
                -- ------------------------------------------------

                elsif
                (
                    cell_x >= COMPUTER_COL and
                    cell_x < COMPUTER_COL + 8
                )
                then

                    index := cell_x - COMPUTER_COL;
                    char_code <= pong_chars(9 + index);

                end if;

            end if;

        end if;

    end process;


    -- ============================================================
    -- Font ROM address
    -- ============================================================

    font_address <= std_logic_vector(
        unsigned(char_code(6 downto 0)) - 32
    );


    -- ============================================================
    -- Font ROM
    -- ============================================================

    U_FONT_ROM : entity work.font_rom
        port map
        (
            clock   => clk,
            address => font_address,
            q       => font_data
        );


    -- ============================================================
    -- Glyph coordinate delay
    --
    -- Match the one-cycle font ROM latency.
    -- ============================================================

    process(clk, rst)
    begin

        if rst = '1' then

            glyph_x_d <= (others => '0');
            glyph_y_d <= (others => '0');

        elsif rising_edge(clk) then

            glyph_x_d <= unsigned(x(2 downto 0));
            glyph_y_d <= unsigned(y(2 downto 0));

        end if;

    end process;


    -- ============================================================
    -- Font pixel
    -- ============================================================

    process(font_data, glyph_x_d, glyph_y_d)

        variable bit_index : integer;

    begin

        bit_index :=
            63 -
            (to_integer(glyph_y_d) * 8) -
            to_integer(glyph_x_d);

        glyph_bit <= font_data(bit_index);

    end process;


    -- ============================================================
    -- Pong graphics
    --
    -- Priority:
    --
    -- 1. Text
    -- 2. Ball
    -- 3. Player paddle
    -- 4. Computer paddle
    -- 5. Center dashed line
    -- 6. Border
    -- 7. Background
    -- ============================================================

    process(
        x,
        y,
        ball_x,
        ball_y,
        player_y,
        computer_y,
        glyph_bit
    )

        variable px : integer;
        variable py : integer;

        variable bx_i : integer;
        variable by_i : integer;

        variable player_y_i   : integer;
        variable computer_y_i : integer;

        variable center_y : integer;

    begin

        px := to_integer(unsigned(x));
        py := to_integer(unsigned(y));

        bx_i := to_integer(unsigned(ball_x));
        by_i := to_integer(unsigned(ball_y));

        player_y_i :=
            to_integer(unsigned(player_y));

        computer_y_i :=
            to_integer(unsigned(computer_y));


        -- ========================================================
        -- Text
        -- ========================================================

        if glyph_bit = '1' then

            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '1');


        -- ========================================================
        -- Ball
        -- ========================================================

        elsif
        (
            px >= bx_i and
            px < bx_i + BALL_SIZE and
            py >= by_i and
            py < by_i + BALL_SIZE
        )
        then

            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '1');


        -- ========================================================
        -- Player paddle
        -- ========================================================

        elsif
        (
            px >= PLAYER_X and
            px < PLAYER_X + PADDLE_WIDTH and
            py >= player_y_i and
            py < player_y_i + PADDLE_HEIGHT
        )
        then

            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '1');


        -- ========================================================
        -- Computer paddle
        -- ========================================================

        elsif
        (
            px >= COMPUTER_X and
            px < COMPUTER_X + PADDLE_WIDTH and
            py >= computer_y_i and
            py < computer_y_i + PADDLE_HEIGHT
        )
        then

            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '1');


        -- ========================================================
        -- Center dashed line
        -- ========================================================

        elsif
        (
            px >= CENTER_X - 2 and
            px < CENTER_X + 2
        )
        then

            center_y :=
                py mod (DASH_LENGTH + GAP_LENGTH);

            if center_y < DASH_LENGTH then

                r <= (others => '1');
                g <= (others => '1');
                b <= (others => '1');

            else

                r <= (others => '0');
                g <= (others => '0');
                b <= (others => '0');

            end if;


        -- ========================================================
        -- Border
        -- ========================================================

        elsif
        (
            px < BORDER_WIDTH or
            px >= H_VISIBLE - BORDER_WIDTH or
            py < BORDER_WIDTH or
            py >= V_VISIBLE - BORDER_WIDTH
        )
        then

            r <= (others => '1');
            g <= (others => '1');
            b <= (others => '1');


        -- ========================================================
        -- Background
        -- ========================================================

        else

            r <= (others => '0');
            g <= (others => '0');
            b <= (others => '0');

        end if;

    end process;

end BHV;