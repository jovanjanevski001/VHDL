library ieee;
use ieee.std_logic_1164.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
use work.vga_pkg.all;
 
-- The picture ROM for Quartus: an altsyncram in ROM mode, filled from image.mif when the
-- design is compiled. It is placed in M9K memory blocks explicitly (ram_block_type), so it
-- cannot end up as logic cells. The address is registered inside the
-- memory, so q is valid one clock after address (latency 1 = PIXEL_LATENCY).
--
-- Add image.mif to the project (or keep it in the project folder). For simulation use
-- sim/image_rom.vhd instead of this file - it has the same entity and reads the same .mif.
entity image_rom is
	port
	(
		clock	: in  std_logic;
		address	: in  std_logic_vector(IMG_ADDR_W-1 downto 0);
		q		: out std_logic_vector(11 downto 0)
	);
end image_rom;
 
architecture SYN of image_rom is
	signal rom_q : std_logic_vector(11 downto 0);
begin
	U_IMAGE_ROM : altsyncram
		generic map
		(
			address_aclr_a         => "NONE",
			clock_enable_input_a   => "BYPASS",
			clock_enable_output_a  => "BYPASS",
			init_file              => IMAGE_MIF,
			intended_device_family => "MAX 10",
			lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
			lpm_type               => "altsyncram",
			numwords_a             => IMG_W*IMG_H,
			operation_mode         => "ROM",
			outdata_aclr_a         => "NONE",
			outdata_reg_a          => "UNREGISTERED",
			ram_block_type         => "M9K",
			widthad_a              => IMG_ADDR_W,
			width_a                => 12,
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