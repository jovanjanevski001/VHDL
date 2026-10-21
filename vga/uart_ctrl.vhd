library ieee;
use ieee.std_logic_1164.all;
 
-- UART receiver controller: the FSM only. It decides what happens next from the status signals
-- and tells the datapath what to do with control signals; it holds no counters or data.
--
--   IDLE      wait for the line to fall (start bit)
--   START_BIT wait half a bit, then check the line is still low (rejects glitches)
--   DATA_BITS every full bit time, sample one data bit (LSB first), 8 times
--   STOP_BIT  wait one more bit time; a high line means a good frame, so the byte is released
--
-- Status signals from the datapath: rx_level, half_done, bit_done, last_bit.
-- Control signals to the datapath:  clr_clk, clr_bit, inc_bit, shift_en, load_out.
entity uart_ctrl is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;     -- active high
 
        -- status signals from the datapath
        rx_level   : in  std_logic;     -- synchronized RX line
        half_done  : in  std_logic;     -- half a bit time has passed
        bit_done   : in  std_logic;     -- a full bit time has passed
        last_bit   : in  std_logic;     -- the bit being received is bit 7
 
        -- control signals to the datapath
        clr_clk    : out std_logic;     -- restart the bit-time counter
        clr_bit    : out std_logic;     -- bit index back to 0
        inc_bit    : out std_logic;     -- next bit
        shift_en   : out std_logic;     -- store the sampled bit
        load_out   : out std_logic      -- good frame: release the byte
    );
end uart_ctrl;
 
architecture FSM2 of uart_ctrl is
    type state_t is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
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
    process(state, rx_level, half_done, bit_done, last_bit)
    begin
        -- defaults
        next_state <= state;
        clr_clk    <= '0';
        clr_bit    <= '0';
        inc_bit    <= '0';
        shift_en   <= '0';
        load_out   <= '0';
 
        case state is
            when IDLE =>
                clr_clk <= '1';
                clr_bit <= '1';
                if rx_level = '0' then
                    next_state <= START_BIT;
                end if;
 
            when START_BIT =>
                if half_done = '1' then
                    clr_clk <= '1';
                    if rx_level = '0' then
                        next_state <= DATA_BITS;
                    else
                        next_state <= IDLE;
                    end if;
                end if;
 
            when DATA_BITS =>
                if bit_done = '1' then
                    clr_clk  <= '1';
                    shift_en <= '1';
                    if last_bit = '1' then
                        next_state <= STOP_BIT;
                    else
                        inc_bit <= '1';
                    end if;
                end if;
 
            when STOP_BIT =>
                if bit_done = '1' then
                    clr_clk <= '1';
                    if rx_level = '1' then
                        load_out <= '1';
                    end if;
                    next_state <= IDLE;
                end if;
        end case;
    end process;
 
end FSM2;