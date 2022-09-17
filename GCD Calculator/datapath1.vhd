library ieee;
use ieee.std_logic_1164.all;

entity datapath1 is
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
		x_lt_y : out std_logic;
		x_ne_y : out std_logic
	);
end datapath1;

architecture STR of datapath1 is
	-- x related signals
	signal x_mux_output : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal x_reg 		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal x_reg_sub 	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	
	-- y related signals
	signal y_mux_output : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal y_reg 		: std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal y_reg_sub 	: std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin	-- STR
	
	U_X_MUX : entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	x_reg_sub, -- sub result here
			in2		=>	x,
			sel		=>	x_sel,
			output	=>	x_mux_output
		);
	
	U_Y_MUX : entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	y_reg_sub, -- sub result here
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
	
	
	U_X_SUB : entity work.sub
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1 	=>	x_reg,
			in2 	=>	y_reg,
			output 	=>	x_reg_sub -- feed back into x_mux
		);
	
	
	U_Y_SUB : entity work.sub
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1 	=>	y_reg,
			in2 	=>	x_reg,
			output 	=>	y_reg_sub -- feed back into y_mux
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