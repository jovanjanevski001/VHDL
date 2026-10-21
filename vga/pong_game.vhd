library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;

entity pong_game is
    port
    (
        clk             : in  std_logic;
        rst             : in  std_logic;
        frame_tick      : in  std_logic;

        tilt_x          : in  std_logic_vector(15 downto 0);
        tilt_y          : in  std_logic_vector(15 downto 0);

        ball_x          : out coor_width_t;
        ball_y          : out coor_width_t;

        player_y        : out coor_width_t;
        computer_y      : out coor_width_t;

        player_score    : out std_logic_vector(3 downto 0);
        computer_score  : out std_logic_vector(3 downto 0);

        game_over       : out std_logic;
        winner          : out std_logic
    );
end pong_game;


architecture BHV of pong_game is

    --------------------------------------------------------------------
    -- Pong geometry
    --------------------------------------------------------------------
    constant PADDLE_WIDTH  : integer := 12;
    constant PADDLE_HEIGHT : integer := 72;
    constant BALL_SIZE     : integer := 8;

    constant PLAYER_X      : integer := 32;
    constant COMPUTER_X    : integer :=
        H_VISIBLE - 32 - PADDLE_WIDTH;

    constant MAX_PADDLE_Y  : integer :=
        V_VISIBLE - PADDLE_HEIGHT;

    constant MAX_BALL_X    : integer :=
        H_VISIBLE - BALL_SIZE;

    constant MAX_BALL_Y    : integer :=
        V_VISIBLE - BALL_SIZE;


    --------------------------------------------------------------------
    -- Game speed
    --------------------------------------------------------------------
    constant BALL_SPEED_X  : integer := 4;
    constant BALL_SPEED_Y  : integer := 3;

    constant COMPUTER_SPEED : integer := 3;
    constant COMPUTER_DEADZONE : integer := 6;


    --------------------------------------------------------------------
    -- Scoring / game-state timing
    --------------------------------------------------------------------
    constant SCORE_PAUSE_FRAMES : integer := 60;
    constant GAME_OVER_FRAMES   : integer := 180;


    --------------------------------------------------------------------
    -- Game states
    --------------------------------------------------------------------
    type game_state_t is
    (
        PLAYING,
        SCORE_PAUSE,
        GAME_OVER_S
    );

    signal game_state : game_state_t;


    --------------------------------------------------------------------
    -- Ball state
    --------------------------------------------------------------------
    signal bx : integer range 0 to MAX_BALL_X;
    signal by : integer range 0 to MAX_BALL_Y;

    signal ball_vx : integer range -16 to 16;
    signal ball_vy : integer range -16 to 16;


    --------------------------------------------------------------------
    -- Paddle state
    --------------------------------------------------------------------
    signal py_player : integer range 0 to MAX_PADDLE_Y;
    signal py_computer : integer range 0 to MAX_PADDLE_Y;


    --------------------------------------------------------------------
    -- Scores
    --------------------------------------------------------------------
    signal player_score_reg   : integer range 0 to 9;
    signal computer_score_reg : integer range 0 to 9;


    --------------------------------------------------------------------
    -- Game-over information
    --
    -- '0' = player wins
    -- '1' = computer wins
    --------------------------------------------------------------------
    signal winner_reg : std_logic;


    --------------------------------------------------------------------
    -- Pause counter
    --------------------------------------------------------------------
    signal pause_counter : integer range 0 to GAME_OVER_FRAMES;


    --------------------------------------------------------------------
    -- Accelerometer speed
    --
    -- This is intentionally the same speed calculation used by
    -- tilt_motion.vhd.
    --------------------------------------------------------------------
    function tilt_speed
    (
        reading : std_logic_vector(15 downto 0);
        invert  : boolean
    ) return integer is

        variable a   : integer;
        variable mag : integer;

    begin

        a := to_integer(signed(reading));

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


    --------------------------------------------------------------------
    -- Player vertical velocity
    --------------------------------------------------------------------
    signal player_vy : integer range -4096 to 4096;


