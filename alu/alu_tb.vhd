library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end alu_tb;

architecture TB of alu_tb is
	
	constant WIDTH	:	positive := 8;
	
	subtype retType	is std_logic_vector(WIDTH downto 0);
	
	component alu		
		port 
		(	
			input1	:	in	std_logic_vector(WIDTH-1 downto 0);
			input2	:	in	std_logic_vector(WIDTH-1 downto 0);
			sel		:	in	std_logic_vector(3 downto 0);
			
			output		:	out	std_logic_vector(WIDTH-1 downto 0);
			overflow	:	out std_logic
		);
	end component;

	signal input1	:	std_logic_vector(WIDTH-1 downto 0);
	signal input2	:	std_logic_vector(WIDTH-1 downto 0);
	signal sel 		:	std_logic_vector(3 downto 0) := "0000";		--	ADD = "0000"
	signal output	:	std_logic_vector(WIDTH-1 downto 0);
	signal overflow	:	std_logic;

begin -- TB

	U_ALU	:	entity work.alu
		generic map
		(
			WIDTH	=>	WIDTH
		)
	
		port map
		(
			input1	 => 	input1,
			input2	 => 	input2,
			sel		 => 	sel,
			output	 => 	output,
			overflow => 	overflow
		);
	
	process		
		
		variable temp		:	std_logic_vector(WIDTH-1 downto 0) := (others => '0');
		variable add_temp 	:	std_logic_vector(WIDTH downto 0) := (others => '0');
		variable mult_temp	:	std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
		variable mult_ovf	:	std_logic;
		variable swap_temp	:	std_logic_vector(WIDTH-1 downto 0);
		
	begin
		for i in 0 to 2**WIDTH-1 loop
	
			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));
		
			wait for 10 ns;		
			add_temp := std_logic_vector(resize(unsigned(input1), WIDTH+1) + resize(unsigned(input2), WIDTH+1));

			assert(unsigned(output) = unsigned(add_temp(WIDTH-1 downto 0))) report "ADD error at i: " & integer'image(i) severity warning;
			assert(overflow = add_temp(WIDTH)) report "ADD Overflow error at i: " & integer'image(i) severity warning;
		
		end loop; -- i
		

		sel <= "0001";		--	SUB
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(2**WIDTH-1 - i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			temp := std_logic_vector(unsigned(input1) - unsigned(input2));

			assert(unsigned(output) = unsigned(temp)) report "SUB Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "SUB Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i
		

		sel <= "0010";		--	MULT
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			mult_temp := std_logic_vector(unsigned(input1) * unsigned(input2));
			
			if(unsigned(mult_temp) > 2**WIDTH-1) then
				mult_ovf := '1';
			else
				mult_ovf := '0';
			end if;
			
			assert(unsigned(output) = unsigned(mult_temp(WIDTH-1 downto 0))) report "MULT Error at i: " & integer'image(i) severity warning;
			assert(overflow = mult_ovf) report "MULT Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i
		

		sel <= "0011";		--	AND	
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			
			assert(output = (input1 and input2)) report "AND Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "AND Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i
		

		sel <= "0100";		--	OR		
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			
			assert(output = (input1 or input2)) report "OR Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "OR Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i		
		

		sel <= "0101";		--	XOR
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			
			assert(output = (input1 xor input2)) report "XOR Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "XOR Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i
		
		
		sel <= "0110";		--	NOR
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			input2 <= std_logic_vector(to_unsigned(i, WIDTH));

			wait for 10 ns;		
			
			assert(output = (input1 nor input2)) report "NOR Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "NOR Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i		
		

		input2 <= (others => '0');	--	input2 not needed for further opcodes, 0 to make simulation easier to read
		sel <= "0111";		--	NOT input1
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait for 10 ns;		
			
			assert(output = not(input1)) report "NOT(input1) Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "NOT(input1) Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i		
		
		
		sel <= "1000";		--	Shift input1 left 1 bit		
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait for 10 ns;		
			
			assert(overflow = input1(WIDTH-1)) report "SHL Overflow error at i: " & integer'image(i) severity warning;
			assert(output = std_logic_vector(shift_left(unsigned(input1), 1))) report "SHL Error at i: " & integer'image(i) severity warning;
			
		end loop; -- i		


		sel <= "1001";		--	Shift input1 right 1 bit
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait for 10 ns;		
			
			assert(output = std_logic_vector(shift_right(unsigned(input1), 1))) report "SHR Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "SHR Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i	
		
		
		sel <= "1010";		-- swap the upper half of input1 with the lower half
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait for 10 ns;		
			
			if ((WIDTH mod 2) = 0) then
				swap_temp(WIDTH-1 downto (WIDTH/2)) := input1((WIDTH/2)-1 downto 0);
				swap_temp((WIDTH/2)-1 downto 0) := input1(WIDTH-1 downto (WIDTH/2));
			else
				swap_temp(WIDTH-1 downto ((WIDTH-1)/2)+1) := input1((WIDTH/2)-1 downto 0);
				swap_temp((WIDTH-1)/2 downto 0) := input1(WIDTH-1 downto (WIDTH-1)/2);
			end if;
			
			
			assert(output = swap_temp) report "SWAP Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "SWAP Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i			
		
		
		sel <= "1011";		-- reverse the bits in input1
		for i in 0 to 2**WIDTH-1 loop

			input1 <= std_logic_vector(to_unsigned(i, WIDTH));
			
			wait for 10 ns;		
			
			for ii in 0 to WIDTH-1 loop
				temp(ii) := input1(WIDTH-1-ii);
			end loop; -- ii
	
			assert(output = temp) report "REVERSE Error at i: " & integer'image(i) severity warning;
			assert(overflow = '0') report "REVERSE Overflow error at i: " & integer'image(i) severity warning;

		end loop; -- i			
		
		report "Simulation Finished!" severity note;
		
		wait;
	end process;
end TB;