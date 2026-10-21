library ieee;
use ieee.std_logic_1164.all;
 
-- SPI master controller (mode 3: SCLK idles high, data changes on the falling edge and is
-- sampled on the rising edge, most significant bit first). The FSM only; counters and
-- shift registers are in spi_datapath.
--
--   IDLE  SCLK high. start loads the byte to send.
--   LOW   SCLK low for half a bit time; at the end the incoming bit is sampled (rising edge).
--   HIGH  SCLK high for half a bit time; at the end either the byte is complete or the next bit starts.
--
-- Status signals from the datapath: half_done, last_bit.
-- Control signals to the datapath:  clr_half, clr_bit, load_tx, shift_tx, inc_bit, sample_rx, sclk_lo.
entity spi_ctrl is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;     -- active high
 
        start     : in  std_logic;     -- send (and receive) one byte
        busy      : out std_logic;     -- a byte is in progress
        done      : out std_logic;     -- one-clock pulse: byte finished, rx_byte is valid
 
        -- status signals from the datapath
        half_done : in  std_logic;     -- half a bit time has passed
        last_bit  : in  std_logic;     -- the bit in progress is the eighth (index 7)
 
        -- control signals to the datapath
        clr_half  : out std_logic;     -- restart the half-bit counter
        clr_bit   : out std_logic;     -- bit index back to 0
        load_tx   : out std_logic;     -- take the byte to send
        shift_tx  : out std_logic;     -- next bit to send
        inc_bit   : out std_logic;     -- next bit
        sample_rx : out std_logic;     -- store the incoming bit
        sclk_lo   : out std_logic      -- SCLK is low in this state
    );
end spi_ctrl;
 
architecture FSM2 of spi_ctrl is
    type state_t is (IDLE, LOW, HIGH);
    signal state, next_state : state_t;
begin
 
    ------------------------------------------------------------------ state register
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
 
    ------------------------------------------------------------------ next state / control
    process(state, start, half_done, last_bit)
    begin
        -- defaults
        next_state <= state;
        clr_half   <= '0';
        clr_bit    <= '0';
        load_tx    <= '0';
        shift_tx   <= '0';
        inc_bit    <= '0';
        sample_rx  <= '0';
        done       <= '0';
 
        case state is
            when IDLE =>
                clr_half <= '1';
                clr_bit  <= '1';
                if start = '1' then
                    load_tx    <= '1';
                    next_state <= LOW;
                end if;
 
            when LOW =>
                if half_done = '1' then
                    sample_rx  <= '1';
                    next_state <= HIGH;
                end if;
 
            when HIGH =>
                if half_done = '1' then
                    if last_bit = '1' then
                        done       <= '1';
                        next_state <= IDLE;
                    else
                        shift_tx   <= '1';
                        inc_bit    <= '1';
                        next_state <= LOW;
                    end if;
                end if;
        end case;
    end process;
 
    ------------------------------------------------------------------ outputs (Moore)
    sclk_lo <= '1' when state = LOW  else '0';
    busy    <= '0' when state = IDLE else '1';
 
end FSM2;