library ieee;
use ieee.std_logic_1164.all;
library altera_mf;
use altera_mf.altera_mf_components.all;
use work.vga_pkg.all;
 
-- The sprite ROM for Quartus: an altsyncram in ROM mode, filled from sprite.mif when the design
-- is compiled and placed in an M9K block. The address is registered inside the memory, so q is
-- valid one clock after address.
--
-- Needs the MAX 10 configuration mode with memory initialization (same as the picture ROM).
-- For simulation use sim/sprite_rom.vhd instead - it has the same entity and reads the same .mif.
entity sprite_rom is
    port
    (
        clock   : in  std_logic;
        address : in  std_logic_vector(SPRITE_ADDR_W-1 downto 0);
        q       : out std_logic_vector(11 downto 0)
    );
end sprite_rom;
 
architecture SYN of sprite_rom is
begin
    U_ROM : altsyncram
        generic map
        (
            address_aclr_a         => "NONE",
            clock_enable_input_a   => "BYPASS",
            clock_enable_output_a  => "BYPASS",
            init_file              => SPRITE_MIF,
            intended_device_family => "MAX 10",
            lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
            lpm_type               => "altsyncram",
            numwords_a             => 2**SPRITE_ADDR_W,
            operation_mode         => "ROM",
            outdata_aclr_a         => "NONE",
            outdata_reg_a          => "UNREGISTERED",
            ram_block_type         => "M9K",
            widthad_a              => SPRITE_ADDR_W,
            width_a                => 12,
            width_byteena_a        => 1
        )
        port map
        (
            address_a => address,
            clock0    => clock,
            q_a       => q
        );
end SYN;
 