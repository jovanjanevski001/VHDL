library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_pkg.all;
 
-- Position of a square that bounces around the visible area.
-- Moves SQUARE_SPEED_X / SQUARE_SPEED_Y pixels each time tick = '1' (once per frame),
-- and reverses direction when it reaches an edge. pos_x / pos_y are the top-left corner.
entity bounce_motion is
	port
	(
		clk		: in  std_logic;
		rst		: in  std_logic;
		tick	: in  std_logic;
		pos_x	: out coor_width_t;
		pos_y	: out coor_width_t
	);
end bounce_motion;

architecture BHV of bounce_motion is

	signal px, py	: unsigned(COOR_WIDTH-1 downto 0);
	signal right	: std_logic;	--	'1' = right, '0' = left
	signal down		: std_logic;	--	'1' = down, '0' = up
	
begin
	
	process(clk, rst)
	
	begin
		if (rst = '1') then
			px    <= to_unsigned(SQUARE_START_X, COOR_WIDTH);
			py    <= to_unsigned(SQUARE_START_Y, COOR_WIDTH);
			right <= '1';
			down  <= '1';
		elsif (rising_edge(clk)) then
			if (tick = '1') then
				-- horizontal
				if (right = '1') then
					if (px + SQUARE_SPEED_X + SQUARE_SIZE >= H_VISIBLE) then
						px <= to_unsigned(H_VISIBLE - SQUARE_SIZE, COOR_WIDTH);
						right <= '0';
					else
						px <= px + SQUARE_SPEED_X;
					end if;
				
				else	--	right = '0'
					if (px <= SQUARE_SPEED_X) then
						px <= to_unsigned(0, COOR_WIDTH);
						right <= '1';
					else
						px <= px - SQUARE_SPEED_X;
					end if;
				end if;
				
				-- vertical
				if (down = '1') then
					if (py + SQUARE_SPEED_Y + SQUARE_SIZE >= V_VISIBLE) then
						py <= to_unsigned(V_VISIBLE - SQUARE_SIZE, COOR_WIDTH);
						down <= '0';
					else
						py <= py + SQUARE_SPEED_Y;
					end if;
				
				else	--	down = '0'
					if (py <= SQUARE_SPEED_Y) then
						py <= to_unsigned(0, COOR_WIDTH);
						down <= '1';
					else
						py <= py - SQUARE_SPEED_Y;
					end if;	
				end if;
			end if;
		end if;
	end process;
	
	pos_x <= std_logic_vector(px);
	pos_y <= std_logic_vector(py);
	
end BHV;