library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;

-- The VGA driver proper: everything except the board connections.
-- Structural only. All configuration (video mode, pixel clock divide,
-- border thickness, bus widths) comes from vga_pkg.
entity vga_driver is
    port
    (
        clk         : in  std_logic;
        rst         : in  std_logic;        -- active high

        rx_data     : in  std_logic_vector(7 downto 0);
        rx_toggle   : in  std_logic;

        tilt_data   : in  std_logic_vector(31 downto 0);
        tilt_toggle : in  std_logic;

        r     : out color_width_t;
        g     : out color_width_t;
        b     : out color_width_t;
        hsync : out std_logic;
        vsync : out std_logic
    );
end vga_driver;


architecture STR of vga_driver is

    signal pix_clk, pix_rst : std_logic;

    -- controller <-> datapath
    signal h_ld, h_clr, v_ld, v_clr : std_logic;

    signal h_at_vis_end   : std_logic;
    signal h_at_front_end : std_logic;
    signal h_at_sync_end  : std_logic;
    signal h_at_last      : std_logic;

    signal v_at_vis_end   : std_logic;
    signal v_at_front_end : std_logic;
    signal v_at_sync_end  : std_logic;
    signal v_at_last      : std_logic;

    -- video path
    signal visible, hs, vs, frame_tick : std_logic;
    signal visible_delay, hs_delay, vs_delay : std_logic;

    signal ctl_in, ctl_out : std_logic_vector(2 downto 0);

    signal x, y : coor_width_t;

    signal pr, pg, pb : color_width_t;

begin

    ------------------------------------------------------
    -- Pixel clock
    ------------------------------------------------------

    U_PIXCLK : entity work.pixel_clk_gen
        port map
        (
            clk     => clk,
            rst     => rst,
            pix_clk => pix_clk,
            pix_rst => pix_rst
        );


    ------------------------------------------------------
    -- VGA timing controller
    ------------------------------------------------------

    U_CTRL : entity work.vga_ctrl
        port map
        (
            clk => pix_clk,
            rst => pix_rst,

            h_at_vis_end   => h_at_vis_end,
            h_at_front_end => h_at_front_end,
            h_at_sync_end  => h_at_sync_end,
            h_at_end       => h_at_last,

            v_at_vis_end   => v_at_vis_end,
            v_at_front_end => v_at_front_end,
            v_at_sync_end  => v_at_sync_end,
            v_at_end       => v_at_last,

            h_reg_ld  => h_ld,
            h_mux_sel => h_clr,
            v_reg_ld  => v_ld,
            v_mux_sel => v_clr,

            h_sync   => hs,
            v_sync   => vs,
            visible  => visible,
            frame_tick => frame_tick
        );


    ------------------------------------------------------
    -- VGA datapath coordinate generator
    ------------------------------------------------------

    U_DATAPATH : entity work.vga_datapath
        port map
        (
            clk => pix_clk,
            rst => pix_rst,

            x => x,
            y => y,

            h_ld      => h_ld,
            h_mux_sel => h_clr,
            v_ld      => v_ld,
            v_mux_sel => v_clr,

            h_at_vis_end   => h_at_vis_end,
            h_at_front_end => h_at_front_end,
            h_at_sync_end  => h_at_sync_end,
            h_at_end       => h_at_last,

            v_at_vis_end   => v_at_vis_end,
            v_at_front_end => v_at_front_end,
            v_at_sync_end  => v_at_sync_end,
            v_at_end       => v_at_last
        );


    ------------------------------------------------------
    -- Pattern generator / selector
    --
    -- Menu navigation is now handled inside vga_patterns
    -- from the UART rx_data / rx_toggle stream.
    --
    -- No SW5 menu switch.
    -- No KEY1 menu button.
    ------------------------------------------------------

    U_PATTERNS : entity work.vga_patterns
        port map
        (
            clk        => pix_clk,
            rst        => pix_rst,

            x          => x,
            y          => y,

            frame_tick => frame_tick,

            rx_data    => rx_data,
            rx_toggle  => rx_toggle,

            tilt_data   => tilt_data,
            tilt_toggle => tilt_toggle,

            r => pr,
            g => pg,
            b => pb
        );


    ------------------------------------------------------
    -- Delay sync/control signals to match pixel pipeline
    ------------------------------------------------------

    -- hsync, vsync and visible get the same delay as the pixels
    ctl_in <= hs & vs & visible;


    U_CTL_DLY : entity work.delay_line
        generic map
        (
            WIDTH  => 3,
            STAGES => PIXEL_LATENCY
        )
        port map
        (
            clk   => pix_clk,
            input => ctl_in,
            output => ctl_out
        );


    visible_delay <= ctl_out(0);
    hs_delay      <= ctl_out(2);
    vs_delay      <= ctl_out(1);


    ------------------------------------------------------
    -- VGA color output
    ------------------------------------------------------

    U_OUT : entity work.vga_out_stage
        port map
        (
            clk      => pix_clk,
            visible  => visible_delay,
            hsync_i  => hs_delay,
            vsync_i  => vs_delay,

            r_i => pr,
            g_i => pg,
            b_i => pb,

            hsync_o => hsync,
            vsync_o => vsync,

            r_o => r,
            g_o => g,
            b_o => b
        );

end STR;