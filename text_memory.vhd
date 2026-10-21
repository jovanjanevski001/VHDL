library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity text_memory is
    generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 13 
    );
    port (
        clock        : in  std_logic;
        -- Port A (Write Only)
        wr_en       : in  std_logic;
        wr_address  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Port B (Read Only)
        address     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        q        	: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end text_memory;

architecture RTL of text_memory is
begin

    U_TEXT_RAM : altsyncram
    generic map (
        address_reg_b             => "CLOCK0",      -- Port B addresses clocked by clock0
        clock_enable_input_a      => "BYPASS",
        clock_enable_input_b      => "BYPASS",
        clock_enable_output_b     => "BYPASS",
        intended_device_family    => "MAX 10", 
        lpm_type                  => "altsyncram",
        numwords_a                => 2**ADDR_WIDTH,
        numwords_b                => 2**ADDR_WIDTH,
        operation_mode            => "DUAL_PORT",   -- Simple Dual Port Mode
        outdata_aclr_b            => "NONE",
        outdata_reg_b             => "UNREGISTERED",-- Change to "CLOCK0" for pipelined output (adds 1 cycle latency)
        power_up_uninitialized    => "FALSE",
		ram_block_type         	  => "M9K",
        widthad_a                 => ADDR_WIDTH,
        widthad_b                 => ADDR_WIDTH,
        width_a                   => DATA_WIDTH,
        width_b                   => DATA_WIDTH,
        width_byteena_a           => 1
    )
    port map (
        -- Tie both write (A) and read (B) logic to the same single clock input
        clock0    => clock,
		
        -- Port A (Write)
        wren_a    => wr_en,
        address_a => wr_address,
        data_a    => wr_data,
        
        -- Port B (Read)
        address_b => address,
        q_b       => q
    );

end RTL;