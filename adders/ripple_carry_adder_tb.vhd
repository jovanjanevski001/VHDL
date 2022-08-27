library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ripple_carry_adder_tb is 
end ripple_carry_adder_tb;

architecture TB of ripple_carry_adder_tb is 

constant WIDTH	:	positive := 8;

signal in1			:	std_logic_vector(WIDTH-1 downto 0);
signal in2			:	std_logic_vector(WIDTH-1 downto 0);
signal carry_in		:	std_logic := '0';
signal sum			:	std_logic_vector(WIDTH-1 downto 0);
signal carry_out	:	std_logic;

begin
	
	UUT: entity work.ripple_carry_adder
		generic map
		(
			WIDTH	=>	WIDTH
		)
		
		port map
		(
			in1			=>	in1,
			in2			=>	in2,
			carry_in	=>	carry_in,
			
			sum			=>	sum,
			carry_out	=>	carry_out
		);
	
	process
		
		variable temp1, temp2 : std_logic_vector(WIDTH-1 downto 0);
		variable add_temp : std_logic_vector(WIDTH downto 0);

	begin
		
		for i in 0 to 2**WIDTH-1 loop
			for j in 0 to 2**WIDTH-1 loop
				
				temp1 := std_logic_vector(to_unsigned(i, WIDTH));
				temp2 := std_logic_vector(to_unsigned(j, WIDTH));
				
				in1 <= temp1;
				in2 <= temp2;
				
				wait for 20 ns;
				
				add_temp := std_logic_vector(resize(unsigned(temp1), WIDTH+1) + resize(unsigned(temp2), WIDTH+1));
				
				assert(sum = add_temp(WIDTH-1 downto 0)) report "Incorrect Sum" severity warning;
				assert(carry_out = add_temp(WIDTH)) report "Incorrect Carry" severity warning;
				
			end loop; -- j
		end loop; -- i
		
		report "SIMULATION FINISHED!" severity note;
		wait;
	end process;
end TB;