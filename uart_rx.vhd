library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity uart_rx is
    generic (
        CLOCK_HZ  : positive := 50_000_000;
        BAUD_RATE : positive := 115_200
    );
    port (
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        rx         : in  std_logic_vector(0 downto 0);
        data_byte  : out std_logic_vector(7 downto 0);
        data_valid : out std_logic
    );
end uart_rx;

--------------- STR: controller + datapath (FSM + D)
architecture STR of uart_rx is
    
	signal rst : std_logic;
 
    -- status (datapath -> controller)
    signal rx_level  : std_logic;
    signal half_done : std_logic;
    signal bit_done  : std_logic;
    signal last_bit  : std_logic;
 
    -- control (controller -> datapath)
    signal clr_clk  : std_logic;
    signal clr_bit  : std_logic;
    signal inc_bit  : std_logic;
    signal shift_en : std_logic;
    signal load_out : std_logic;

begin
    rst <= not reset_n;
 
    U_CTRL : entity work.uart_ctrl
        port map
        (
            clk       => clk,
            rst       => rst,
            rx_level  => rx_level,
            half_done => half_done,
            bit_done  => bit_done,
            last_bit  => last_bit,
            clr_clk   => clr_clk,
            clr_bit   => clr_bit,
            inc_bit   => inc_bit,
            shift_en  => shift_en,
            load_out  => load_out
        );
 
    U_DATAPATH : entity work.uart_datapath
        generic map ( CLOCK_HZ => CLOCK_HZ, BAUD_RATE => BAUD_RATE )
        port map
        (
            clk        => clk,
            rst        => rst,
            rx         => rx,
            clr_clk    => clr_clk,
            clr_bit    => clr_bit,
            inc_bit    => inc_bit,
            shift_en   => shift_en,
            load_out   => load_out,
            rx_level   => rx_level,
            half_done  => half_done,
            bit_done   => bit_done,
            last_bit   => last_bit,
            data_byte  => data_byte,
            data_valid => data_valid
        );
end STR;