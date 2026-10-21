library ieee;
use ieee.std_logic_1164.all;
use work.vga_pkg.all;

entity vga_datapath is 
	port
	(
		clk		:	in std_logic;
		rst		:	in std_logic;
		
		x		:	out	coor_width_t;
		y		:	out coor_width_t;
		
		-- Control signals from the vga_ctrl
		h_ld		:	in std_logic;
		h_mux_sel	:	in std_logic;
		v_ld		:	in std_logic;
		v_mux_sel	:	in std_logic;
		
		-- Status signals to the vga_ctrl
		h_at_vis_end	:	out	std_logic;
		h_at_front_end	:	out	std_logic;
		h_at_sync_end	:	out	std_logic;
		h_at_end		:	out	std_logic;
		
		v_at_vis_end	:	out	std_logic;
		v_at_front_end	:	out	std_logic;
		v_at_sync_end	:	out	std_logic;
		v_at_end		:	out	std_logic
	);
end vga_datapath;

architecture STR of vga_datapath is
	
	signal h_reg, h_1, h_mux_out	: coor_width_t;
	signal v_reg, v_1, v_mux_out	: coor_width_t;
	
begin
	
	x <= h_reg;
	y <= v_reg;
	
	
	-- Horizontal component instantiations --
	U_H_INC	: entity work.adder
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1		=> 	h_reg,
			in2 	=>	C_ONE,
			output	=>	h_1
		);
	
	U_H_MUX : entity work.mux_2x1
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1		=>	h_1,
			in2		=>	C_ZERO,
			sel		=>	h_mux_sel,
			output	=>	h_mux_out
		);
	
	U_H_REG : entity work.reg_en
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst, 
			en		=>	h_ld,
			input	=>	h_mux_out,
			output	=>	h_reg
		);
		
	U_H_CMP_VIS	: entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	h_reg,
			in2	=>	H_VISIBLE_END,
			eq	=>	h_at_vis_end
		);
		
	U_H_CMP_FRONT : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	h_reg,
			in2	=>	H_FRONT_END,
			eq	=>	h_at_front_end
		);
	
	U_H_CMP_SYNC : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	h_reg,
			in2	=>	H_SYNC_END,
			eq	=>	h_at_sync_end
		);
	
	U_H_CMP_BACK : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	h_reg,
			in2	=>	H_END,
			eq	=>	h_at_end
		);
	-------------------------------------------
	
	
	-- Vertical component instantiations --
	U_V_INC	: entity work.adder
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1		=> 	v_reg,
			in2 	=>	C_ONE,
			output	=>	v_1
		);
	
	U_V_MUX : entity work.mux_2x1
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1		=>	v_1,
			in2		=>	C_ZERO,
			sel		=>	v_mux_sel,
			output	=>	v_mux_out
		);
	
	U_V_REG : entity work.reg_en
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			clk		=>	clk,
			rst		=>	rst, 
			en		=>	v_ld,
			input	=>	v_mux_out,
			output	=>	v_reg
		);
	
	U_V_CMP_VIS	: entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	v_reg,
			in2	=>	V_VISIBLE_END,
			eq	=>	v_at_vis_end
		);
		
	U_V_CMP_FRONT : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	v_reg,
			in2	=>	V_FRONT_END,
			eq	=>	v_at_front_end
		);
	
	U_V_CMP_SYNC : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	v_reg,
			in2	=>	V_SYNC_END,
			eq	=>	v_at_sync_end
		);
	
	U_V_CMP_BACK : entity work.comparator_eq
		generic map ( WIDTH => COOR_WIDTH )
		
		port map
		(
			in1	=>	v_reg,
			in2	=>	V_END,
			eq	=>	v_at_end
		);
	-------------------------------------------
		
end STR;