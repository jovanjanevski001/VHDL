library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;
 
-- Final stage: forces the colors to black outside the visible area and
-- registers colors and syncs together, so they stay aligned with each other
-- and don't glitch. Adds one pixel of delay to everything equally.
entity vga_out_stage is
    port
    (
        clk     : in  std_logic;
        visible : in  std_logic;
        hsync_i : in  std_logic;
        vsync_i : in  std_logic;
        r_i     : in  color_width_t;
        g_i     : in  color_width_t;
        b_i     : in  color_width_t;
        hsync_o : out std_logic;
        vsync_o : out std_logic;
        r_o     : out color_width_t;
        g_o     : out color_width_t;
        b_o     : out color_width_t
    );
end vga_out_stage;
 
architecture RTL of vga_out_stage is
begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            hsync_o <= hsync_i;
            vsync_o <= vsync_i;
			
            if (visible = '1') then
                r_o <= r_i;
                g_o <= g_i;
                b_o <= b_i;
            else
                r_o <= "0000";
                g_o <= "0000";
                b_o <= "0000";
            end if;
        end if;
    end process;
end RTL;
 