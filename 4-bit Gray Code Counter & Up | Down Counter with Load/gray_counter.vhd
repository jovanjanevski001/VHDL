library ieee;
use ieee.std_logic_1164.all;

entity gray_counter is
    port 
	(
        clk    : in  std_logic;
        rst    : in  std_logic;
        output : out std_logic_vector(3 downto 0)
	);
end gray_counter;

-- gray counter implemented using the 2 process model 
architecture BHV of gray_counter is
	type state_type is (STATE_0, STATE_1, STATE_2, STATE_3,
						STATE_4, STATE_5, STATE_6, STATE_7,
						STATE_8, STATE_9, STATE_10, STATE_11,
						STATE_12, STATE_13, STATE_14, STATE_15);
						
	signal state, next_state : state_type;
begin
	process(clk, rst)	--	sequential logic
	begin
		if (rst = '1') then
			state <= STATE_0;
		elsif (rising_edge(clk)) then
			state <= next_state;
		end if;
	end process;
	
	process(state)		--	combinatorial logic
	begin
		output <= "0000";	--	default value to avoid latches
		
		case state is
			when STATE_0 =>
				output <= "0000";
				next_state <= STATE_1;
				
			when STATE_1 =>
				output <= "0001";
				next_state <= STATE_2;
			
			when STATE_2 =>
				output <= "0011";
				next_state <= STATE_3;
			
			when STATE_3 =>
				output <= "0010";
				next_state <= STATE_4;
			
			when STATE_4 =>
				output <= "0110";
				next_state <= STATE_5;
			
			when STATE_5 =>
				output <= "0111";
				next_state <= STATE_6;
			
			when STATE_6 =>
				output <= "0101";
				next_state <= STATE_7;
			
			when STATE_7 =>
				output <= "0100";
				next_state <= STATE_8;
			
			when STATE_8 =>
				output <= "1100";
				next_state <= STATE_9;
			
			when STATE_9 =>
				output <= "1101";
				next_state <= STATE_10;
			
			when STATE_10 =>
				output <= "1111";
				next_state <= STATE_11;
			
			when STATE_11 =>
				output <= "1110";
				next_state <= STATE_12;
			
			when STATE_12 =>
				output <= "1010";
				next_state <= STATE_13;
			
			when STATE_13 =>
				output <= "1011";
				next_state <= STATE_14;
			
			when STATE_14 =>
				output <= "1001";
				next_state <= STATE_15;
			
			when STATE_15 =>
				output <= "1000";
				next_state <= STATE_0;
			
			when others =>
				null;
		end case;
	end process;
end BHV;