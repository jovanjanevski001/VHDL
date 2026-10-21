library ieee;
use ieee.std_logic_1164.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
use work.vga_pkg.all;
 
-- The picture ROM for Quartus: an altsyncram in ROM mode, filled from ascii_96_8x8.mif when the
-- design is compiled. It is placed in M9K memory blocks explicitly (ram_block_type), so it
-- cannot end up as logic cells. The address is registered inside the
-- memory, so q is valid one clock after address (latency 1 = PIXEL_LATENCY).
entity font_rom is
	port
	(
		clock	: in  std_logic;
		address	: in  std_logic_vector(6 downto 0);
		q		: out std_logic_vector(63 downto 0)
	);
end font_rom;
 
architecture SYN of font_rom is
	signal rom_q : std_logic_vector(63 downto 0);
begin
	U_FONT_ROM : altsyncram
		generic map
		(
			address_aclr_a         => "NONE",
			clock_enable_input_a   => "BYPASS",
			clock_enable_output_a  => "BYPASS",
			init_file              => "ascii_96_8x8.mif",
			intended_device_family => "MAX 10",
			lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
			lpm_type               => "altsyncram",
			numwords_a             => 96,
			operation_mode         => "ROM",
			outdata_aclr_a         => "NONE",
			outdata_reg_a          => "UNREGISTERED",
			ram_block_type         => "M9K",
			widthad_a              => 7,
			width_a                => 64,
			width_byteena_a        => 1
		)
		port map
		(
			address_a => address,
			clock0    => clock,
			q_a       => rom_q
		);
	
	q <= rom_q;
end SYN;