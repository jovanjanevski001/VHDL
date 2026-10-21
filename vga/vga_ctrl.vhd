library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;


entity vga_ctrl is
	port
	(
		clk		:	in std_logic;
		rst		:	in std_logic;
		
		-- status signals from the datapath
		h_at_vis_end	:	in std_logic;
		h_at_front_end	:	in std_logic;
		h_at_sync_end	:	in std_logic;
		h_at_end		:	in std_logic;
		
		v_at_vis_end	:	in std_logic;
		v_at_front_end	:	in std_logic;
		v_at_sync_end	:	in std_logic;
		v_at_end		:	in std_logic;
		
		-- control signals to the datapath
		h_reg_ld	:	out std_logic;
		h_mux_sel 	:	out std_logic;
		v_reg_ld	:	out std_logic;
		v_mux_sel	:	out std_logic;
		
		
		-- video control outputs
		h_sync		:	out std_logic;
		v_sync		:	out std_logic;
		visible		:	out	std_logic;
		frame_tick	:	out std_logic
	);
end vga_ctrl;

architecture BHV of vga_ctrl is
	
	type h_state_t is (H_VISIBLE_S, H_FRONT_S, H_SYNC_S, H_BACK_S);
	type v_state_t is (V_VISIBLE_S, V_FRONT_S, V_SYNC_S, V_BACK_S);
	
	signal h_state, h_next_state : h_state_t;
	signal v_state, v_next_state : v_state_t;
	
	signal line_end	:	std_logic;	--	last pixel of a line
	
begin	
	
	line_end <= h_at_end;
	
	h_reg_ld <= '1';	-- x advances every pixel clock
	v_reg_ld <= line_end;	-- y advances once per line
	
	process(clk, rst)
	begin
		if (rst = '1') then
			h_state <= H_VISIBLE_S;
			v_state <= V_VISIBLE_S;
			
		elsif (rising_edge(clk)) then
			h_state <= h_next_state;
			if (line_end = '1') then
				v_state <= v_next_state;
			end if;
		end if;
	end process;
	
	process(h_state, v_state, h_at_vis_end, h_at_front_end, h_at_sync_end, 
			h_at_end, v_at_vis_end, v_at_front_end, v_at_sync_end, v_at_end)
	begin	
		
		-- default values
		h_next_state <= h_state;
		v_next_state <= v_state;
		h_mux_sel <= '0';
		v_mux_sel <= '0';
		
		case h_state is
			when H_VISIBLE_S =>
				if (h_at_vis_end = '1') then
					h_next_state <= H_FRONT_S;
				end if;
			when H_FRONT_S =>
				if (h_at_front_end = '1') then
					h_next_state <= H_SYNC_S;
				end if;
			when H_SYNC_S =>
				if (h_at_sync_end = '1') then
					h_next_state <= H_BACK_S;
				end if;
			when H_BACK_S =>
				if (h_at_end = '1') then
					h_mux_sel <= '1';			--	start next line, x = 0
					h_next_state <= H_VISIBLE_S;
				end if;
		end case;
		
		
		case v_state is
			when V_VISIBLE_S =>
				if (v_at_vis_end = '1') then
					v_next_state <= V_FRONT_S;
				end if;
			when V_FRONT_S =>
				if (v_at_front_end = '1') then
					v_next_state <= V_SYNC_S;
				end if;
			when V_SYNC_S =>
				if (v_at_sync_end = '1') then
					v_next_state <= V_BACK_S;
				end if;
			when V_BACK_S =>
				if (v_at_end = '1') then
					v_mux_sel <= '1';			--	start next frame, y = 0
					v_next_state <= V_VISIBLE_S;
				end if;
		end case;
	end process;
	
	h_sync 	<= '0' when (h_state = H_SYNC_S) else '1';
	v_sync 	<= '0' when (v_state = V_SYNC_S) else '1';
	visible <= '1' when (h_state = H_VISIBLE_S and v_state = V_VISIBLE_S) else '0';
	frame_tick <= '1' when (v_state = V_VISIBLE_S and v_at_vis_end = '1' and h_at_end = '1') else '0';
	
end BHV;