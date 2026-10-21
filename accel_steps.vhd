library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- The ADXL345 conversation as a table of bytes, one row per byte, read by step number (idx).
-- A transaction is a run of rows that ends at a row with last = '1' (chip select goes high there).
--
--   idx  byte sent                     what it does
--    0   read DEVID                    first byte of "read the device ID"
--    1   (dummy)                       the ID comes back here   -> id
--    2   POWER_CTL                     first byte of "start measuring"
--    3   MEASURE
--    4   DATA_FORMAT                   first byte of "full resolution, +-2 g"
--    5   FULL_RES
--    6   read DATAX0, several bytes     first byte of "read X and Y"   <- ACCEL_LOOP_START
--    7   (dummy)  X low                -> cap
--    8   (dummy)  X high               -> cap
--    9   (dummy)  Y low                -> cap
--   10   (dummy)  Y high               -> cap, last, seq_end
--
-- seq_end marks the end of one pass; after it the reader waits for the next poll and starts
-- again at ACCEL_LOOP_START (so the setup rows 0..5 run only once, after reset).
entity accel_steps is
    port (
        idx      : in  std_logic_vector(3 downto 0);
        tx_byte  : out std_logic_vector(7 downto 0);
        last     : out std_logic;     -- end of a transaction after this byte
        cap      : out std_logic;     -- the byte that comes back is X / Y data
        seq_end  : out std_logic      -- end of a pass
    );
end accel_steps;
 
architecture BHV of accel_steps is
    constant DUMMY : std_logic_vector(7 downto 0) := x"00";
begin
    process(idx)
    begin
        tx_byte <= DUMMY;
        last    <= '0';
        cap     <= '0';
        seq_end <= '0';
 
        case to_integer(unsigned(idx)) is
            when 0 =>
                tx_byte <= ADXL_READ or ADXL_REG_DEVID;
            when 1 =>
                last    <= '1';
            when 2 =>
                tx_byte <= ADXL_REG_POWER_CTL;
            when 3 =>
                tx_byte <= ADXL_MEASURE;
                last    <= '1';
            when 4 =>
                tx_byte <= ADXL_REG_DATA_FORMAT;
            when 5 =>
                tx_byte <= ADXL_FULL_RES;
                last    <= '1';
            when 6 =>
                tx_byte <= ADXL_READ or ADXL_MULTI or ADXL_REG_DATAX0;
            when 7 | 8 | 9 =>
                cap     <= '1';
            when 10 =>
                cap     <= '1';
                last    <= '1';
                seq_end <= '1';
            when others =>			-- never reached; end the pass if it ever were
                last    <= '1';
                seq_end <= '1';
        end case;
    end process;
end BHV;