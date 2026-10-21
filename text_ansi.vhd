library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity text_ansi is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        enable : in std_logic;
        input  : in std_logic_vector(7 downto 0);

        char_valid : out std_logic;
        char       : out std_logic_vector(7 downto 0);

        sgr_valid : out std_logic;
        sgr_p1    : out integer range 0 to 999;
        sgr_p2    : out integer range 0 to 999;
        sgr_param : out integer range 0 to 999;
        sgr_have_p1 : out std_logic;
        sgr_have_p2 : out std_logic;

        clear_screen : out std_logic;
        clear_line   : out std_logic;

        cursor_pos     : out std_logic;
        cursor_p1      : out integer range 0 to 999;
        cursor_param   : out integer range 0 to 999;
        cursor_have_p1 : out std_logic
    );
end text_ansi;

architecture STR of text_ansi is

    type state_t is
    (
        ESC_NONE,
        ESC_GOT,
        ESC_CSI
    );

    signal state : state_t := ESC_NONE;

    signal param   : integer range 0 to 999 := 0;
    signal p1      : integer range 0 to 999 := 0;
    signal p2      : integer range 0 to 999 := 0;
    signal have_p1 : std_logic := '0';
    signal have_p2 : std_logic := '0';

begin

    ------------------------------------------------------------------------
    -- ANSI parser state.
    ------------------------------------------------------------------------

    process(clk)
        variable b : integer;
    begin
        if rising_edge(clk) then

            if rst = '1' then

                state   <= ESC_NONE;

                param   <= 0;
                p1      <= 0;
                p2      <= 0;

                have_p1 <= '0';
                have_p2 <= '0';

            elsif enable = '1' then

                b := to_integer(unsigned(input));

                case state is

                    when ESC_NONE =>

                        if b = 27 then
                            state <= ESC_GOT;
                        end if;

                    when ESC_GOT =>

                        if b = 91 then

                            state <= ESC_CSI;

                            param   <= 0;
                            p1      <= 0;
                            p2      <= 0;
                            have_p1 <= '0';
                            have_p2 <= '0';

                        else
                            state <= ESC_NONE;
                        end if;

                    when ESC_CSI =>

                        if b >= 48 and b <= 57 then

                            if param < 100 then
                                param <= param * 10 + (b - 48);
                            end if;

                        elsif b = 59 then

                            if have_p1 = '0' then

                                p1      <= param;
                                have_p1 <= '1';

                            elsif have_p2 = '0' then

                                p2      <= param;
                                have_p2 <= '1';

                            end if;

                            param <= 0;

                        else

                            state <= ESC_NONE;

                        end if;

                end case;

            end if;

        end if;
    end process;

    ------------------------------------------------------------------------
    -- Decode the current input and current parser state.
    --
    -- These outputs are intentionally combinational. This preserves the
    -- original text_writer timing: fifo_data is decoded during the same
    -- cycle that fifo_pop is asserted.
    ------------------------------------------------------------------------

    process(state, input, enable, p1, p2, param, have_p1, have_p2)

        variable b : integer;

    begin

        char_valid <= '0';
        char       <= input;

        sgr_valid   <= '0';
        sgr_p1      <= p1;
        sgr_p2      <= p2;
        sgr_param   <= param;
        sgr_have_p1 <= have_p1;
        sgr_have_p2 <= have_p2;

        clear_screen <= '0';
        clear_line   <= '0';

        cursor_pos     <= '0';
        cursor_p1      <= p1;
        cursor_param   <= param;
        cursor_have_p1 <= have_p1;

        if enable = '1' then

            b := to_integer(unsigned(input));

            case state is

                ----------------------------------------------------------------
                -- Normal terminal input.
                ----------------------------------------------------------------

                when ESC_NONE =>

                    if b /= 27 then
                        char_valid <= '1';
                    end if;

                ----------------------------------------------------------------
                -- ESC has been received.
                ----------------------------------------------------------------

                when ESC_GOT =>

                    null;

                ----------------------------------------------------------------
                -- CSI command terminator.
                ----------------------------------------------------------------

                when ESC_CSI =>

                    if b = 109 then

                        sgr_valid <= '1';

                    elsif b = 74 then

                        if param = 2 and have_p1 = '0' then
                            clear_screen <= '1';
                        end if;

                    elsif b = 75 then

                        if param = 0 and have_p1 = '0' then
                            clear_line <= '1';
                        end if;

                    elsif b = 72 or b = 102 then

                        cursor_pos <= '1';

                    end if;

            end case;

        end if;

    end process;

end STR;