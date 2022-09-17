library ieee;
use ieee.std_logic_1164.all;

entity ctrl2 is 
	generic ( WIDTH : positive := 8);
	
	port
	(
		clk  : in std_logic;
		rst  : in std_logic;
		go   : in std_logic;
		done : out std_logic;
		
		-- Control flow signals to/from the datapath/ctrl
		x_lt_y  : in std_logic;
		x_ne_y  : in std_logic;
		
		x_sel 	: out std_logic;
		y_sel 	: out std_logic;
		x_en  	: out std_logic;
		y_en  	: out std_logic;
		sub_sel : out std_logic;	--	new control signal added to remove 1 subtractor from the design
		out_en	: out std_logic
	);
end ctrl2;

-- dataflow architecture, this controller will drive the datapath via control signals.
architecture BHV of ctrl2 is
	
	type state_type is (INIT_STATE, LOOP_CONDITION_STATE, ALGORITHM_STATE, DONE_STATE);
	signal state, next_state : state_type;
	
begin	-- BHV

	-- sequential logic
	process(clk, rst)
	begin
		if (rst = '1') then
			state <= INIT_STATE;
		elsif (rising_edge(clk)) then
			state <= next_state;
		end if;
	end process;
	
	-- combinatorial logic
	process(go, x_lt_y, x_ne_y, state)
	begin
		-- default values go here
		done    <= '0';	--	***** might need a next_done signal to sync properly *****
		x_sel   <= '1';	--	selects x input
		y_sel   <= '1';	--	selects y input
		x_en    <= '0';	--	turns off x_reg
		y_en    <= '0';	--	turns off y_reg
		out_en  <= '0';	--	turns off out_reg
		sub_sel <= '0';
		next_state <= state;
		
		case state is
			when INIT_STATE =>
				if (go = '1') then
					-- x_sel and y_sel already 1 by default, dont need to enable them
					x_en <= '1';	-- save x input
					y_en <= '1';	-- save y input
					
					next_state <= LOOP_CONDITION_STATE;
				end if;
			
			when LOOP_CONDITION_STATE =>
				if (x_ne_y = '1') then
					next_state <= ALGORITHM_STATE;
				else
					out_en <= '1';	--	GCD calculator finished, store output from x_reg
					next_state <= DONE_STATE;
				end if;
				
			when ALGORITHM_STATE =>
				if (x_lt_y = '1') then
					sub_sel <= '1'; -- selects y_reg - x_reg from sub_with_sel entity
					y_en  <= '1';	--	y_reg = y_reg - x_reg
					y_sel <= '0';	-- select new y result from y_mux for the next iteration of the loop 
					
					next_state <= LOOP_CONDITION_STATE;
				else
					sub_sel <= '0'; -- selects x_reg - y_reg from sub_with_sel entity
					x_en  <= '1';	--	x_reg = x_reg - y_reg
					x_sel <= '0';	-- select new x result from x_mux for the next iteration of the loop
					
					next_state <= LOOP_CONDITION_STATE;
				end if;
			
			when DONE_STATE =>
				done <= '1';	--	assert done to let user know circuit is finished
				
				if (go = '0') then		--	wait in DONE_STATE until go is cleared
					next_state <= INIT_STATE;
				end if;
			
			when others =>
				null;
		end case;
	end process;
end BHV;