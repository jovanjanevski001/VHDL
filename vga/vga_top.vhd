library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;

-- Board-level connections top level (DE10-Lite).
entity vga_top is
    port
    (
        clk       : in std_logic;                        -- 50 MHz
        button    : in std_logic_vector(1 downto 0);     -- active low
        switch    : in std_logic_vector(5 downto 0);     -- physical switches

        uart_rx_pin : in std_logic;

        leds      : out std_logic_vector(9 downto 0);

        vga_r     : out color_width_t;
        vga_g     : out color_width_t;
        vga_b     : out color_width_t;
        vga_hs    : out std_logic;
        vga_vs    : out std_logic;

        gs_cs_n   : out std_logic;                       -- accelerometer chip select
        gs_sclk   : out std_logic;
        gs_sdi    : out std_logic;                       -- to chip SDI / MOSI
        gs_sdo    : in  std_logic                        -- from chip SDO / MISO
    );
end vga_top;


architecture STR of vga_top is

    signal rst : std_logic;

    signal uart_data   : std_logic_vector(7 downto 0);
    signal uart_toggle : std_logic;

    signal tilt_data   : std_logic_vector(31 downto 0);
    signal tilt_toggle : std_logic;

begin

    rst <= not button(0);		-- DE10-Lite buttons are active low.


    --------------------------------------------------------------------
    -- VGA Driver
    --------------------------------------------------------------------

    U_VGA : entity work.vga_driver
        port map
        (
            clk         => clk,
            rst         => rst,

            rx_data     => uart_data,
            rx_toggle   => uart_toggle,

            tilt_data   => tilt_data,
            tilt_toggle => tilt_toggle,

            r           => vga_r,
            g           => vga_g,
            b           => vga_b,

            hsync       => vga_hs,
            vsync       => vga_vs
        );


    --------------------------------------------------------------------
    -- UART receiver
    --------------------------------------------------------------------

    U_UART : entity work.uart_driver
        port map
        (
            clk         => clk,
            rst         => rst,

            rx_pin      => uart_rx_pin,

            data_byte   => uart_data,
            data_toggle => uart_toggle
        );


    --------------------------------------------------------------------
    -- Accelerometer
    --------------------------------------------------------------------

    U_ACCEL : entity work.accel_driver
        port map
        (
            clk         => clk,
            rst         => rst,

            spi_cs_n    => gs_cs_n,
            spi_sclk    => gs_sclk,
            spi_mosi    => gs_sdi,
            spi_miso    => gs_sdo,

            data        => tilt_data,
            data_toggle => tilt_toggle
        );


	leds(9)          <= uart_toggle;
	leds(8)			 <= '0';
    leds(7 downto 0) <= uart_data;

end STR;