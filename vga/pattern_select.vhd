library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;
 
-- 8-to-1 selection of a pixel source, built from a tree of mux_2x1 (12 bits wide:
-- r & g & b). sel(0) picks within each pair, sel(1) within each group of four,
-- sel(2) between the two groups.
entity pattern_select is
	port
	(
		sel	: in  pattern_sel_t;
		pix	: in  pixel_array_t;
		r	: out color_width_t;
		g	: out color_width_t;
		b	: out color_width_t
	);
end pattern_select;
 
architecture STR of pattern_select is
	type pixel_array_4_t is array (0 to 3) of std_logic_vector(11 downto 0);
	type pixel_array_2_t is array (0 to 1) of std_logic_vector(11 downto 0);
	
	signal l1 : pixel_array_4_t;
	signal l2 : pixel_array_2_t;
	signal m  : std_logic_vector(11 downto 0);
begin
	G_L1 : for k in 0 to 3 generate
		U_MUX : entity work.mux_2x1
			generic map ( WIDTH => 12 )
			port map 
			( 
				in1 => pix(2*k), 
				in2 => pix(2*k+1),
				sel => sel(0), 
				output => l1(k) 
			);
	end generate G_L1;
	
	G_L2 : for k in 0 to 1 generate
		U_MUX : entity work.mux_2x1
			generic map ( WIDTH => 12 )
			port map 
			( 
				in1 => l1(2*k),
				in2 => l1(2*k+1),
				sel => sel(1), 
				output => l2(k)
			);
	end generate G_L2;
	
	U_MUX_FINAL : entity work.mux_2x1
		generic map ( WIDTH => 12 )
		port map 
		( 
			in1 => l2(0),
			in2 => l2(1), 
			sel => sel(2),
			output => m 
		);
	
	r <= m(11 downto 8);
	g <= m(7 downto 4);
	b <= m(3 downto 0);
end STR;