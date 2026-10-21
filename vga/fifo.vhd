library ieee;
use ieee.std_logic_1164.all;

entity fifo is
    generic
    (
        WIDTH : positive := 8;
        DEPTH : positive := 16
    );
    port
    (
        clk    : in  std_logic;
        rst    : in  std_logic;

        push   : in  std_logic;
        pop    : in  std_logic;

        input  : in  std_logic_vector(WIDTH - 1 downto 0);
        output : out std_logic_vector(WIDTH - 1 downto 0);

        empty  : out std_logic;
        full   : out std_logic
    );
end fifo;

architecture BHV of fifo is

    type memory_t is array
    (
        0 to DEPTH - 1
    ) of std_logic_vector(WIDTH - 1 downto 0);

    signal memory : memory_t;

    signal write_ptr : integer range 0 to DEPTH - 1 := 0;
    signal read_ptr  : integer range 0 to DEPTH - 1 := 0;
    signal count     : integer range 0 to DEPTH := 0;

begin

    output <= memory(read_ptr);

    empty <= '1' when count = 0 else '0';
    full  <= '1' when count = DEPTH else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                write_ptr <= 0;
                read_ptr  <= 0;
                count     <= 0;

            else
                if push = '1' then
                    memory(write_ptr) <= input;

                    if write_ptr = DEPTH - 1 then
                        write_ptr <= 0;
                    else
                        write_ptr <= write_ptr + 1;
                    end if;
                end if;

                if pop = '1' then
                    if read_ptr = DEPTH - 1 then
                        read_ptr <= 0;
                    else
                        read_ptr <= read_ptr + 1;
                    end if;
                end if;

                if push = '1' and pop = '0' then
                    count <= count + 1;

                elsif push = '0' and pop = '1' then
                    count <= count - 1;
                end if;
            end if;
        end if;
    end process;

end BHV;