library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UART receiver datapath: the input synchronizer, the bit-time counter, the bit counter, the
-- shift register and the output registers. It does what the controller (uart_ctrl) tells it to
-- and reports back with status signals; it makes no decisions of its own.
--
-- Counters are built from the small reusable parts (reg_en, mux_2x1, adder, comparator_eq):
--     clr = '0' -> count + 1
--     clr = '1' -> clear to 0
entity uart_datapath is
    generic (
        CLOCK_HZ  : positive := 50_000_000;
        BAUD_RATE : positive := 115_200
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        rx         : in  std_logic_vector(0 downto 0);

        -- control signals from the controller
        clr_clk    : in  std_logic;
        clr_bit    : in  std_logic;
        inc_bit    : in  std_logic;
        shift_en   : in  std_logic;
        load_out   : in  std_logic;

        -- status signals to the controller
        rx_level   : out std_logic;
        half_done  : out std_logic;
        bit_done   : out std_logic;
        last_bit   : out std_logic;

        -- results
        data_byte  : out std_logic_vector(7 downto 0);
        data_valid : out std_logic
    );
end uart_datapath;

architecture STR of uart_datapath is

    constant CLKS_PER_BIT : positive := CLOCK_HZ / BAUD_RATE;

    -- number of bits needed to count 0 .. CLKS_PER_BIT-1
    function bits_for(n : positive) return positive is
        variable w : positive := 1;
    begin
        while (2 ** w) < n loop
            w := w + 1;
        end loop;
        return w;
    end function;

    constant CNT_W : positive := bits_for(CLKS_PER_BIT);

    constant CNT_ZERO : std_logic_vector(CNT_W - 1 downto 0) := (others => '0');
    constant CNT_ONE  : std_logic_vector(CNT_W - 1 downto 0) :=
        std_logic_vector(to_unsigned(1, CNT_W));
    constant CNT_HALF : std_logic_vector(CNT_W - 1 downto 0) :=
        std_logic_vector(to_unsigned(CLKS_PER_BIT / 2 - 1, CNT_W));
    constant CNT_FULL : std_logic_vector(CNT_W - 1 downto 0) :=
        std_logic_vector(to_unsigned(CLKS_PER_BIT - 1, CNT_W));

    constant IDX_ZERO : std_logic_vector(2 downto 0) := "000";
    constant IDX_ONE  : std_logic_vector(2 downto 0) := "001";
    constant IDX_LAST : std_logic_vector(2 downto 0) := "111";

    constant ENABLE : std_logic := '1';

    signal rx_sync : std_logic_vector(0 downto 0);

    -- bit-time counter
    signal clk_reg, clk_1, clk_mux : std_logic_vector(CNT_W - 1 downto 0);

    -- bit index
    signal idx_reg, idx_1, idx_mux : std_logic_vector(2 downto 0);
    signal idx_en                  : std_logic;

    -- data registers
    signal shift_reg : std_logic_vector(7 downto 0);
    signal byte_reg  : std_logic_vector(7 downto 0);
    signal valid_reg : std_logic_vector(0 downto 0);
    signal load_vec  : std_logic_vector(0 downto 0);

begin

    ------------------------------------------------------------------ input synchronizer

    U_RX_SYNC : entity work.sync_2ff
        port map ( clk => clk, input => rx, output => rx_sync );

    rx_level <= rx_sync(0);

    ------------------------------------------------------------------ bit-time counter

    U_CLK_INC : entity work.adder
        generic map ( WIDTH => CNT_W )
        port map ( in1 => clk_reg, in2 => CNT_ONE, output => clk_1 );

    U_CLK_MUX : entity work.mux_2x1
        generic map ( WIDTH => CNT_W )
        port map ( in1 => clk_1, in2 => CNT_ZERO, sel => clr_clk, output => clk_mux );

    U_CLK_REG : entity work.reg_en
        generic map ( WIDTH => CNT_W )
        port map ( clk => clk, rst => rst, en => ENABLE, input => clk_mux, output => clk_reg );

    U_HALF_CMP : entity work.comparator_eq
        generic map ( WIDTH => CNT_W )
        port map ( in1 => clk_reg, in2 => CNT_HALF, eq => half_done );

    U_FULL_CMP : entity work.comparator_eq
        generic map ( WIDTH => CNT_W )
        port map ( in1 => clk_reg, in2 => CNT_FULL, eq => bit_done );

    ------------------------------------------------------------------ bit index

    U_IDX_INC : entity work.adder
        generic map ( WIDTH => 3 )
        port map ( in1 => idx_reg, in2 => IDX_ONE, output => idx_1 );

    U_IDX_MUX : entity work.mux_2x1
        generic map ( WIDTH => 3 )
        port map ( in1 => idx_1, in2 => IDX_ZERO, sel => clr_bit, output => idx_mux );

    idx_en <= clr_bit or inc_bit;

    U_IDX_REG : entity work.reg_en
        generic map ( WIDTH => 3 )
        port map ( clk => clk, rst => rst, en => idx_en, input => idx_mux, output => idx_reg );

    U_LAST_CMP : entity work.comparator_eq
        generic map ( WIDTH => 3 )
        port map ( in1 => idx_reg, in2 => IDX_LAST, eq => last_bit );

    ------------------------------------------------------------------ shift register
    -- the sampled bit goes into the position the bit index points at (LSB first)

    process(clk, rst)
    begin
        if rst = '1' then
            shift_reg <= (others => '0');
        elsif rising_edge(clk) then
            if shift_en = '1' then
                shift_reg(to_integer(unsigned(idx_reg))) <= rx_sync(0);
            end if;
        end if;
    end process;

    ------------------------------------------------------------------ output registers

    U_BYTE_REG : entity work.reg_en
        generic map ( WIDTH => 8 )
        port map ( clk => clk, rst => rst, en => load_out, input => shift_reg, output => byte_reg );

    load_vec(0) <= load_out;

    U_VALID_REG : entity work.reg_en
        generic map ( WIDTH => 1 )
        port map ( clk => clk, rst => rst, en => ENABLE, input => load_vec, output => valid_reg );

    data_byte  <= byte_reg;
    data_valid <= valid_reg(0);

end STR;