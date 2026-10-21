library ieee;
use ieee.std_logic_1164.all;
 
-- SPI master, one byte at a time: pulse start with tx_byte on the input, wait for the done
-- pulse, then rx_byte holds what came back. Chip select is not here; the block that knows
-- how many bytes make a transaction owns it (accel_driver).
entity spi_master is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;                      -- active high
 
        start   : in  std_logic;                      -- send tx_byte
        tx_byte : in  std_logic_vector(7 downto 0);
        rx_byte : out std_logic_vector(7 downto 0);
        busy    : out std_logic;
        done    : out std_logic;                      -- one-clock pulse
 
        sclk    : out std_logic;
        mosi    : out std_logic;
        miso    : in  std_logic
    );
end spi_master;
 
architecture STR of spi_master is
    signal half_done, last_bit : std_logic;
    signal clr_half, clr_bit, load_tx, shift_tx, inc_bit, sample_rx, sclk_lo : std_logic;
begin
    U_CTRL : entity work.spi_ctrl
        port map
        (
            clk => clk, rst => rst,
            start => start, busy => busy, done => done,
            half_done => half_done, last_bit => last_bit,
            clr_half => clr_half, clr_bit => clr_bit, load_tx => load_tx,
            shift_tx => shift_tx, inc_bit => inc_bit, sample_rx => sample_rx,
            sclk_lo => sclk_lo
        );
 
    U_DATAPATH : entity work.spi_datapath
        port map
        (
            clk => clk, rst => rst,
            tx_byte => tx_byte, rx_byte => rx_byte,
            sclk => sclk, mosi => mosi, miso => miso,
            half_done => half_done, last_bit => last_bit,
            clr_half => clr_half, clr_bit => clr_bit, load_tx => load_tx,
            shift_tx => shift_tx, inc_bit => inc_bit, sample_rx => sample_rx,
            sclk_lo => sclk_lo
        );
end STR;