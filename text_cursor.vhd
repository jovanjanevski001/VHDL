library ieee;
use ieee.std_logic_1164.all;

entity text_cursor is
    generic
    (
        COLS : positive := 80;
        ROWS : positive := 60
    );
    port
    (
        col : in integer range 0 to COLS - 1;
        row : in integer range 0 to ROWS - 1;

        advance : in std_logic;
        cr      : in std_logic;
        back    : in std_logic;

        next_col : out integer range 0 to COLS - 1;
        next_row : out integer range 0 to ROWS - 1;
        scroll   : out std_logic
    );
end text_cursor;

architecture BHV of text_cursor is
begin

    process(col, row, advance, cr, back)
        variable v_col    : integer range 0 to COLS - 1;
        variable v_row    : integer range 0 to ROWS - 1;
        variable v_scroll : std_logic;
    begin
        v_col    := col;
        v_row    := row;
        v_scroll := '0';

        if cr = '1' then
            v_col := 0;

            if row = ROWS - 1 then
                v_scroll := '1';
            else
                v_row := row + 1;
            end if;

        elsif back = '1' then
            if col > 0 then
                v_col := col - 1;

            elsif row > 0 then
                v_col := COLS - 1;
                v_row := row - 1;
            end if;

        elsif advance = '1' then
            if col = COLS - 1 then
                v_col := 0;

                if row = ROWS - 1 then
                    v_scroll := '1';
                else
                    v_row := row + 1;
                end if;

            else
                v_col := col + 1;
            end if;
        end if;

        next_col <= v_col;
        next_row <= v_row;
        scroll   <= v_scroll;
    end process;

end BHV;