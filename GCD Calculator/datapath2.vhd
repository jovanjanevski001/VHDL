library ieee;
use ieee.std_logic_1164.all;

entity datapath2 is
	generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		clk	   : in std_logic;
		rst    : in std_logic;
		x 	   : in std_logic_vector(WIDTH-1 downto 0);
		y 	   : in std_logic_vector(WIDTH-1 downto 0);
		output : out std_logic_vector(WIDTH-1 downto 0);
		
		-- Control signals to/from the datapath/ctrl
		x_sel  : in  std_logic;
		y_sel  : in  std_logic;
		x_en   : in  std_logic;
		y_en   : in  std_logic;
		out_en : in  std_logic;
		sub_sel: in	 std_logic;		--	new input added to remove 1 subtractor from the design
		x_lt_y : out std_logic;
		x_ne_y : out std_logic
	);
end datapath2;

architecture STR of datapath2 is
	-- x related signals
	signal x_mux_output : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal x_reg 		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	
	-- y related signals
	signal y_mux_output : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal y_reg 		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	
	-- sub result is fed to x_mux and y_mux, the controller handles which mux selects the result
	signal sub_result	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin	-- STR
	
	U_X_MUX : entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	sub_result, -- sub result here
			in2		=>	x,
			sel		=>	x_sel,
			output	=>	x_mux_output
		);
	
	U_Y_MUX : entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	sub_result, -- sub result here
			in2		=>	y,
			sel		=>	y_sel,
			output	=>	y_mux_output
		);
	
	U_X_REG : entity work.reg_en
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst,
			en		=>	x_en,
			input	=>	x_mux_output,
			output	=>	x_reg
		);
		
	
	U_Y_REG : entity work.reg_en
		generic map ( 	WIDTH => WIDTH )
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst,
			en		=>	y_en,
			input	=>	y_mux_output,
			output	=>	y_reg
		);
	
	
	U_SUB : entity work.sub_with_sel
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1 	=>	x_reg,
			in2 	=>	y_reg,
			sub_sel =>	sub_sel,
			output 	=>	sub_result -- feed back into muxes
		);
	
	
	U_COMPARATOR : entity work.comparator
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			x 	=>	x_reg,
			y 	=>	y_reg,
			
			x_lt_y	=>	x_lt_y,
			x_ne_y	=>	x_ne_y
		);
		
	U_OUTPUT_REG : entity work.reg_en
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst,
			en		=>	out_en,
			input	=>	x_reg,
			output	=>	output
		);
	
end STR;