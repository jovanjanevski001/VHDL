library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
	generic
	(	
		WIDTH : positive := 8
	);
	
	port
	(
		clk		:	in std_logic;
		rst		:	in std_logic;
		n		:	in std_logic_vector(WIDTH-1 downto 0);
		result	:	out std_logic_vector(WIDTH-1 downto 0);
		
		-- signals to/from the datapath/controller
		i_sel		:	in std_logic;
		x_sel		:	in std_logic;
		y_sel		:	in std_logic;
		i_ld		:	in std_logic;
		x_ld		:	in std_logic;
		y_ld		:	in std_logic;
		n_ld		:	in std_logic;
		result_ld	:	in std_logic;
		i_le_n		:	out std_logic
	);
end datapath;

architecture STR of datapath is
	
	constant C_1 : unsigned(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
	constant C_3 : unsigned(WIDTH-1 downto 0) := to_unsigned(3, WIDTH);
	
	signal i_mux_output : std_logic_vector(WIDTH-1 downto 0);
	signal x_mux_output : std_logic_vector(WIDTH-1 downto 0);
	signal y_mux_output : std_logic_vector(WIDTH-1 downto 0);
	
	signal i_reg : std_logic_vector(WIDTH-1 downto 0);
	signal x_reg : std_logic_vector(WIDTH-1 downto 0);
	signal y_reg : std_logic_vector(WIDTH-1 downto 0);
	signal n_reg : std_logic_vector(WIDTH-1 downto 0);
	
	signal i_1 		: std_logic_vector(WIDTH-1 downto 0);	--	i++ signal
	signal x_add_y 	: std_logic_vector(WIDTH-1 downto 0);	--	x+y signal
	
begin
		
	U_I_MUX		:	entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			in1    =>	i_1, -- i++ goes here
			in2	   =>	std_logic_vector(C_3),
			sel    =>	i_sel,
			output =>	i_mux_output
		);
	
	
	U_X_MUX		:	entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			in1    =>	y_reg,
			in2	   =>	std_logic_vector(C_1),
			sel    =>	x_sel,
			output =>	x_mux_output
		);
	
	
	U_Y_MUX		:	entity work.mux_2x1
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			in1    =>	x_add_y, -- x+y goes here
			in2	   =>	std_logic_vector(C_1),
			sel    =>	y_sel,
			output =>	y_mux_output
		);
	
	
	U_I_REG		:	entity work.reg_en
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk	   =>	clk,
			rst	   =>	rst,
			en	   =>	i_ld,
			input  =>	i_mux_output,
			output =>	i_reg
		);
	
	
	U_X_REG		:	entity work.reg_en
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk	   =>	clk,
			rst	   =>	rst,
			en	   =>	x_ld,
			input  =>	x_mux_output,
			output =>	x_reg
		);
	
	
	U_Y_REG		:	entity work.reg_en
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk	   =>	clk,
			rst	   =>	rst,
			en	   =>	y_ld,
			input  =>	y_mux_output,
			output =>	y_reg
		);
	
	
	U_N_REG		:	entity work.reg_en
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk	   =>	clk,
			rst	   =>	rst,
			en	   =>	n_ld,
			input  =>	n,
			output =>	n_reg
		);
	
	
	U_COMPARATOR :	entity work.comparator
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			i		=>	i_reg,
			n		=>	n_reg,
			i_le_n	=>	i_le_n
		);
	
	
	U_ADD_I_1	:	entity work.adder
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	std_logic_vector(C_1),
			in2		=>	i_reg,
			output	=>	i_1
		);
		
		
	U_ADD_X_Y	:	entity work.adder	
		generic map ( WIDTH => WIDTH )
		
		port map
		(
			in1		=>	y_reg,
			in2		=>	x_reg,
			output	=>	x_add_y
		);
		
		
	U_RESULT_REG :	entity work.reg_en
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk	   =>	clk,
			rst	   =>	rst,
			en	   =>	result_ld,
			input  =>	y_reg,
			output =>	result
		);
		
end STR;