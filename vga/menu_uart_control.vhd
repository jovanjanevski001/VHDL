library ieee;
use ieee.std_logic_1164.all;

entity menu_uart_control is
    port
    (
        clk       : in std_logic;
        rst       : in std_logic;

        rx_data   : in std_logic_vector(7 downto 0);
        rx_toggle : in std_logic;

        menu_next  : out std_logic;
        menu_prev  : out std_logic;
        menu_enter : out std_logic;
        menu_back  : out std_logic
    );
end menu_uart_control;


architecture rtl of menu_uart_control is

    --------------------------------------------------------------------
    -- Detect a new UART byte
    --------------------------------------------------------------------

    signal rx_toggle_last : std_logic := '0';


    --------------------------------------------------------------------
    -- ANSI escape sequence state
    --
    -- Arrow keys:
    --
    --     UP    = ESC [ A
    --     DOWN  = ESC [ B
    --     RIGHT = ESC [ C
    --     LEFT  = ESC [ D
    --
    -- ESC by itself = BACK
    --------------------------------------------------------------------

    type escape_state_t is
    (
        IDLE,
        GOT_ESC,
        GOT_ESC_BRACKET
    );

    signal escape_state : escape_state_t := IDLE;


begin


    --------------------------------------------------------------------
    -- UART MENU CONTROL
    --------------------------------------------------------------------

    process(clk, rst)

        variable rx_byte :
            std_logic_vector(7 downto 0);

    begin

        if (rst = '1') then

            rx_toggle_last <= '0';
            escape_state   <= IDLE;

            menu_next  <= '0';
            menu_prev  <= '0';
            menu_enter <= '0';
            menu_back  <= '0';


        elsif rising_edge(clk) then

            ------------------------------------------------------------
            -- Default outputs.
            --
            -- All menu commands are one-clock pulses.
            ------------------------------------------------------------

            menu_next  <= '0';
            menu_prev  <= '0';
            menu_enter <= '0';
            menu_back  <= '0';


            ------------------------------------------------------------
            -- New UART byte
            ------------------------------------------------------------

            if (rx_toggle /= rx_toggle_last) then

                rx_toggle_last <= rx_toggle;

                rx_byte := rx_data;


                --------------------------------------------------------
                -- IDLE
                --------------------------------------------------------

                if (escape_state = IDLE) then

                    ----------------------------------------------------
                    -- ESC
                    --
                    -- Could be:
                    --
                    --     ESC by itself = BACK
                    --     ESC [ ...    = arrow key
                    --
                    -- Wait one character before deciding.
                    ----------------------------------------------------

                    if (rx_byte = x"1B") then

                        escape_state <= GOT_ESC;


                    ----------------------------------------------------
                    -- ENTER
                    ----------------------------------------------------

                    elsif (rx_byte = x"0D") or
                          (rx_byte = x"0A") then

                        menu_enter <= '1';

                    end if;


                --------------------------------------------------------
                -- GOT_ESC
                --------------------------------------------------------

                elsif (escape_state = GOT_ESC) then

                    ----------------------------------------------------
                    -- '[' means this is an ANSI arrow-key sequence.
                    ----------------------------------------------------

                    if (rx_byte = x"5B") then

                        escape_state <= GOT_ESC_BRACKET;


                    ----------------------------------------------------
                    -- Another ESC
                    --
                    -- Treat it as another possible ESC.
                    ----------------------------------------------------

                    elsif (rx_byte = x"1B") then

                        menu_back <= '1';
                        escape_state <= GOT_ESC;


                    ----------------------------------------------------
                    -- Anything else means the previous ESC was alone.
                    --
                    -- Therefore it is BACK.
                    ----------------------------------------------------

                    else

                        menu_back <= '1';
                        escape_state <= IDLE;

                    end if;


                --------------------------------------------------------
                -- GOT_ESC_BRACKET
                --
                -- Decode the final ANSI arrow byte.
                --------------------------------------------------------

                elsif (escape_state = GOT_ESC_BRACKET) then

                    case rx_byte is

                        ------------------------------------------------
                        -- UP
                        ------------------------------------------------

                        when x"41" =>
                            menu_prev <= '1';


                        ------------------------------------------------
                        -- DOWN
                        ------------------------------------------------

                        when x"42" =>
                            menu_next <= '1';


                        ------------------------------------------------
                        -- RIGHT
                        ------------------------------------------------

                        when x"43" =>
                            menu_enter <= '1';


                        ------------------------------------------------
                        -- LEFT
                        ------------------------------------------------

                        when x"44" =>
                            menu_back <= '1';


                        ------------------------------------------------
                        -- Unknown sequence
                        ------------------------------------------------

                        when others =>
                            null;

                    end case;

                    escape_state <= IDLE;

                end if;

            end if;

        end if;

    end process;

end rtl;