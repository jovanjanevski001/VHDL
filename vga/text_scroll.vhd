library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity text_scroll is
    generic
    (
        COLS : positive := 80;
        ROWS : positive := 60
    );
    port
    (
        row : in integer range 0 to ROWS - 1;
        top : in integer range 0 to ROWS - 1;

        scroll : in std_logic;

        phys_row : out integer range 0 to ROWS - 1;
        next_top : out integer range 0 to ROWS - 1;

        clear_start : out integer range 0 to (COLS * ROWS) - 1;
        clear_end   : out integer range 0 to (COLS * ROWS) - 1
    );
end text_scroll;

architecture BHV of text_scroll is

    constant CELLS : positive := COLS * ROWS;

begin

    process(row, top, scroll)
        variable v_phys_row : integer range 0 to ROWS - 1;
        variable v_next_top : integer range 0 to ROWS - 1;
        variable v_clear_row : integer range 0 to ROWS - 1;
    begin

        --------------------------------------------------------------------
        -- Current logical row -> physical text RAM row
        --------------------------------------------------------------------

        if row + top >= ROWS then
            v_phys_row := row + top - ROWS;
        else
            v_phys_row := row + top;
        end if;

        --------------------------------------------------------------------
        -- Default: no scroll
        --------------------------------------------------------------------

        v_next_top  := top;
        v_clear_row := top;

        --------------------------------------------------------------------
        -- Scroll advances the ring-buffer origin.
        --
        -- The old value of TOP is the physical row that becomes the
        -- newly exposed row, so that is the row that must be cleared.
        --------------------------------------------------------------------

        if scroll = '1' then

            v_clear_row := top;

            if top = ROWS - 1 then
                v_next_top := 0;
            else
                v_next_top := top + 1;
            end if;

        end if;

        --------------------------------------------------------------------
        -- Outputs
        --------------------------------------------------------------------

        phys_row <= v_phys_row;

        next_top <= v_next_top;

        clear_start <= v_clear_row * COLS;

        clear_end <= v_clear_row * COLS + COLS - 1;

    end process;

end BHV;