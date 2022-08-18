library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_2x1_tb is
end mux_2x1_tb;


architecture TB of mux_2x1_tb is

	component mux_2x1
		port
		(
			in1		:	in	std_logic;
			in2		:	in	std_logic;
			sel		:	in	std_logic;
			
			output	:	out	std_logic
		);
	end component;
	
	signal	in1		:	std_logic;
	signal	in2		:	std_logic;
	signal	sel		:	std_logic;
	
	signal	output_when_else		:	std_logic;
	signal	output_with_select		:	std_logic;
	signal	output_if_statement		:	std_logic;
	signal	output_case_statement	:	std_logic;
	
begin
	
	U_WHEN_ELSE		:	entity work.mux_2x1(WHEN_ELSE)
		port map
		(
			in1		=>	in1,
			in2		=>	in2,
			sel		=>	sel,
			output	=>	output_when_else
		);
		
	U_WITH_SELECT	:	entity work.mux_2x1(WITH_SELECT)
		port map
		(
			in1		=>	in1,
			in2		=>	in2,
			sel		=>	sel,
			output	=>	output_with_select
		);	
		
	U_IF_STATMENT	:	entity work.mux_2x1(IF_STATEMENT)
		port map
		(
			in1		=>	in1,
			in2		=>	in2,
			sel		=>	sel,
			output	=>	output_if_statement
		);	
	
	U_CASE_STATMENT	:	entity work.mux_2x1(CASE_STATEMENT)
		port map
		(
			in1		=>	in1,
			in2		=>	in2,
			sel		=>	sel,
			output	=>	output_case_statement
		);	
		
	process
		variable temp	:	std_logic_vector(2 downto 0);
		
		pure function mux_test
		(
			signal in1	:	std_logic;
			signal in2	:	std_logic;
			signal sel	:	std_logic
		)
			return std_logic is
			
		begin
			if (sel = '0') then 
				return in1;
			else 
				return in2;
			end if;
		end mux_test;
		
	
	begin
		
		for i in 0 to 7 loop
			
			temp:= std_logic_vector(to_unsigned(i, 3));
			
			in1	<=	temp(2);
			in2	<=	temp(1);
			sel	<=	temp(0);
			
			wait for 10 ns;
			
			assert(output_when_else = mux_test(in1, in2, sel))
				report "Error : output_when_else incorrect for in1 = " & std_logic'image(in1) & " in2 = " & std_logic'image(in2) & " sel = " & std_logic'image(sel) severity warning;
		
			assert(output_with_select = mux_test(in1, in2, sel))
				report "Error : output_with_select incorrect for in1 = " & std_logic'image(in1) & " in2 = " & std_logic'image(in2) & " sel = " & std_logic'image(sel) severity warning;

			assert(output_if_statement = mux_test(in1, in2, sel))
				report "Error : output_if_statement incorrect for in1 = " & std_logic'image(in1) & " in2 = " & std_logic'image(in2) & " sel = " & std_logic'image(sel) severity warning;

			assert(output_case_statement = mux_test(in1, in2, sel))
				report "Error : output_case_statement incorrect for in1 = " & std_logic'image(in1) & " in2 = " & std_logic'image(in2) & " sel = " & std_logic'image(sel) severity warning;


		end loop;
		
		wait;	
	
	end process;
	
end TB;