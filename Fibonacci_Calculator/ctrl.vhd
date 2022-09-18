library ieee;
use ieee.std_logic_1164.all;

entity ctrl is 
	generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		clk		:	in	std_logic;
		rst		:	in	std_logic;
		go		:	in	std_logic;
		done	:	out	std_logic;
		
		-- control flow signals to/from the datapath/controller
		i_le_n		:	in std_logic;
		i_sel		:	out std_logic;
		x_sel		:	out std_logic;
		y_sel		:	out std_logic;
		i_ld		:	out std_logic;
		x_ld		:	out std_logic;
		y_ld		:	out std_logic;
		n_ld		:	out std_logic;
		result_ld	:	out std_logic	
	);
end ctrl;

architecture BHV of ctrl is

	type state_type is (INIT_STATE, ALGORITHM_STATE, DONE_STATE);
	signal state, next_state : state_type;

begin
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
	process(state, go, i_le_n)
	begin
		-- default values for the control flow signals
		i_sel		<= '0';		
		x_sel		<= '0';		
		y_sel 		<= '0';		
		i_ld  		<= '0';
		x_ld		<= '0';
		y_ld		<= '0';
		n_ld		<= '0';
		result_ld	<= '0';
		
		done  		<= '0';
		next_state  <= state;
		
		case state is
			when INIT_STATE =>
				if (go = '1') then
					i_sel <= '1';	-- i = 3	
					x_sel <= '1';	-- x = 1
					y_sel <= '1';	-- y = 1
					n_ld <= '1';	-- n_reg = n
					i_ld <= '1';	-- i_reg = 3
					x_ld <= '1';	-- x_reg = 1
					y_ld <= '1';	-- y_reg = 1
					
					next_state <= ALGORITHM_STATE;
				end if;
			when ALGORITHM_STATE =>
				if (i_le_n = '1') then
					-- muxes sel lines should all be '0', but we set them to 0 by default
					i_ld <= '1';	--	i++
					x_ld <= '1';	--	x = y_reg
					y_ld <= '1';	--	y = x + y
					
				else
					result_ld <= '1';	--	result = y_reg
					next_state <= DONE_STATE;
				end if;
			when DONE_STATE =>
				done <= '1';
				
				if (go = '0') then		--	wait for go to be cleared before restarting the circuit
					next_state <= INIT_STATE;
				end if;
			when others =>
				null;
		end case;
	end process;
end BHV;