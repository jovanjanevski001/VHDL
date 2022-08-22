library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	generic 
	(
		WIDTH	:	positive := 16 
	);
	
	port
	(
		input1	:	in	std_logic_vector(WIDTH-1 downto 0);
		input2	:	in	std_logic_vector(WIDTH-1 downto 0);
		sel		:	in	std_logic_vector(3 downto 0);
		
		output	 :	out	std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		overflow :	out	std_logic		--	assuming all operations are unsigned
	);
end alu;

architecture BHV of alu is
begin
	
	process(input1, input2, sel)	
	
		variable add_output		:	std_logic_vector(WIDTH downto 0);
		variable mult_output	:	std_logic_vector(2*WIDTH-1 downto 0);
	begin	
		-- default values to avoid latches inferred on outputs
		output 	 <= (others => '0');
		overflow <= '0';
		
		case sel is
			-- ADD
			when "0000" =>
				add_output 	:= std_logic_vector(resize(unsigned(input1), WIDTH+1) + resize(unsigned(input2), WIDTH+1));
				output	 	<= add_output(WIDTH-1 downto 0);
				overflow 	<= add_output(WIDTH);
				
			-- SUB
			when "0001" =>
				output <= std_logic_vector(unsigned(input1) - unsigned(input2));
			
			-- MULT
			when "0010" =>
				mult_output := std_logic_vector(unsigned(input1) * unsigned(input2));
				output		<= mult_output(WIDTH-1 downto 0);
				
				if(unsigned(mult_output) > 2**WIDTH-1) then
					overflow <= '1';
				else
					overflow <= '0';
				end if;
				
			-- AND
			when "0011" =>
				output <= input1 and input2;
				
			-- OR
			when "0100" =>
				output <= input1 or input2;
			
			-- XOR
			when "0101" =>
				output <= input1 xor input2;
				
			-- NOR
			when "0110" =>
				output <= input1 nor input2;
				
			-- NOT input1
			when "0111" =>
				output <= not(input1);
				
			-- Shift input1 left by 1 bit
			when "1000" =>
				overflow <= input1(WIDTH-1);
				output <= std_logic_vector(shift_left(unsigned(input1), 1));
			
			-- Shift input1 right by 1 bit
			when "1001" =>
				output <= std_logic_vector(shift_right(unsigned(input1), 1));
				
			-- swap the upper half of input1 with the lower half
			-- write the result to output
			when "1010" =>
				if ((WIDTH mod 2) = 0) then
					output(WIDTH-1 downto (WIDTH/2)) <= input1((WIDTH/2)-1 downto 0);
					output((WIDTH/2)-1 downto 0) <= input1(WIDTH-1 downto (WIDTH/2));
				else
					output(WIDTH-1 downto ((WIDTH-1)/2)+1) <= input1((WIDTH/2)-1 downto 0);
					output((WIDTH-1)/2 downto 0) <= input1(WIDTH-1 downto (WIDTH-1)/2);
				end if;
			
			-- reverse the bits in input1, write the result to output
			when "1011" =>
				for i in 0 to WIDTH-1 loop			--	check RTL viewer to see if design synthesized correctly
					output(i) <= input1(WIDTH-1-i);
				end loop; -- i
			
			-- all other cases default here
			when others =>
				output <= (others => '0');
				overflow <= '0';
		end case;
	end process;
end;