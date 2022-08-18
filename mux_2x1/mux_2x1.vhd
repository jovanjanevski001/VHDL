library ieee;
use ieee.std_logic_1164.all;

entity mux_2x1 is
	port
	(
		in1		:	in	std_logic;
		in2		:	in	std_logic;
		sel		:	in	std_logic;
	
		output	:	out	std_logic
	);
end mux_2x1;


architecture WHEN_ELSE of mux_2x1 is
begin
	
	output <= in1 when sel = '0' else
			  in2 when sel = '1';
	
end WHEN_ELSE;


architecture WITH_SELECT of mux_2x1 is
begin

	with sel select
		output <= in1 when '0',
				  in2 when others;
	
end WITH_SELECT;


architecture IF_STATEMENT of mux_2x1 is
begin
	-- all inputs to the comb. logic must go in the sensitivity list
	process(in1, in2, sel)
	begin
		if (sel = '0') then
			output <= in1;
		
		else 
			output <= in2;
		
		end if;
	end process;
	
end IF_STATEMENT;

architecture CASE_STATEMENT of mux_2x1 is
begin
	
	process(in1, in2, sel)
	begin
		case sel is
			when '0' =>
				output <= in1;
		
			when others =>
				output <= in2;
		
		end case;
	end process;
	
end CASE_STATEMENT;