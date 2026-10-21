library ieee;
use ieee.std_logic_1164.all;
 
-- Accelerometer reader controller: the FSM only. It walks the byte table (accel_steps),
-- one byte at a time through the SPI master, and decides when chip select goes low and high.
--
--   WAIT_POLL wait for the poll timer (every 10 ms)
--   SETUP     chip select goes low, wait a moment before the first clock
--   SEND      start the SPI master on the current byte
--   RUN       wait for the byte to finish; keep it if it is data; next byte, or end the transaction
--   GAP       chip select is high, wait a moment; then the next transaction, or the end of the pass
--
-- Status signals from the datapath: poll_tick, gap_tick, step_last, step_cap, step_end.
-- Control signals to the datapath:  clr_gap, inc_idx, ld_loop, cs_set, cs_clr, cap_en, publish.
entity accel_ctrl is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;     -- active high
 
        -- from the SPI master
        done      : in  std_logic;     -- byte finished
        start     : out std_logic;     -- send the current byte
 
        -- status signals from the datapath
        poll_tick : in  std_logic;
        gap_tick  : in  std_logic;
        step_last : in  std_logic;
        step_cap  : in  std_logic;
        step_end  : in  std_logic;
 
        -- control signals to the datapath
        clr_gap   : out std_logic;     -- restart the gap timer
        inc_idx   : out std_logic;     -- next row of the table
        ld_loop   : out std_logic;     -- back to the first row of the read transaction
        cs_set    : out std_logic;     -- chip select low
        cs_clr    : out std_logic;     -- chip select high
        cap_en    : out std_logic;     -- store the byte as X / Y data
        publish   : out std_logic      -- new X / Y ready: hand them out
    );
end accel_ctrl;
 
architecture FSM2 of accel_ctrl is
    type state_t is (WAIT_POLL, SETUP, SEND, RUN, GAP);
    signal state, next_state : state_t;
begin
 
    ------------------------------------------------------------------ state register
    process(clk, rst)
    begin
        if rst = '1' then
            state <= WAIT_POLL;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
 
    ------------------------------------------------------------------ next state / control
    process(state, done, poll_tick, gap_tick, step_last, step_cap, step_end)
    begin
        -- defaults
        next_state <= state;
        start      <= '0';
        clr_gap    <= '1';
        inc_idx    <= '0';
        ld_loop    <= '0';
        cs_set     <= '0';
        cs_clr     <= '0';
        cap_en     <= '0';
        publish    <= '0';
 
        case state is
            when WAIT_POLL =>
                if poll_tick = '1' then
                    next_state <= SETUP;
                end if;
 
            when SETUP =>
                clr_gap <= '0';
                cs_set  <= '1';
                if gap_tick = '1' then
                    next_state <= SEND;
                end if;
 
            when SEND =>
                start      <= '1';
                next_state <= RUN;
 
            when RUN =>
                if done = '1' then
                    cap_en <= step_cap;

                    if step_last = '1' then
                        cs_clr     <= '1';
                        next_state <= GAP;
                    else
                        inc_idx    <= '1';
                        next_state <= SEND;
                    end if;
                end if;
 
            when GAP =>
                clr_gap <= '0';
                if gap_tick = '1' then
                    if step_end = '1' then
                        publish    <= '1';
                        ld_loop    <= '1';
                        next_state <= WAIT_POLL;
                    else
                        inc_idx    <= '1';
                        next_state <= SETUP;
                    end if;
                end if;
        end case;
    end process;
 
end FSM2;