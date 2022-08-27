library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fa_tb is
end fa_tb;

architecture TB of fa_tb is

signal in1, in2, carry_in, sum, carry_out	:	std_logic;	
	
begin
	
	UUT	: entity work.fa
		port map
		(
			in1		  =>  in1,
			in2		  =>  in2,
			carry_in  =>  carry_in,
			
			sum		  =>  sum,
			carry_out =>  carry_out
		);
	
	process
		variable temp : std_logic_vector(2 downto 0);
	begin
		
		for i in 0 to 7 loop
			
			temp := std_logic_vector(to_unsigned(i, 3));
			
			in1 <= temp(2);
			in2 <= temp(1);
			carry_in <= temp(0);
			
			wait for 20 ns;
			
			assert(sum = (in1 xor in2 xor carry_in)) report "Sum failed" severity warning;
			assert(carry_out = ((in1 and carry_in) or (in2 and carry_in) or (in1 and in2))) report "Carry out failed" severity warning;
			
		end loop; -- i 
		
		report "Simulation Finished!" severity note;
		wait;
	end process;
end TB;