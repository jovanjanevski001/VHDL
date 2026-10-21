library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;


entity vga_patterns is
    port
    (
        clk        : in  std_logic;
        rst        : in  std_logic;

        x          : in  coor_width_t;
        y          : in  coor_width_t;

        frame_tick : in  std_logic;

        rx_data    : in  std_logic_vector(7 downto 0);
        rx_toggle  : in  std_logic;

        tilt_data   : in  std_logic_vector(31 downto 0);
        tilt_toggle : in  std_logic;

        r : out color_width_t;
        g : out color_width_t;
        b : out color_width_t
    );
end vga_patterns;


architecture STR of vga_patterns is

    ------------------------------------------------------------------------
    -- Pattern engine
    ------------------------------------------------------------------------

    signal engine_pix : pixel_array_t;


    ------------------------------------------------------------------------
    -- Aligned pattern pixels
    --
    -- Patterns 0..4 are combinational in pattern_engine and therefore need
    -- two cycles of delay to match the internal image/text/sprite paths.
    ------------------------------------------------------------------------

    signal pix : pixel_array_t;


    ------------------------------------------------------------------------
    -- System info
    ------------------------------------------------------------------------

    signal r8 : color_width_t;
    signal g8 : color_width_t;
    signal b8 : color_width_t;


    ------------------------------------------------------------------------
    -- Menu
    ------------------------------------------------------------------------

    signal r_menu : color_width_t;
    signal g_menu : color_width_t;
    signal b_menu : color_width_t;

    signal vga_pattern_sel : pattern_sel_t;
    signal vga_menu_active : std_logic;
    signal menu_active     : std_logic;

    signal menu_application_sel : std_logic_vector(2 downto 0);


    ------------------------------------------------------------------------
    -- UART menu control
    --
    -- UP    = PREVIOUS
    -- DOWN  = NEXT
    -- RIGHT = ENTER
    -- ENTER = ENTER
    -- LEFT  = BACK
    -- ESC   = BACK
    ------------------------------------------------------------------------

    signal menu_next  : std_logic;
    signal menu_prev  : std_logic;
    signal menu_enter : std_logic;
    signal menu_back  : std_logic;


    ------------------------------------------------------------------------
    -- Application selection
    ------------------------------------------------------------------------

    signal app_pong   : std_logic;
    signal app_uart   : std_logic;
    signal app_vga    : std_logic;
    signal app_accel  : std_logic;
    signal app_system : std_logic;


    ------------------------------------------------------------------------
    -- Application RGB
    ------------------------------------------------------------------------

    signal r_application : color_width_t;
    signal g_application : color_width_t;
    signal b_application : color_width_t;


    ------------------------------------------------------------------------
    -- VGA pattern selection
    ------------------------------------------------------------------------

    signal effective_pattern_sel : pattern_sel_t;


    ------------------------------------------------------------------------
    -- Text state
    ------------------------------------------------------------------------

    signal blink : std_logic;

    signal live_bcd :
        std_logic_vector(4*LIVE_DIGITS-1 downto 0);


    ------------------------------------------------------------------------
    -- Moving square
    ------------------------------------------------------------------------

    signal sq_x : coor_width_t;
    signal sq_y : coor_width_t;


    ------------------------------------------------------------------------
    -- Accelerometer
    ------------------------------------------------------------------------

    signal tilt_word : std_logic_vector(31 downto 0);
    signal tilt_tick : std_logic;

    signal tilt_px : coor_width_t;
    signal tilt_py : coor_width_t;

    signal spr_x : coor_width_t;
    signal spr_y : coor_width_t;

    signal accel_active : std_logic;


    ------------------------------------------------------------------------
    -- Pong
    ------------------------------------------------------------------------

    signal pong_ball_x : coor_width_t;
    signal pong_ball_y : coor_width_t;

    signal pong_player_y   : coor_width_t;
    signal pong_computer_y : coor_width_t;

    signal pong_player_score :
        std_logic_vector(3 downto 0);

    signal pong_computer_score :
        std_logic_vector(3 downto 0);

    signal pong_game_over : std_logic;
    signal pong_winner    : std_logic;

    signal r_pong : color_width_t;
    signal g_pong : color_width_t;
    signal b_pong : color_width_t;


    ------------------------------------------------------------------------
    -- Selected pattern RGB
    ------------------------------------------------------------------------

    signal r_selected : color_width_t;
    signal g_selected : color_width_t;
    signal b_selected : color_width_t;


