library ieee;
use ieee.std_logic_1164.all;
 
-- Accelerometer driver: board-agnostic wrapper, like uart_driver. Takes the raw SPI pins and an
-- active-high reset; runs on the 50 MHz clock. Reads the ADXL345 100 times a second.
--
--   data        X (31..16) & Y (15..0), 16-bit two's complement, +-2 g full resolution (256 per g);
--               held steady for 10 ms between reads
--   data_toggle flips each time data is updated (for a block on another clock to synchronize)
entity accel_driver is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;                      -- active high
 
        spi_cs_n    : out std_logic;
        spi_sclk    : out std_logic;
        spi_mosi    : out std_logic;
        spi_miso    : in  std_logic;
 
        data        : out std_logic_vector(31 downto 0);
        data_toggle : out std_logic
    );
end accel_driver;
 
architecture STR of accel_driver is

    signal start, done                           : std_logic;
    signal tx_byte, rx_byte                      : std_logic_vector(7 downto 0);
    signal poll_tick, gap_tick                   : std_logic;
    signal step_last, step_cap, step_end : std_logic;
    signal clr_gap, inc_idx, ld_loop, cs_set, cs_clr, cap_en, publish : std_logic;
	
begin

    U_SPI : entity work.spi_master
        port map
        (
            clk 	=>	clk, 
			rst 	=>	rst,
			
            start 	=>	start, 
			tx_byte =>	tx_byte, 
			rx_byte =>	rx_byte,
            busy 	=>	open, 
			done 	=>	done,
			
            sclk 	=>	spi_sclk, 
			mosi 	=>	spi_mosi, 
			miso 	=>	spi_miso
        );
 
    U_CTRL : entity work.accel_ctrl
        port map
        (
            clk 		=> 	clk, 
			rst 		=> 	rst,
			
            done 		=> 	done, 
			start 		=> 	start,
			
            poll_tick 	=>	poll_tick, 
			gap_tick 	=>	gap_tick,
            step_last	=>	step_last, 
			step_cap 	=>	step_cap, 
			step_end 	=>	step_end,
			
            clr_gap 	=>	clr_gap,
			inc_idx 	=>	inc_idx, 
			ld_loop 	=>	ld_loop,
            cs_set 		=>	cs_set, 
			cs_clr 		=>	cs_clr,
			cap_en 		=>	cap_en, 
			publish 	=>	publish
        );
 
    U_DATAPATH : entity work.accel_datapath
        port map
        (
            clk 		=>	clk, 
			rst 		=>	rst,
			
            tx_byte 	=>	tx_byte, 
			rx_byte 	=>	rx_byte, 
			cs_n 		=>	spi_cs_n,
			
            data 		=>	data, 
			data_toggle =>	data_toggle,
			
            poll_tick 	=>	poll_tick,
			gap_tick 	=>	gap_tick,
            step_last 	=>	step_last,
			step_cap 	=>	step_cap, 
			step_end 	=>	step_end,
			
            clr_gap 	=>	clr_gap,
			inc_idx 	=>	inc_idx,
			ld_loop 	=>	ld_loop,
            cs_set 		=>	cs_set,
			cs_clr 		=>	cs_clr, 
			cap_en 		=>	cap_en,
			publish 	=>	publish
        );
		
end STR;