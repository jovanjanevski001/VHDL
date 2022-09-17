library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
	generic 
	(
		WIDTH : positive := 16
	);
	
	port
	(
		-- inputs
		clk	: in std_logic;
		rst	: in std_logic;
		go	: in std_logic;
		x	: in std_logic_vector(WIDTH-1 downto 0);
		y	: in std_logic_vector(WIDTH-1 downto 0);
		
		-- outputs
		done : out std_logic;
		output : out std_logic_vector(WIDTH-1 downto 0)
	);
end gcd;

-- 1-process model implementation of the FSM with datapath operations
architecture FSMD of gcd is
	
	type state_type is (INIT_STATE, LOOP_CONDITION_STATE, ALGORITHM_STATE, DONE_STATE);
	
	signal state : state_type;
	signal regX, regY : unsigned (WIDTH-1 downto 0);
	
begin -- FSMD
	process(clk, rst)
	begin
		if (rst = '1') then
			done <= '0';
			regX <= (others => '0');
			regY <= (others => '0');
			output <= (others => '0');
			state <= INIT_STATE;
			
		elsif (rising_edge(clk)) then
			case state is
				when INIT_STATE =>
					if (go = '1') then
						done <= '0';
						regX <= unsigned(x);
						regY <= unsigned(y);
						
						state <= LOOP_CONDITION_STATE;
					end if;
				
				when LOOP_CONDITION_STATE =>
					if (regX /= regY) then
						state <= ALGORITHM_STATE;
					else
						state <= DONE_STATE;
					end if;
				
				when ALGORITHM_STATE =>
					if (regX < regY) then
						regY <= regY - regX;
					else
						regX <= regX - regY;
					end if;
					
					state <= LOOP_CONDITION_STATE;	--	return to the loop condition check after 1 iteration
					
				when DONE_STATE =>
					output <= std_logic_vector(regX);
					done <= '1';
					
					if (go = '0') then
						state <= INIT_STATE;
					end if;
				
				when others =>
					null;
			end case;
		end if;
	end process;
end FSMD;

-- FSM + Datapath approach to designing the gcd calculator
-- ctrl will handle generating the signals necessary for the datapath to perform its operations
architecture FSM_D1 of gcd is

	signal x_sel  : std_logic;
	signal y_sel  : std_logic;
	signal x_en   : std_logic;
	signal y_en   : std_logic;
	signal out_en : std_logic;
	signal x_lt_y : std_logic;
	signal x_ne_y : std_logic;
	
begin -- FSM_D1
	U_DATAPATH1 : entity work.datapath1
		generic map (WIDTH => WIDTH)
		
		port map
		(
			clk	   	=>	clk,
			rst    	=>	rst,
			x 	   	=>	x,
			y 	   	=>	y,
			output 	=>	output,
			
			x_sel  	=>	x_sel,
			y_sel  	=>	y_sel,
			x_en   	=>	x_en,
			y_en   	=>	y_en,
			out_en 	=>	out_en,
			x_lt_y 	=>	x_lt_y,
			x_ne_y 	=>	x_ne_y
		);
		
	U_CTRL1 : entity work.ctrl1
		generic map (WIDTH => WIDTH)
		
		port map
		(
			clk	   	=>	clk,
			rst    	=>	rst,
			go		=>	go,
			done	=>	done,
			
			x_lt_y 	=>	x_lt_y,
			x_ne_y 	=>	x_ne_y,
			x_sel  	=>	x_sel,
			y_sel  	=>	y_sel,
			x_en   	=>	x_en,
			y_en   	=>	y_en,
			out_en 	=>	out_en
		);
end FSM_D1;

-- Similiar to the FSM_D1 architecture, however the datapath implementation uses only
-- one subtractor instead of two. This alteration saves on resources, but needs an extra
-- control signal to the subtractor to determine which subtraction to perform. For this,
-- we can use the x_lt_y control signal from the comparator to drive a new control signal "sub_sel" 
-- which will be driven by the controller.
architecture FSM_D2 of gcd is
	
	signal x_sel   : std_logic;
	signal y_sel   : std_logic;
	signal x_en    : std_logic;
	signal y_en    : std_logic;
	signal out_en  : std_logic;
	signal sub_sel : std_logic;
	signal x_lt_y  : std_logic;
	signal x_ne_y  : std_logic;
	
begin -- FSM_D2
	
	U_DATAPATH2 : entity work.datapath2
		generic map (WIDTH => WIDTH)
		
		port map
		(
			clk	   	=>	clk,
			rst    	=>	rst,
			x 	   	=>	x,
			y 	   	=>	y,
			output 	=>	output,
			
			x_sel  	=>	x_sel,
			y_sel  	=>	y_sel,
			x_en   	=>	x_en,
			y_en   	=>	y_en,
			out_en 	=>	out_en,
			sub_sel =>	sub_sel,
			x_lt_y 	=>	x_lt_y,
			x_ne_y 	=>	x_ne_y
		);
		
	U_CTRL2 : entity work.ctrl2
		generic map (WIDTH => WIDTH)
		
		port map
		(
			clk	   	=>	clk,
			rst    	=>	rst,
			go		=>	go,
			done	=>	done,
			
			x_lt_y 	=>	x_lt_y,
			x_ne_y 	=>	x_ne_y,
			x_sel  	=>	x_sel,
			y_sel  	=>	y_sel,
			x_en   	=>	x_en,
			y_en   	=>	y_en,
			out_en 	=>	out_en,
			sub_sel =>	sub_sel
		);

end FSM_D2;

-- Similiar to the FSMD, however this architecture uses the 2-process model to implement the gcd calculator
architecture FSMD2 of gcd is
	
	type state_type is (INIT_STATE, LOOP_CONDITION_STATE, ALGORITHM_STATE, DONE_STATE);
	signal state, next_state 		: state_type;
	signal x_reg, y_reg				: unsigned(WIDTH-1 downto 0) := (others => '0');
	signal x_reg_next, y_reg_next 	: unsigned(WIDTH-1 downto 0) := (others => '0');
	
begin
	-- sequential logic
	process(clk, rst)
	begin
		if (rst = '1') then
			state   <=  INIT_STATE;
			x_reg	<=	(others => '0');
			y_reg	<=	(others => '0');
		elsif (rising_edge(clk)) then
			state   <=  next_state;
			x_reg   <=  x_reg_next;
			y_reg   <=  y_reg_next;
		end if;
	end process;
	
	-- combinatorial logic
	process(go, x, y, state, x_reg, y_reg)
	begin
		-- default values
		output <= (others => '0');
		done <= '0';
		x_reg_next <= x_reg;
		y_reg_next <= y_reg;
		next_state <= state;
		
		case state is
			when INIT_STATE =>
				if (go = '1') then
					x_reg_next <= unsigned(x);
					y_reg_next <= unsigned(y);
					next_state <= LOOP_CONDITION_STATE;
				end if;
			when LOOP_CONDITION_STATE =>
				if (x_reg /= y_reg) then
					next_state <= ALGORITHM_STATE;
				else
					next_state <= DONE_STATE;
				end if;
			when ALGORITHM_STATE =>
				if (x_reg < y_reg) then
					y_reg_next <= y_reg - x_reg;
				else
					x_reg_next <= x_reg - y_reg;
				end if;
				
				next_state <= LOOP_CONDITION_STATE;
			when DONE_STATE =>
				output  <=  std_logic_vector(x_reg);
				done    <=	'1';
				
				if (go = '0') then
					next_state <= INIT_STATE;
				end if;
			when others =>
			    null;
		end case;		
	end process;
end FSMD2;