library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div_tb is

end clk_div_tb;

architecture TB of clk_div_tb is

    component clk_div
        generic(clk_in_freq  : natural;
                clk_out_freq : natural);
        port (
            clk_in  : in  std_logic;
            clk_out : out std_logic;
            rst     : in  std_logic);
    end component;

    signal clk1 : std_logic := '0';
    signal clk2 : std_logic;
    signal rst  : std_logic;

    -- CHANGE THIS TO TEST DIFFERENT CLOCK RATIOS
    constant RATIO : integer := 50000000/1000;

begin  -- TB

    UUT : clk_div
        generic map (
            clk_in_freq  => RATIO,      -- NOTE: This is not how you should
                                        -- instantiate the clk_div in clk_gen.
                                        -- You should specify the actual
                                        -- frequencies 
            clk_out_freq => 1)
        port map (
            clk_in  => clk1,
            clk_out => clk2,
            rst     => rst);

    clk1 <= not clk1 after 10 ns;

    process
    begin

        rst <= '1';

        -- wait for 5 cycles
        for i in 0 to 5 loop
            wait until clk1'event and clk1 = '1';
        end loop;  -- i

        wait for 5 ns;

        rst <= '0';

        wait;

    end process;

end TB;