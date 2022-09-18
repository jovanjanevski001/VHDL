library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fibonacci is
	generic
	(
		WIDTH : positive := 8
	);
	
	port
	(
		clk		:	in	std_logic;
		rst		:	in	std_logic;
		go		:	in	std_logic;
		n		:	in	std_logic_vector(WIDTH-1 downto 0);
		result 	:	out std_logic_vector(WIDTH-1 downto 0);
		done	:	out	std_logic
	);
end fibonacci;

-- 1-process model FSMD implementation of the fibonacci calculator
architecture FSMD of fibonacci is
	
	constant C_3 : unsigned(WIDTH-1 downto 0) := to_unsigned(3, WIDTH);
	constant C_1 : unsigned(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
	
	type state_type is (INIT_STATE, ALGORITHM_STATE, DONE_STATE);
	signal state : state_type;
	
	signal n_reg : unsigned(WIDTH-1 downto 0) := (others => '0');
	signal i_reg : unsigned(WIDTH-1 downto 0) := C_3;
	signal x_reg : unsigned(WIDTH-1 downto 0) := C_1;
	signal y_reg : unsigned(WIDTH-1 downto 0) := C_1;
		
begin	-- FSMD
	process(clk, rst)
		variable temp  : unsigned(WIDTH-1 downto 0) := (others => '0');
	begin
		if (rst = '1') then
			state <= INIT_STATE;
			done <= '0';
			result <= (others => '0');
			
		elsif (rising_edge(clk)) then	
			case state is
				
				when INIT_STATE =>
					if (go = '1') then
						done <= '0';
						n_reg <= unsigned(n);
						i_reg <= C_3;
						x_reg <= C_1;
						y_reg <= C_1;
						
						state <= ALGORITHM_STATE;
					end if;
					
				when ALGORITHM_STATE =>
					if (i_reg <= n_reg) then
						temp  := x_reg + y_reg;	--	temp = x + y
						x_reg <= y_reg;			--	x = y
						y_reg <= temp;			--	y = temp
						i_reg <= i_reg + 1;		--	i++
					else
						result <= std_logic_vector(y_reg);
						done <= '1';
						
						state <= DONE_STATE;
					end if;
					
				when DONE_STATE =>
					if (go = '0') then
						state <= INIT_STATE;
					end if;
					
				when others =>
					null;
			end case;
		end if;
	end process;
end FSMD;


-- FSM+D structural implementation of the fibonacci calculator
architecture FSM_D of fibonacci is
	
	signal i_sel 	 : std_logic;
	signal x_sel	 : std_logic;
	signal y_sel	 : std_logic;	
	signal i_ld		 : std_logic;
	signal x_ld		 : std_logic;
	signal y_ld		 : std_logic;
	signal n_ld		 : std_logic;
	signal result_ld : std_logic; 
	signal i_le_n	 : std_logic;
	
begin
	U_DATAPATH	:	entity work.datapath
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk			=>	clk,
			rst			=>	rst,
			n			=>	n,
			result		=>	result,
			
			i_sel		=>	i_sel,
			x_sel		=>	x_sel,		
			y_sel		=>	y_sel,		
			i_ld		=>	i_ld,		
			x_ld		=>	x_ld,		
			y_ld		=>	y_ld,		
			n_ld		=>	n_ld,		
			result_ld	=>	result_ld,	
			i_le_n		=>	i_le_n			
		);
	
	U_CTRL	:	entity work.ctrl
		generic map ( WIDTH => WIDTH )
	
		port map
		(
			clk			=> 	clk,
			rst			=> 	rst,
			go			=> 	go,
			done		=> 	done,

			i_le_n		=> 	i_le_n,
			i_sel		=> 	i_sel,
			x_sel		=> 	x_sel,	
			y_sel		=> 	y_sel,	
			i_ld		=> 	i_ld,	
			x_ld		=> 	x_ld,	
			y_ld		=> 	y_ld,	
			n_ld		=> 	n_ld,	
			result_ld	=> 	result_ld
		);
	
end FSM_D;

-- 2-process model FSMD implementation of the fibonacci calculator
architecture FSMD2 of fibonacci is
	
	type state_type is (INIT_STATE, ALGORITHM_STATE, DONE_STATE);
	signal state, next_state : state_type;
	
	constant C_1 : unsigned(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
	constant C_3 : unsigned(WIDTH-1 downto 0) := to_unsigned(3, WIDTH);
	
	signal i, i_reg : unsigned(WIDTH-1 downto 0) := C_3;
	signal x, x_reg : unsigned(WIDTH-1 downto 0) := C_1;
	signal y, y_reg : unsigned(WIDTH-1 downto 0) := C_1;
	signal n_reg    : unsigned(WIDTH-1 downto 0);
	
	
begin	-- FSMD2
	-- Sequential Logic
	process(clk, rst)
	begin
		if (rst = '1') then
			state <= INIT_STATE;
			i_reg <= (others => '0');
			x_reg <= (others => '0');
			y_reg <= (others => '0');
			n_reg <= (others => '0');
			
		elsif (rising_edge(clk)) then
			state <= next_state;
			i_reg <= i;
			x_reg <= x;
			y_reg <= y;
			n_reg <= unsigned(n);
			
		end if;
	end process;
	
	-- Combinatorial Logic
	process(state, go, n_reg, i_reg, x_reg, y_reg)
		variable temp : unsigned(WIDTH-1 downto 0);
	begin
		-- default values 
		done <= '0';
		result <= (others => '0');
		next_state <= state;
		
		case state is
			when INIT_STATE =>
				if (go = '1') then
					i <= C_3;
					x <= C_1;
					y <= C_1;
					
					next_state <= ALGORITHM_STATE;
				end if;
			when ALGORITHM_STATE =>
				if (i <= n_reg) then
					temp := x + y;
					x <= y;
					y <= temp;
					i <= i + 1;
				else
					next_state <= DONE_STATE;
				end if;
			when DONE_STATE =>
				result <= std_logic_vector(y);
				done <= '1';
				
				if (go = '0') then
					next_state <= INIT_STATE;
				end if;
			when others =>
				null;
		end case;
	end process;
end FSMD2;