library ieee;
use ieee.std_logic_1164.all;

entity FSM is
	port
	(
		clk		:	in	std_logic;
		rst		:	in	std_logic;
		en		:	in	std_logic;		
		output	:	out	std_logic_vector(3 downto 0)
	);          
end FSM;

---------------------------------------------
---------------------------------------------
-- 		1 Process model example		       --
---------------------------------------------
---------------------------------------------
architecture PROC1 of FSM is

	type state_type is (STATE_0, STATE_1, STATE_2, STATE_3);
	signal state : state_type;

begin
	
	process(clk, rst)
	begin
		if (rst = '1') then
			output <= "0001";
			state <= STATE_0;
			
		elsif (rising_edge(clk)) then
			case state is 
				
				when STATE_0 =>
					output <= "0001";
					if (en = '1') then
						state <= STATE_1;
					else
						state <= STATE_0;
					end if;
					
				when STATE_1 =>
					output <= "0010";
					if (en = '1') then
						state <= STATE_2;
					else
						state <= STATE_1;
					end if;
					
				when STATE_2 =>
					output <= "0100";
					if (en = '1') then
						state <= STATE_3;
					else
						state <= STATE_2;
					end if;
					
				when STATE_3 =>
					output <= "1000";
					if (en = '1') then
						state <= STATE_0;
					else
						state <= STATE_3;
					end if;
					
				when others =>
					null;
			end case;
		end if;
	end process;
end PROC1;


---------------------------------------------
---------------------------------------------
-- 		2 Process model example		       --
---------------------------------------------
---------------------------------------------
architecture PROC2 of FSM is

	type state_type is (STATE_0, STATE_1, STATE_2, STATE_3);
	signal state, next_state : state_type;	

begin
	
	process(clk, rst) 
	begin
		if (rst = '1') then
			state <= STATE_0;
		elsif (rising_edge(clk)) then 
			state <= next_state;
		end if;
	end process;
	
	process(en, state)
	begin
		--	if en = '0', then we stay in our current state & default value given to avoid any latches
		next_state <= state;		
		
		case state is
			when STATE_0 =>
				output <= "0001";
				
				if (en = '1') then
					next_state <= STATE_1;
				end if;
				
			when STATE_1 =>
				output <= "0010";
				
				if (en = '1') then
					next_state <= STATE_2;
				end if;
			
			when STATE_2 =>
				output <= "0100";
				
				if (en = '1') then
					next_state <= STATE_3;
				end if;
			
			when STATE_3 =>
				output <= "1000";
				
				if (en = '1') then
					next_state <= STATE_0;
				end if;
			
			when others =>
				null;
		end case;
	end process;
end PROC2;