begin

    --------------------------------------------------------------------
    -- Accelerometer axis selection
    --------------------------------------------------------------------
    player_vy <=
        tilt_speed(tilt_x, TILT_INVERT_Y)
            when TILT_SWAP_XY = true
        else
        tilt_speed(tilt_y, TILT_INVERT_Y);


    --------------------------------------------------------------------
    -- Main Pong game process
    --------------------------------------------------------------------
    process(clk, rst)

        variable new_player_y   : integer;
        variable new_computer_y : integer;

        variable new_bx : integer;
        variable new_by : integer;

        variable player_center   : integer;
        variable computer_center : integer;
        variable ball_center_y   : integer;

    begin

        if (rst = '1') then

            ----------------------------------------------------------------
            -- Initial game state
            ----------------------------------------------------------------
            bx <= H_VISIBLE / 2 - BALL_SIZE / 2;
            by <= V_VISIBLE / 2 - BALL_SIZE / 2;

            ball_vx <= BALL_SPEED_X;
            ball_vy <= BALL_SPEED_Y;

            py_player <= V_VISIBLE / 2 - PADDLE_HEIGHT / 2;
            py_computer <= V_VISIBLE / 2 - PADDLE_HEIGHT / 2;

            player_score_reg <= 0;
            computer_score_reg <= 0;

            game_state <= PLAYING;

            pause_counter <= 0;

            winner_reg <= '0';


        elsif (rising_edge(clk)) then

            if (frame_tick = '1') then

                case game_state is


                    ----------------------------------------------------------------
                    -- NORMAL PLAY
                    ----------------------------------------------------------------
                    when PLAYING =>

                        ------------------------------------------------------------
                        -- Player paddle
                        ------------------------------------------------------------
                        new_player_y := py_player + player_vy;

                        if (new_player_y < 0) then
                            new_player_y := 0;
                        elsif (new_player_y > MAX_PADDLE_Y) then
                            new_player_y := MAX_PADDLE_Y;
                        end if;

                        py_player <= new_player_y;


                        ------------------------------------------------------------
                        -- Computer paddle
                        ------------------------------------------------------------
                        ball_center_y := by + BALL_SIZE / 2;
                        computer_center :=
                            py_computer + PADDLE_HEIGHT / 2;

                        new_computer_y := py_computer;

                        if (ball_center_y >
                            computer_center + COMPUTER_DEADZONE) then

                            new_computer_y :=
                                py_computer + COMPUTER_SPEED;

                        elsif (ball_center_y <
                               computer_center - COMPUTER_DEADZONE) then

                            new_computer_y :=
                                py_computer - COMPUTER_SPEED;

                        end if;


                        if (new_computer_y < 0) then
                            new_computer_y := 0;
                        elsif (new_computer_y > MAX_PADDLE_Y) then
                            new_computer_y := MAX_PADDLE_Y;
                        end if;

                        py_computer <= new_computer_y;


                        ------------------------------------------------------------
                        -- Ball movement
                        ------------------------------------------------------------
                        new_bx := bx + ball_vx;
                        new_by := by + ball_vy;


                        ------------------------------------------------------------
                        -- Top/bottom wall collision
                        ------------------------------------------------------------
                        if (new_by <= 0) then

                            new_by := 0;
                            ball_vy <= BALL_SPEED_Y;

                        elsif (new_by >= MAX_BALL_Y) then

                            new_by := MAX_BALL_Y;
                            ball_vy <= -BALL_SPEED_Y;

                        end if;


                        ------------------------------------------------------------
                        -- Player paddle collision
                        --
                        -- Ball is moving toward player.
                        ------------------------------------------------------------
                        if (ball_vx < 0) then

                            if
                            (
                                (new_bx <= PLAYER_X + PADDLE_WIDTH) and
                                (new_bx + BALL_SIZE >= PLAYER_X) and
                                (new_by + BALL_SIZE >= py_player) and
                                (new_by <= py_player + PADDLE_HEIGHT)
                            )
                            then

                                new_bx := PLAYER_X + PADDLE_WIDTH;

                                ball_vx <= BALL_SPEED_X;

                            end if;

                        end if;


                        ------------------------------------------------------------
                        -- Computer paddle collision
                        --
                        -- Ball is moving toward computer.
                        ------------------------------------------------------------
                        if (ball_vx > 0) then

                            if
                            (
                                (new_bx + BALL_SIZE >= COMPUTER_X) and
                                (new_bx <= COMPUTER_X + PADDLE_WIDTH) and
                                (new_by + BALL_SIZE >= py_computer) and
                                (new_by <= py_computer + PADDLE_HEIGHT)
                            )
                            then

                                new_bx := COMPUTER_X - BALL_SIZE;

                                ball_vx <= -BALL_SPEED_X;

                            end if;

                        end if;


                        ------------------------------------------------------------
                        -- Player scores
                        --
                        -- Ball reached the right side.
                        ------------------------------------------------------------
                        if (new_bx >= MAX_BALL_X) then

                            if (player_score_reg = 8) then

                                ----------------------------------------------------
                                -- Player reaches 9: game over.
                                ----------------------------------------------------
                                player_score_reg <= 9;

                                winner_reg <= '0';

                                game_state <= GAME_OVER_S;

                                pause_counter <= 0;

                                new_bx :=
                                    H_VISIBLE / 2 - BALL_SIZE / 2;

                                new_by :=
                                    V_VISIBLE / 2 - BALL_SIZE / 2;

                                ball_vx <= 0;
                                ball_vy <= 0;

                            else

                                ----------------------------------------------------
                                -- Normal point.
                                ----------------------------------------------------
                                player_score_reg <=
                                    player_score_reg + 1;

                                new_bx :=
                                    H_VISIBLE / 2 - BALL_SIZE / 2;

                                new_by :=
                                    V_VISIBLE / 2 - BALL_SIZE / 2;

                                ----------------------------------------------------
                                -- Serve toward computer.
                                ----------------------------------------------------
                                ball_vx <= -BALL_SPEED_X;
                                ball_vy <= BALL_SPEED_Y;

                                pause_counter <= 0;

                                game_state <= SCORE_PAUSE;

                            end if;


                        ------------------------------------------------------------
                        -- Computer scores
                        --
                        -- Ball reached the left side.
                        ------------------------------------------------------------
                        elsif (new_bx <= 0) then

                            if (computer_score_reg = 8) then

                                ----------------------------------------------------
                                -- Computer reaches 9: game over.
                                ----------------------------------------------------
                                computer_score_reg <= 9;

                                winner_reg <= '1';

                                game_state <= GAME_OVER_S;

                                pause_counter <= 0;

                                new_bx :=
                                    H_VISIBLE / 2 - BALL_SIZE / 2;

                                new_by :=
                                    V_VISIBLE / 2 - BALL_SIZE / 2;

                                ball_vx <= 0;
                                ball_vy <= 0;

                            else

                                ----------------------------------------------------
                                -- Normal point.
                                ----------------------------------------------------
                                computer_score_reg <=
                                    computer_score_reg + 1;

                                new_bx :=
                                    H_VISIBLE / 2 - BALL_SIZE / 2;

                                new_by :=
                                    V_VISIBLE / 2 - BALL_SIZE / 2;

                                ----------------------------------------------------
                                -- Serve toward player.
                                ----------------------------------------------------
                                ball_vx <= BALL_SPEED_X;
                                ball_vy <= BALL_SPEED_Y;

                                pause_counter <= 0;

                                game_state <= SCORE_PAUSE;

                            end if;

                        end if;


                        ------------------------------------------------------------
                        -- Commit ball position
                        ------------------------------------------------------------
                        bx <= new_bx;
                        by <= new_by;


                    ----------------------------------------------------------------
                    -- SCORE PAUSE
                    --
                    -- Ball is stationary in the center for one second.
                    ----------------------------------------------------------------
                    when SCORE_PAUSE =>

                        ------------------------------------------------------------
                        -- Keep ball centered.
                        ------------------------------------------------------------
                        bx <= H_VISIBLE / 2 - BALL_SIZE / 2;
                        by <= V_VISIBLE / 2 - BALL_SIZE / 2;

                        if (pause_counter < SCORE_PAUSE_FRAMES) then

                            pause_counter <= pause_counter + 1;

                        else

                            pause_counter <= 0;
                            game_state <= PLAYING;

                        end if;


                    ----------------------------------------------------------------
                    -- GAME OVER
                    --
                    -- Hold final score for approximately three seconds.
                    ----------------------------------------------------------------
                    when GAME_OVER_S =>

                        ------------------------------------------------------------
                        -- Keep ball centered and stopped.
                        ------------------------------------------------------------
                        bx <= H_VISIBLE / 2 - BALL_SIZE / 2;
                        by <= V_VISIBLE / 2 - BALL_SIZE / 2;

                        ball_vx <= 0;
                        ball_vy <= 0;


                        if (pause_counter < GAME_OVER_FRAMES) then

                            pause_counter <= pause_counter + 1;

                        else

                            --------------------------------------------------------
                            -- Start a new game.
                            --------------------------------------------------------
                            pause_counter <= 0;

                            player_score_reg <= 0;
                            computer_score_reg <= 0;

                            bx <=
                                H_VISIBLE / 2 - BALL_SIZE / 2;

                            by <=
                                V_VISIBLE / 2 - BALL_SIZE / 2;

                            ball_vx <= BALL_SPEED_X;
                            ball_vy <= BALL_SPEED_Y;

                            py_player <=
                                V_VISIBLE / 2 - PADDLE_HEIGHT / 2;

                            py_computer <=
                                V_VISIBLE / 2 - PADDLE_HEIGHT / 2;

                            winner_reg <= '0';

                            game_state <= PLAYING;

                        end if;


                end case;

            end if;

        end if;

    end process;


    --------------------------------------------------------------------
    -- Outputs
    --------------------------------------------------------------------
    ball_x <= std_logic_vector(
        to_unsigned(bx, coor_width_t'length)
    );

    ball_y <= std_logic_vector(
        to_unsigned(by, coor_width_t'length)
    );

    player_y <= std_logic_vector(
        to_unsigned(py_player, coor_width_t'length)
    );

    computer_y <= std_logic_vector(
        to_unsigned(py_computer, coor_width_t'length)
    );


    player_score <= std_logic_vector(
        to_unsigned(player_score_reg, 4)
    );

    computer_score <= std_logic_vector(
        to_unsigned(computer_score_reg, 4)
    );


    game_over <= '1'
        when game_state = GAME_OVER_S
        else '0';

    winner <= winner_reg;

end BHV;