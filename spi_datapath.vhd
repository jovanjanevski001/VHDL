library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- SPI master datapath: half-bit counter, bit counter, transmit and receive shift registers,
-- and the registered SCLK / MOSI outputs. All built from the reusable parts.
--
-- SCLK and MOSI come out of flip-flops (never straight from the FSM decode), so SCLK cannot
-- glitch; both are delayed by the same one clock so they stay lined up with each other.
-- MISO comes from outside, so it goes through a two-flop synchronizer first.
entity spi_datapath is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;     -- active high
 
        tx_byte   : in  std_logic_vector(7 downto 0);
        rx_byte   : out std_logic_vector(7 downto 0);
 
        -- SPI pins
        sclk      : out std_logic;
        mosi      : out std_logic;
        miso      : in  std_logic;
 
        -- status signals to the controller
        half_done : out std_logic;
        last_bit  : out std_logic;
 
        -- control signals from the controller
        clr_half  : in  std_logic;
        clr_bit   : in  std_logic;
        load_tx   : in  std_logic;
        shift_tx  : in  std_logic;
        inc_bit   : in  std_logic;
        sample_rx : in  std_logic;
        sclk_lo   : in  std_logic
    );
end spi_datapath;
 
architecture STR of spi_datapath is
    constant C_BIT_ZERO : std_logic_vector(2 downto 0) := "000";
    constant C_BIT_ONE  : std_logic_vector(2 downto 0) := "001";
    constant C_BIT_LAST : std_logic_vector(2 downto 0) := "111";
    constant ENABLE     : std_logic := '1';
 
    -- bit counter
    signal bit_cnt, bit_1, bit_nxt : std_logic_vector(2 downto 0);
    signal bit_en                  : std_logic;
 
    -- transmit register: load the byte, or shift it left
    signal tx_reg, tx_shifted, tx_nxt : std_logic_vector(7 downto 0);
    signal tx_en                      : std_logic;
 
    -- receive register: shift the sampled bit in at the bottom
    signal rx_reg, rx_nxt : std_logic_vector(7 downto 0);
    signal miso_in, miso_s : std_logic_vector(0 downto 0);
 
    -- registered outputs: bit 1 = SCLK is low, bit 0 = MOSI
    signal pin_nxt, pin_reg : std_logic_vector(1 downto 0);
begin
 
    ------------------------------------------------------------------ half-bit counter
    U_HALF : entity work.period_counter
        generic map ( PERIOD => SPI_HALF_CLKS )
        port map ( clk => clk, rst => rst, clr => clr_half, tick => half_done );
 
    ------------------------------------------------------------------ bit counter
    U_BIT_INC : entity work.adder
        generic map ( WIDTH => 3 )
        port map ( in1 => bit_cnt, in2 => C_BIT_ONE, output => bit_1 );
 
    U_BIT_CLR : entity work.mux_2x1
        generic map ( WIDTH => 3 )
        port map ( in1 => bit_1, in2 => C_BIT_ZERO, sel => clr_bit, output => bit_nxt );
 
    bit_en <= inc_bit or clr_bit;
 
    U_BIT_REG : entity work.reg_en
        generic map ( WIDTH => 3 )
        port map ( clk => clk, rst => rst, en => bit_en, input => bit_nxt, output => bit_cnt );
 
    U_BIT_LAST : entity work.comparator_eq
        generic map ( WIDTH => 3 )
        port map ( in1 => bit_cnt, in2 => C_BIT_LAST, eq => last_bit );
 
    ------------------------------------------------------------------ transmit register
    tx_shifted <= tx_reg(6 downto 0) & '0';
 
    U_TX_SEL : entity work.mux_2x1
        generic map ( WIDTH => 8 )
        port map ( in1 => tx_shifted, in2 => tx_byte, sel => load_tx, output => tx_nxt );
 
    tx_en <= load_tx or shift_tx;
 
    U_TX_REG : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => tx_en, input => tx_nxt, output => tx_reg );
 
    ------------------------------------------------------------------ receive register
    miso_in(0) <= miso;
 
    U_MISO_SYNC : entity work.sync_2ff
        generic map ( WIDTH => 1 )
        port map ( clk => clk, input => miso_in, output => miso_s );
 
    rx_nxt <= rx_reg(6 downto 0) & miso_s(0);
 
    U_RX_REG : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => sample_rx, input => rx_nxt, output => rx_reg );
 
    rx_byte <= rx_reg;
 
    ------------------------------------------------------------------ registered pins
    pin_nxt <= sclk_lo & tx_reg(7);
 
    U_PINS : entity work.reg_en
        generic map ( WIDTH => 2 )
        port map ( clk => clk, rst => rst, en => ENABLE, input => pin_nxt, output => pin_reg );
 
    sclk <= not pin_reg(1);		-- idles high (the registers reset to 0)
    mosi <= pin_reg(0);
 
end STR;