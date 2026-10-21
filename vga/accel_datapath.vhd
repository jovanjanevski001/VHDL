library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- Accelerometer reader datapath: table row counter, poll and gap timers, chip select,
-- the byte capture registers and the output register with its toggle.
--
-- data = X (31..16) & Y (15..0), each a 16-bit two's-complement value. It only changes when a
-- whole read is complete, and data_toggle flips each time, so a block on another clock can
-- synchronize the toggle and then read data (the same idea as uart_driver's data_toggle).
entity accel_datapath is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;     -- active high
 
        -- SPI master side
        tx_byte   : out std_logic_vector(7 downto 0);
        rx_byte   : in  std_logic_vector(7 downto 0);
        cs_n      : out std_logic;
 
        -- results
        data        : out std_logic_vector(31 downto 0);
        data_toggle : out std_logic;
 
        -- status signals to the controller
        poll_tick : out std_logic;
        gap_tick  : out std_logic;
        step_last : out std_logic;
        step_cap  : out std_logic;
        step_end  : out std_logic;
 
        -- control signals from the controller
        clr_gap   : in  std_logic;
        inc_idx   : in  std_logic;
        ld_loop   : in  std_logic;
        cs_set    : in  std_logic;
        cs_clr    : in  std_logic;
        cap_en    : in  std_logic;
        publish   : in  std_logic
    );
end accel_datapath;
 
architecture STR of accel_datapath is
    
    constant NO_CLEAR : std_logic := '0';
    constant C_ONE4   : std_logic_vector(3 downto 0) := "0001";
    constant C_LOOP   : std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(ACCEL_LOOP_START, 4));
 
    -- row counter
    signal idx, idx_1, idx_nxt : std_logic_vector(3 downto 0);
    signal idx_en              : std_logic;
 
    -- chip select (1 = selected)
    signal cs_in, cs_reg : std_logic_vector(0 downto 0);
    signal cs_en         : std_logic;
 
    -- captured bytes: the newest in b0, the oldest in b3
    signal b0, b1, b2, b3 : std_logic_vector(7 downto 0);
 
    -- output toggle
    signal tog_in, tog_reg : std_logic_vector(0 downto 0);
 
    signal word : std_logic_vector(31 downto 0);
	
begin
 
    ------------------------------------------------------------------ row counter
    U_IDX_INC : entity work.adder
        generic map ( WIDTH => 4 )
        port map ( in1 => idx, in2 => C_ONE4, output => idx_1 );
 
    U_IDX_SEL : entity work.mux_2x1
        generic map ( WIDTH => 4 )
        port map ( in1 => idx_1, in2 => C_LOOP, sel => ld_loop, output => idx_nxt );
 
    idx_en <= inc_idx or ld_loop;
 
    U_IDX_REG : entity work.reg_en
        generic map ( WIDTH => 4 )
        port map ( clk => clk, rst => rst, en => idx_en, input => idx_nxt, output => idx );
 
    U_STEPS : entity work.accel_steps
        port map
        (
            idx => idx, tx_byte => tx_byte,
            last => step_last, cap => step_cap, seq_end => step_end
        );
 
    ------------------------------------------------------------------ timers
    U_POLL : entity work.period_counter
        generic map ( PERIOD => ACCEL_POLL_CLKS )
        port map ( clk => clk, rst => rst, clr => NO_CLEAR, tick => poll_tick );
 
    -- the same length as half an SPI bit: far longer than the chip needs between chip select edges
    U_GAP : entity work.period_counter
        generic map ( PERIOD => SPI_HALF_CLKS )
        port map ( clk => clk, rst => rst, clr => clr_gap, tick => gap_tick );
 
    ------------------------------------------------------------------ chip select
    cs_in(0) <= cs_set;
    cs_en    <= cs_set or cs_clr;
 
    U_CS : entity work.reg_en
        generic map ( WIDTH => 1 )
        port map ( clk => clk, rst => rst, en => cs_en, input => cs_in, output => cs_reg );
 
    cs_n <= not cs_reg(0);		-- idles high (the register resets to 0)
 
    ------------------------------------------------------------------ captured bytes
    U_B0 : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => cap_en, input => rx_byte, output => b0 );
 
    U_B1 : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => cap_en, input => b0, output => b1 );
 
    U_B2 : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => cap_en, input => b1, output => b2 );
 
    U_B3 : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => cap_en, input => b2, output => b3 );
 
    -- bytes arrive X low, X high, Y low, Y high
    word <= (b2 & b3) & (b0 & b1);
 
    ------------------------------------------------------------------ output register and toggle
    U_OUT : entity work.reg_en
        generic map ( WIDTH => 32 )
        port map ( clk => clk, rst => rst, en => publish, input => word, output => data );
 
    tog_in(0) <= not tog_reg(0);
 
    U_TOG : entity work.reg_en
        generic map ( WIDTH => 1 )
        port map ( clk => clk, rst => rst, en => publish, input => tog_in, output => tog_reg );
 
    data_toggle <= tog_reg(0);
 
end STR;