begin

    ------------------------------------------------------------------------
    -- Pattern engine
    --
    -- Pattern 0 : border
    -- Pattern 1 : bars
    -- Pattern 2 : checker
    -- Pattern 3 : gradient
    -- Pattern 4 : moving square
    -- Pattern 5 : image
    -- Pattern 6 : text terminal
    -- Pattern 7 : sprite over image
    ------------------------------------------------------------------------

    U_PATTERN_ENGINE : entity work.pattern_engine
        port map
        (
            clk        => clk,
            rst        => rst,

            x          => x,
            y          => y,

            square_x   => sq_x,
            square_y   => sq_y,

            sprite_x   => spr_x,
            sprite_y   => spr_y,

            frame_tick => frame_tick,

            rx_data    => rx_data,
            rx_toggle  => rx_toggle,

            blink      => blink,

            live_bcd   => live_bcd,

            pix        => engine_pix
        );


    ------------------------------------------------------------------------
    -- Moving square
    ------------------------------------------------------------------------

    U_MOTION : entity work.bounce_motion
        port map
        (
            clk   => clk,
            rst   => rst,
            tick  => frame_tick,
            pos_x => sq_x,
            pos_y => sq_y
        );


    ------------------------------------------------------------------------
    -- Text cursor blink
    ------------------------------------------------------------------------

    U_BLINK : entity work.blink_gen
        port map
        (
            clk   => clk,
            rst   => rst,
            tick  => frame_tick,
            blink => blink
        );


    ------------------------------------------------------------------------
    -- Live text counter
    ------------------------------------------------------------------------

    U_LIVE : entity work.live_counter
        port map
        (
            clk    => clk,
            rst    => rst,
            digits => live_bcd
        );


    ------------------------------------------------------------------------
    -- UART menu control
    --
    -- Converts UART keyboard sequences into one-clock pulses.
    ------------------------------------------------------------------------

    U_MENU_UART_CONTROL : entity work.menu_uart_control
        port map
        (
            clk       => clk,
            rst       => rst,

            rx_data   => rx_data,
            rx_toggle => rx_toggle,

            menu_next  => menu_next,
            menu_prev  => menu_prev,
            menu_enter => menu_enter,
            menu_back  => menu_back
        );


    ------------------------------------------------------------------------
    -- Accelerometer capture
    ------------------------------------------------------------------------

    U_TILT_CAP : entity work.toggle_capture
        generic map
        (
            WIDTH => 32
        )
        port map
        (
            clk       => clk,
            rst       => rst,
            data_in   => tilt_data,
            toggle_in => tilt_toggle,
            data_out  => tilt_word
        );


    ------------------------------------------------------------------------
    -- Menu application selection
    --
    -- 000 = PONG
    -- 001 = UART TERMINAL
    -- 010 = VGA PATTERNS
    -- 011 = ACCELEROMETER
    -- 100 = SYSTEM INFO
    ------------------------------------------------------------------------

    app_pong <= '1'
        when menu_application_sel = "000"
        else '0';

    app_uart <= '1'
        when menu_application_sel = "001"
        else '0';

    app_vga <= '1'
        when menu_application_sel = "010"
        else '0';

    app_accel <= '1'
        when menu_application_sel = "011"
        else '0';

    app_system <= '1'
        when menu_application_sel = "100"
        else '0';


    ------------------------------------------------------------------------
    -- Accelerometer application
    ------------------------------------------------------------------------

    accel_active <= app_accel;

    tilt_tick <= frame_tick and accel_active;


    U_TILT : entity work.tilt_motion
        port map
        (
            clk    => clk,
            rst    => rst,
            tick   => tilt_tick,

            tilt_x => tilt_word(31 downto 16),
            tilt_y => tilt_word(15 downto 0),

            pos_x  => tilt_px,
            pos_y  => tilt_py
        );


    ------------------------------------------------------------------------
    -- Sprite X position
    --
    -- Normal VGA operation:
    --     sprite follows bouncing square.
    --
    -- Accelerometer application:
    --     sprite follows accelerometer position.
    ------------------------------------------------------------------------

    U_SPR_X : entity work.mux_2x1
        generic map
        (
            WIDTH => coor_width_t'length
        )
        port map
        (
            in1    => sq_x,
            in2    => tilt_px,
            sel    => accel_active,
            output => spr_x
        );


    ------------------------------------------------------------------------
    -- Sprite Y position
    ------------------------------------------------------------------------

    U_SPR_Y : entity work.mux_2x1
        generic map
        (
            WIDTH => coor_width_t'length
        )
        port map
        (
            in1    => sq_y,
            in2    => tilt_py,
            sel    => accel_active,
            output => spr_y
        );


    ------------------------------------------------------------------------
    -- Pong game
    ------------------------------------------------------------------------

    U_PONG_GAME : entity work.pong_game
        port map
        (
            clk        => clk,
            rst        => rst,
            frame_tick => frame_tick,

            tilt_x => tilt_word(31 downto 16),
            tilt_y => tilt_word(15 downto 0),

            ball_x => pong_ball_x,
            ball_y => pong_ball_y,

            player_y   => pong_player_y,
            computer_y => pong_computer_y,

            player_score   => pong_player_score,
            computer_score => pong_computer_score,

            game_over => pong_game_over,
            winner    => pong_winner
        );


    ------------------------------------------------------------------------
    -- Pong graphics
    ------------------------------------------------------------------------

    U_PATTERN_PONG : entity work.pattern_pong
        port map
        (
            clk => clk,
            rst => rst,

            x => x,
            y => y,

            ball_x => pong_ball_x,
            ball_y => pong_ball_y,

            player_y   => pong_player_y,
            computer_y => pong_computer_y,

            player_score   => pong_player_score,
            computer_score => pong_computer_score,

            game_over => pong_game_over,
            winner    => pong_winner,

            r => r_pong,
            g => g_pong,
            b => b_pong
        );


    ------------------------------------------------------------------------
    -- System info
    ------------------------------------------------------------------------

    U_SYSTEM_INFO : entity work.system_info
        port map
        (
            clk => clk,
            rst => rst,

            x => x,
            y => y,

            r => r8,
            g => g8,
            b => b8
        );


    ------------------------------------------------------------------------
    -- Menu graphics
    --
    -- pattern_menu controls menu_active.
    --
    -- menu_active = '1'
    --     Main menu or VGA submenu is displayed.
    --
    -- menu_active = '0'
    --     Selected application is displayed.
    ------------------------------------------------------------------------

    U_PATTERN_MENU : entity work.pattern_menu
        port map
        (
            clk => clk,
            rst => rst,

            x => x,
            y => y,

            menu_next  => menu_next,
            menu_prev  => menu_prev,
            menu_enter => menu_enter,
            menu_back  => menu_back,

            application_sel => menu_application_sel,
            menu_active     => menu_active,

            vga_pattern_sel => vga_pattern_sel,
            vga_menu_active => vga_menu_active,

            r => r_menu,
            g => g_menu,
            b => b_menu
        );


    ------------------------------------------------------------------------
    -- Effective VGA pattern selection
    --
    -- VGA submenu:
    --
    --   0 = BORDER
    --   1 = BARS
    --   2 = CHECKER
    --   3 = GRADIENT
    --   4 = MOVING SQUARE
    --   5 = IMAGE
    --   6 = IMAGE + SPRITE
    --
    -- Internal pattern 7 = IMAGE + SPRITE.
    --
    -- Internal pattern 6 remains the UART text terminal.
    ------------------------------------------------------------------------

    effective_pattern_sel <=
        "111"
        when
            (app_vga = '1' and
             vga_pattern_sel = "110")
        else vga_pattern_sel;


    ------------------------------------------------------------------------
    -- Align combinational patterns
    --
    -- pattern_engine contains the complete memory timing for:
    --
    --   pattern 5 = image
    --   pattern 6 = text
    --   pattern 7 = sprite/image
    --
    -- Patterns 0..4 are direct combinational pixel sources, so delay them
    -- by two clocks to match the other paths.
    ------------------------------------------------------------------------

    G_ALIGN : for k in 0 to 4 generate

        U_DLY : entity work.delay_line
            generic map
            (
                WIDTH  => 12,
                STAGES => 2
            )
            port map
            (
                clk    => clk,
                input  => engine_pix(k),
                output => pix(k)
            );

    end generate G_ALIGN;


    ------------------------------------------------------------------------
    -- Image
    ------------------------------------------------------------------------

    pix(5) <= engine_pix(5);


    ------------------------------------------------------------------------
    -- Text
    ------------------------------------------------------------------------

    pix(6) <= engine_pix(6);


    ------------------------------------------------------------------------
    -- Sprite
    ------------------------------------------------------------------------

    pix(7) <= engine_pix(7);


    ------------------------------------------------------------------------
    -- VGA pattern selector
    ------------------------------------------------------------------------

    U_SELECT : entity work.pattern_select
        port map
        (
            sel => effective_pattern_sel,
            pix => pix,

            r => r_selected,
            g => g_selected,
            b => b_selected
        );


    ------------------------------------------------------------------------
    -- FINAL APPLICATION SELECTOR
    ------------------------------------------------------------------------

    process(
        menu_application_sel,
        pix,
        r_pong,
        g_pong,
        b_pong,
        r_selected,
        g_selected,
        b_selected,
        r8,
        g8,
        b8
    )
    begin

        case menu_application_sel is

            when "000" =>
                ----------------------------------------------------------------
                -- PONG
                ----------------------------------------------------------------

                r_application <= r_pong;
                g_application <= g_pong;
                b_application <= b_pong;


            when "001" =>
                ----------------------------------------------------------------
                -- UART TERMINAL
                --
                -- Internal pattern 6.
                ----------------------------------------------------------------

                r_application <= pix(6)(11 downto 8);
                g_application <= pix(6)(7 downto 4);
                b_application <= pix(6)(3 downto 0);


            when "010" =>
                ----------------------------------------------------------------
                -- VGA PATTERNS
                ----------------------------------------------------------------

                r_application <= r_selected;
                g_application <= g_selected;
                b_application <= b_selected;


            when "011" =>
                ----------------------------------------------------------------
                -- ACCELEROMETER SPRITE
                --
                -- Internal pattern 7.
                ----------------------------------------------------------------

                r_application <= pix(7)(11 downto 8);
                g_application <= pix(7)(7 downto 4);
                b_application <= pix(7)(3 downto 0);


            when "100" =>
                ----------------------------------------------------------------
                -- SYSTEM INFO
                ----------------------------------------------------------------

                r_application <= r8;
                g_application <= g8;
                b_application <= b8;


            when others =>
                ----------------------------------------------------------------
                -- Default to VGA patterns
                ----------------------------------------------------------------

                r_application <= r_selected;
                g_application <= g_selected;
                b_application <= b_selected;

        end case;

    end process;


    ------------------------------------------------------------------------
    -- FINAL VGA OUTPUT
    --
    -- Menu is displayed while menu_active = '1'.
    --
    -- Once an application is selected:
    --
    --     menu_active = '0'
    --
    -- and the selected application is displayed.
    ------------------------------------------------------------------------

    r <= r_menu
        when menu_active = '1'
        else r_application;

    g <= g_menu
        when menu_active = '1'
        else g_application;

    b <= b_menu
        when menu_active = '1'
        else b_application;


end STR;