library ieee;
use ieee.std_logic_1164.all;
 
-- Pixel clock from the MAX 10 PLL, plus a reset that is safe in the pixel domain.
--
-- vga_pll is the ALTPLL IP generated in Quartus (inclk0 = 50 MHz, c0 = PIXEL_CLK_HZ,
-- with the 'locked' output). For simulation, sim/vga_pll.vhd provides a behavioral
-- model with the same ports - never put both in the same Quartus project.
--
-- pix_rst is held while the board reset is pressed or the PLL is not locked, and
-- is released synchronously to pix_clk (2-flop synchronizer).
entity pixel_clk_gen is
	port
	(
		clk		: in  std_logic;	-- 50 MHz board clock
		rst		: in  std_logic;	-- active high, asynchronous
		pix_clk	: out std_logic;
		pix_rst	: out std_logic		-- active high, synchronous to pix_clk
	);
end pixel_clk_gen;
 
architecture STR of pixel_clk_gen is
	signal pll_clk : std_logic;
	signal locked  : std_logic;
	signal arst    : std_logic;
	signal sync    : std_logic_vector(1 downto 0);
begin
	U_PLL : entity work.vga_pll
		port map ( inclk0 => clk, c0 => pll_clk, locked => locked );
	
	arst <= rst or not locked;
	
	process(pll_clk, arst)
	begin
		if (arst = '1') then
			sync <= "11";
		elsif (rising_edge(pll_clk)) then
			sync(0) <= '0';
			sync(1) <= sync(0);
		end if;
	end process;
	
	pix_clk <= pll_clk;
	pix_rst <= sync(1);
end STR;