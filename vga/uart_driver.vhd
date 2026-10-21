library ieee;
use ieee.std_logic_1164.all;
 
-- UART receive driver: board-agnostic wrapper around uart_rx.
-- Takes the raw pin and an active-high reset, like vga_driver does.
--
-- data_toggle flips once for every received byte. It exists so the byte can be passed to a block
-- running on a different clock (the pixel clock): data_byte is held for a whole byte time
-- (about 87 us at 115200 baud), so the other side only has to synchronize this one toggle bit
-- and then read data_byte.
entity uart_driver is
    generic (
        CLOCK_HZ  : positive := 50_000_000;
        BAUD_RATE : positive := 115_200
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;                      -- active high
        rx_pin      : in  std_logic;                      -- raw UART RX input
 
        data_byte   : out std_logic_vector(7 downto 0);   -- last received byte (held)
        data_toggle : out std_logic                       -- flips once per new byte
    );
end uart_driver;
 
architecture STR of uart_driver is

    signal rx_vec     : std_logic_vector(0 downto 0);
    signal reset_n    : std_logic;
    signal valid      : std_logic;
    signal toggle_reg : std_logic := '0';

begin
    
	rx_vec(0)  <= rx_pin;
    reset_n    <= not rst;
 
    U_UART_RX : entity work.uart_rx
        generic map ( CLOCK_HZ => CLOCK_HZ, BAUD_RATE => BAUD_RATE )
        port map
        (
            clk        => clk,
            reset_n    => reset_n,
            rx         => rx_vec,
            data_byte  => data_byte,
            data_valid => valid
        );
  
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                toggle_reg <= '0';
            elsif valid = '1' then
                toggle_reg <= not toggle_reg;
            end if;
        end if;
    end process;
 
    data_toggle <= toggle_reg;
end STR;
 