library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Bumper_Pool is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by ; ) --
		A_COUNT_H 	: integer := 15;
		B_COUNT_H 	: integer := 95;
		C_COUNT_H 	: integer := 47;
		D_COUNT_H 	: integer := 639;
		LAST_A_V 	: unsigned(9 downto 0) := to_unsigned(9, 	 10);
		LAST_B_V 	: unsigned(9 downto 0) := to_unsigned(11,  10);
		LAST_C_V 	: unsigned(9 downto 0) := to_unsigned(44,  10);
		LAST_D_V	 	: unsigned(9 downto 0) := to_unsigned(524, 10);
		L_COUNT 		: unsigned(9 downto 0) := to_unsigned(524, 10);
		F_COUNT		: integer := 11;
		DELAY			: integer := 500000;
		SAMPLE_PERIOD : integer := 10000000

		);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1

		-- Button input --
		KEY : in std_logic_vector (1 downto 0);
		
		-- VGA --
		VGA_R 	: out std_logic_vector(3 downto 0);
		VGA_G 	: out std_logic_vector(3 downto 0);
		VGA_B 	: out std_logic_vector(3 downto 0);
		VGA_HS	: out std_logic;
		VGA_VS	: out std_logic;
		
		-- Arduino Header --
		ARDUINO_IO			: inout std_logic_vector(15 downto 0);
		ARDUINO_RESET_N	: inout std_logic
	);

end entity Bumper_Pool;

architecture behavioral of Bumper_Pool is

	-- Components --
	-- ADC --
	component my_ADC is
		port (
			clock_clk              : in  std_logic                     := 'X';             -- clk
			reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
			adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
			command_valid          : in  std_logic                     := 'X';             -- valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_ready          : out std_logic;                                        -- ready
			response_valid         : out std_logic;                                        -- valid
			response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_data          : out unsigned(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component my_ADC;
	
	-- PLL --
	component my_PLL IS
		PORT
		(
			areset	: IN STD_LOGIC  := '0';
			inclk0	: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC ;
			locked	: OUT STD_LOGIC 
		);
	END component;
	
	signal c0_sig : std_logic;
	signal locked_sig : std_logic;
	signal c1_sig : std_logic;
	signal locked1_sig : std_logic;

	-- VGA Signals --
	signal pix_count 			: integer := 0;
	signal next_pix_count	: integer := 0;
	signal lin_count 			: unsigned(9 downto 0) := to_unsigned(0, 10);
	signal next_lin_count 	: unsigned(9 downto 0) := to_unsigned(0, 10);
	signal clk_count 			: integer := 0;
	signal next_clk_count 	: integer := 0;
	
	signal timer 				: integer := 0;	-- Timer for debounce
	signal next_timer 		: integer := 0;
	
	signal next_VGA_R  		: std_logic_vector(3 downto 0) := "0000";
	signal next_VGA_G  		: std_logic_vector(3 downto 0) := "0000";
	signal next_VGA_B  		: std_logic_vector(3 downto 0) := "0000";
	signal next_VGA_HS 		: std_logic := '1';
	signal next_VGA_VS 		: std_logic := '1';
	
	signal current_VGA_R  		: std_logic_vector(3 downto 0) := "0000";
	signal current_VGA_G  		: std_logic_vector(3 downto 0) := "0000";
	signal current_VGA_B  		: std_logic_vector(3 downto 0) := "0000";
	signal current_VGA_HS 		: std_logic := '1';
	signal current_VGA_VS 		: std_logic := '1';
	
	-- Game Board Values --
	constant Border_Line_Thickness	: unsigned(9 downto 0) := to_unsigned(5, 10);					-- Thickness of border lines
	constant Border_Line_Top			: unsigned(9 downto 0) := last_C_V + to_unsigned(17, 10);	-- Top-most edge of upper board edge
	constant Border_Line_Bottom 		: unsigned(9 downto 0) := last_C_V + to_unsigned(340, 10);	-- Top-most edge of lower board edge
	constant Border_Line_Left			: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(17, 10);	-- Left-most edge of left board edge
	constant Border_Line_Right			: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(617, 10);	-- Left-most edge of right board edge
	constant Border_Goal_Top			: unsigned(9 downto 0) := last_C_V + to_unsigned(145, 10);	-- Top-most edge of goal
	constant Border_Goal_Bottom		: unsigned(9 downto 0) := last_C_V + to_unsigned(215, 10);	-- Bottom-most edge of goal

	-- Obstacle Locations --
	constant OB_Width				: unsigned(9 downto 0) := to_unsigned(20, 10);
	constant C_OB_Pixel			: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(311, 10);
	constant c_OB_Line			: unsigned(9 downto 0) := last_C_V + to_unsigned(170, 10);
	constant Top_OB_Line			: unsigned(9 downto 0) := last_C_V + to_unsigned(90, 10);
	constant Bottom_OB_Line		: unsigned(9 downto 0) := last_C_V + to_unsigned(250, 10);
	constant OB_Col_1				: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(140, 10);
	constant OB_Col_2				: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(253, 10);
	constant OB_Col_3				: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(366, 10);
	constant OB_Col_4				: unsigned(9 downto 0) := D_COUNT_H - to_unsigned(479, 10);
	
	-- Ball location --
	signal ball_current_pixel 	: integer := 320;
	signal ball_next_pixel	 	: integer := 320;
	signal ball_current_line	: integer := to_integer(last_C_V) + 60;
	signal ball_next_line		: integer := to_integer(last_C_V) + 60;
	constant ball_radius			: integer := 5;
	
	-- Ball movement --
	signal ball_current_x_vel	: integer := 5;
	signal ball_next_x_vel		: integer := 5;
	signal ball_current_y_vel	: integer := 0;
	signal ball_next_y_vel		: integer := 0;
	
	-- ADC Command Signals --
	signal command_valid          : std_logic							  := '1';            -- valid
	signal command_channel        : std_logic_vector(4 downto 0)  :=  "00001";  		-- channel
	signal command_startofpacket  : std_logic                     := '1';            -- startofpacket
	signal command_endofpacket    : std_logic                     := '1';            -- endofpacket
	signal command_ready          : std_logic;                                       -- ready
	
	-- ADC Response Signals --
	signal response_valid         : std_logic;                                  		-- valid
	signal response_channel       : std_logic_vector(4 downto 0);               		-- channel
	signal response_data          : unsigned(11 downto 0);              		-- data
	signal response_startofpacket : std_logic;                                  		-- startofpacket
	signal response_endofpacket   : std_logic;    
	
	-- MISC --
	signal sample_counter : integer := 0;
	signal sample_trigger : std_logic;
	signal player_1 : unsigned(12 downto 0) := (others => '0');
	signal player_2 : unsigned(12 downto 0) := (others => '0');
	signal next_player : unsigned(12 downto 0) := (others => '0');
	signal temp_player : integer;
	signal score_1 : integer := 0;
	signal score_2 : integer := 0;
	signal next_score_1 : integer;
	signal next_score_2 : integer;
	
	-- VGA FSM States
	type VGA_state_type is (
		Clear,
		A,
		B,
		C,
		D,
		Debounce
		);
	
	signal VGA_current_state, VGA_next_state: VGA_state_type;
	
	-- Ball FSM States
	type Ball_state_type is (
		Hidden,
		Waiting,
		Moving,
		Scored
	);
	
	signal ball_current_state, ball_next_state: Ball_state_type;

begin

	-- Define module behavior here --
	-- Instantiate components --
	-- ADC --
	u0 : component my_ADC
		port map (
			-- Input
			clock_clk              => MAX10_CLK1_50,             					--          clock.clk
			reset_sink_reset_n     => KEY(0),  				   					--     reset_sink.reset_n
			adc_pll_clock_clk      => c0_sig,      								--  adc_pll_clock.clk
			adc_pll_locked_export  => locked_sig,  								-- adc_pll_locked.export
			command_valid          => command_valid,          					--        command.valid
			command_channel        => command_channel,        					--               .channel
			command_startofpacket  => command_startofpacket,  					--               .startofpacket
			command_endofpacket    => command_endofpacket,    					--               .endofpacket
			-- Output
			command_ready          => command_ready,          					--               .ready
			response_valid         => response_valid,         					--       response.valid
			response_channel       => response_channel,       					--               .channel
			response_data          => response_data,          					--               .data
			response_startofpacket => response_startofpacket, 					--               .startofpacket
			response_endofpacket   => response_endofpacket    					--               .endofpacket
		);
	
	my_PLL_inst : my_PLL PORT MAP (
		areset	 	=> not KEY(0),
		inclk0	 	=> MAX10_CLK1_50,
		c0	 			=> c0_sig,
		locked	 	=> locked_sig
	);
	
	-- Ball Timing --
	process ( c0_sig, KEY, locked_sig )
	begin
		if rising_edge(c0_sig) then
			-- If Reset
			if (KEY(0) = '0') or (locked_sig = '0') then
				-- State
				ball_current_state 	<= Hidden;
			
				-- Position and Velocity
				ball_current_pixel	<= 0;
				ball_current_line		<= 0;
				ball_current_x_vel	<= 0;
				ball_current_x_vel	<= 0;
				score_1 <= 0;
				score_2 <= 0;
			
			-- Normal behavior
			else
				-- State
				ball_current_state 	<= ball_next_state;
				
				-- Position and Velocity
				ball_current_pixel	<= ball_next_pixel;
				ball_current_line		<= ball_next_line;
				ball_current_x_vel	<= ball_next_x_vel;
				ball_current_y_vel	<= ball_next_y_vel;
				score_1 <= next_score_1;
				score_2 <= next_score_2;

			end if;
			
		end if;
	end process;
	
	-- Ball Control FSM --
	process ( KEY, ball_current_state, ball_current_pixel, ball_current_line, ball_current_x_vel, ball_current_y_vel, lin_count, VGA_current_state, pix_count, locked_sig )
	begin
		case ball_current_state is
			when Hidden =>
				next_score_1 <= score_1;
				next_score_2 <= score_2;
				-- If Reset pressed
				if (KEY(0) = '0')  or (locked_sig = '0') then
					ball_next_state	<= Hidden;
					ball_next_pixel	<= 0;
					ball_next_line		<= 0;
					ball_next_x_vel	<= 0;
					ball_next_y_vel	<= 0;
					next_score_1 <= 0;
					next_score_2 <= 0;

				-- If New-Ball pressed
				elsif KEY(1) = '0' then
					ball_next_state 	<= Waiting;
					ball_next_pixel	<= 320;
					ball_next_line 	<= to_integer(last_C_V) + 60;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel 	<= 0;
				
				-- Otherwise wait for New-Ball
				else
					ball_next_state 	<= Hidden;
					ball_next_pixel 	<= 0;
					ball_next_line 	<= 0;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel 	<= 0;
				end if;
				
			when Waiting =>
				next_score_1 <= score_1;
				next_score_2 <= score_2;
				-- If New-Ball released
				if KEY(1) = '1' then
					ball_next_state <= Moving;
					ball_next_x_vel <= -4;
					ball_next_y_vel <= 3;
					
				-- If New-Ball still pressed
				else
					ball_next_state <= Waiting;
					ball_next_x_vel <= ball_current_x_vel;
					ball_next_y_vel <= ball_current_y_vel;
					
				end if;
				
				-- Do either way
				ball_next_pixel	<= ball_current_pixel;
				ball_next_line 	<= ball_current_line;
			
			when Moving =>
				next_score_1 <= score_1;
				next_score_2 <= score_2;
				-- If Reset pressed
				if (KEY(0) = '0')  or (locked_sig = '0') then
					ball_next_state	<= Hidden;
					ball_next_pixel 	<= 0;
					ball_next_line 	<= 0;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel	<= 0;
					next_score_1 <= 0;
					next_score_2 <= 0;
				
				-- If New-Ball pressed
				elsif KEY(1) = '0' then
					ball_next_state	<= Waiting;
					ball_next_pixel 	<= 320;
					ball_next_line 	<= to_integer(last_C_V) + 60;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel 	<= 0;
		
				-- Normal Behavior
				else
					-- If in left goal
					if (ball_current_pixel > Border_Line_Left - Border_Line_Thickness) then
						ball_next_state	<= Scored;
						ball_next_pixel	<= 0;
						ball_next_line		<= 0;
						ball_next_x_vel	<= 0;
						ball_next_y_vel	<= 0;
						if score_1 < 5 then
							next_score_1 <= score_1 + 1;
						else
							next_score_1 <= score_1;
						end if;
						
					-- If in right goal
					elsif (ball_current_pixel < to_integer(Border_Line_Right) + 1) then
						ball_next_state	<= Scored;
						ball_next_pixel	<= 0;
						ball_next_line		<= 0;
						ball_next_x_vel	<= 0;
						ball_next_y_vel	<= 0;
						if score_2 < 5 then
							next_score_2 <= score_2 + 1;
						else
							next_score_2 <= score_2;
						end if;
					
					-- If going to hit left wall
					elsif ((ball_current_pixel + ball_radius - ball_current_x_vel) >= (Border_Line_Left - Border_Line_Thickness)) and 
						((ball_current_line - ball_radius - ball_current_y_vel < Border_Goal_Top) or
						(ball_Current_line + ball_radius - ball_current_y_vel > Border_Goal_Bottom)) then
						ball_next_state	<= moving;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= 0 - ball_current_x_vel;
						ball_next_y_vel 	<= ball_current_y_vel;
						
					-- If going to hit right wall
					elsif ((ball_current_pixel - ball_radius - ball_current_x_vel) <= Border_Line_Right) and 
						((ball_current_line - ball_radius - ball_current_y_vel < Border_Goal_Top) or
						(ball_Current_line + ball_radius - ball_current_y_vel > Border_Goal_Bottom)) then
						ball_next_state	<= moving;
						ball_next_pixel	<= ball_current_pixel;
						ball_next_line		<= ball_current_line;
						ball_next_x_vel	<= 0 - ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
						
					-- If going to hit top wall
					elsif (ball_current_line - ball_radius - ball_current_y_vel) <= (Border_Line_Top + Border_Line_Thickness) then
						ball_next_state	<= moving;
						ball_next_pixel	<= ball_current_pixel;
						ball_next_line		<= ball_current_line;
						ball_next_x_vel	<= ball_current_x_vel;
						ball_next_y_vel	<= 0 - ball_current_y_vel;
						
					-- If going to hit bottom wall
					elsif (ball_current_line + ball_radius - ball_current_y_vel) >= Border_Line_Bottom then
						ball_next_state	<= moving;
						ball_next_pixel	<= ball_current_pixel;
						ball_next_line		<= ball_current_line;
						ball_next_x_vel	<= ball_current_x_vel;
						ball_next_y_vel	<= 0 - ball_current_y_vel;
						
						
					-- If traveling horizontally right and going to hit obstacle 1
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel > 0)) and 
							((ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1) and 
							(ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and
							(ball_current_line + ball_radius >= TOP_OB_Line) and 
							(ball_current_line - ball_radius <= TOP_OB_Line + OB_Width)) then
						-- Bounce left
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
					-- If traveling horizontally right and going to hit center obstacle
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel > 0)) and 
							((ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel) and 
							(ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
							(ball_current_line + ball_radius >= C_OB_Line) and 
							(ball_current_line - ball_radius <= C_OB_LIne + OB_Width)) then
						-- Bounce left
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
					-- If traveling horizontally right and going to hit obstable 5
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel > 0)) and 
							(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1) and 
							(ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and
							(ball_current_line + ball_radius >= Bottom_OB_Line) and 
							(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width) then
						-- Bounce left
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
						
					-- If traveling horizontally left and going to hit obstacle 4
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel < 0)) and 
							((ball_current_pixel + ball_radius - ball_current_x_vel >= (OB_Col_4 - OB_Width)) and 
							(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4) and
							(ball_current_line + ball_radius >= TOP_OB_Line) and 
							(ball_current_line - ball_radius <= TOP_OB_Line + OB_Width)) then
						-- Bounce right
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
						
					-- If traveling horizontally left and going to hit center obstacle
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel < 0)) and 
							((ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
							(ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel) and
							(ball_current_line + ball_radius >= C_OB_Line) and 
							(ball_current_line - ball_radius <= C_OB_Line + OB_Width)) then
						-- Bounce right
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
						
					-- If traveling horizontally left and going to hit obstable 8
					elsif ((ball_current_y_vel = 0) and (ball_current_x_vel < 0)) and 
							((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
							(ball_current_pixel - ball_radius - ball_current_x_Vel <= OB_Col_4) and
							(ball_current_line + ball_radius >= Bottom_OB_Line) and 
							(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width)) then
						-- Bounce right
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= -ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
					
					-- Object 1 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
						
					-- Object 2 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 3 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 4 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Top_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Top_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Top_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Top_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 5 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_1 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_1)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 6 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_2 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_2)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 7 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_3 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_3)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
					
					-- Object 8 Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= Bottom_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= OB_Col_4 - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= OB_Col_4)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= Bottom_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= Bottom_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= Bottom_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- Center Object Collisions ------------------------------------------------------------------------------
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel)) and
						-- If going to hit side
						(ball_current_line - ball_radius <= C_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= C_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= C_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling upwards
					elsif (ball_current_y_vel > 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel)) and
						-- If going to hit bottom
						(ball_current_line - ball_radius >= C_OB_Line + OB_Width) and
						(ball_current_line + ball_radius - ball_current_y_vel >= C_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= C_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel)) and
						-- If going to hit side
						(ball_current_line + ball_radius >= C_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= C_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= C_OB_Line + OB_Width) then
							-- Bounce horizontally
							ball_next_state	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel 	<= -ball_current_x_vel;
							ball_next_y_vel 	<= ball_current_y_vel;
							
					-- If traveling downwards
					elsif (ball_current_y_vel < 0) and 
						-- Going to hit OB 1
						((ball_current_pixel + ball_radius - ball_current_x_vel >= C_OB_Pixel - OB_Width) and 
						(ball_current_pixel - ball_radius - ball_current_x_vel <= C_OB_Pixel)) and
						-- If going to hit top
						(ball_current_line + ball_radius <= C_OB_Line) and
						(ball_current_line + ball_radius - ball_current_y_vel >= C_OB_Line) and
						(ball_current_line - ball_radius - ball_current_y_vel <= C_OB_Line + OB_Width)	then
							-- Bounce vertically
							ball_next_state 	<= ball_current_state;
							ball_next_pixel 	<= ball_current_pixel;
							ball_next_line 	<= ball_current_line;
							ball_next_x_vel	<= ball_current_x_vel;
							ball_next_y_vel	<= -ball_current_y_vel;
							
					-- Update ball on last pixel of last Vert C data
					elsif (lin_count = LAST_C_V) and (VGA_current_state = D) and (pix_count = 0) then
						ball_next_state 	<= Moving;
						ball_next_pixel 	<= ball_current_pixel - ball_current_x_vel;
						ball_next_line 	<= ball_current_line - ball_current_y_vel;
						ball_next_x_vel 	<= ball_current_x_vel;
						ball_next_y_vel 	<= ball_current_y_vel;
						
					-- Otherwise, no changes
					else
						ball_next_state 	<= ball_current_state;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel	<= ball_current_x_vel;
						ball_next_y_vel	<= ball_current_y_vel;
						
					end if;				
				end if;
			
			when Scored =>
				next_score_1 <= score_1;
				next_score_2 <= score_2;
				-- If new-ball
				if KEY(1) = '0' then
					ball_next_state 	<= Waiting;
					ball_next_pixel	<= 320;
					ball_next_line 	<= to_integer(last_C_V) + 60;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel 	<= 0;
				else
					-- No change
					ball_next_state 	<= ball_current_state;
					ball_next_pixel 	<= ball_current_pixel;
					ball_next_line 	<= ball_current_line;
					ball_next_x_vel	<= ball_current_x_vel;
					ball_next_y_vel	<= ball_current_y_vel;
				end if;
		end case;
	end process;
	
	-- VGA/Board Timing --
	process ( c0_sig ) -- Sensitivity list goes in ()
	begin
		if rising_edge( c0_sig ) then
				
			-- If Reset
			if (KEY(0) = '0') or (locked_sig = '0') then
				-- Reset behavior --
				pix_count <= next_pix_count;
				lin_count <= next_lin_count;
				timer <= next_timer;
				current_VGA_R  <= next_VGA_R; 
				current_VGA_G  <= next_VGA_G; 
				current_VGA_B  <= next_VGA_B; 
				current_VGA_HS <= next_VGA_HS;
				current_VGA_VS <= next_VGA_VS;
				VGA_current_state <= Clear;
				
			else
				-- Normal behavior --
				pix_count <= next_pix_count;
				lin_count <= next_lin_count;
				timer 	 <= next_timer;
				current_VGA_R  <= next_VGA_R; 
				current_VGA_G  <= next_VGA_G; 
				current_VGA_B  <= next_VGA_B; 
				current_VGA_HS <= next_VGA_HS;
				current_VGA_VS <= next_VGA_VS;
				VGA_current_state <= VGA_next_state;
			end if;
		end if;
	end process;
	
	
	-- VGA/Board FSM --
	process ( VGA_current_state, pix_count, KEY, lin_count, timer, current_VGA_HS, current_VGA_VS, current_VGA_R, current_VGA_G, current_VGA_B, ball_current_line, ball_current_pixel )
	begin
		case VGA_current_state is
			when Clear => 
				-- Drive data low --
				next_VGA_R	<= "0000";
				next_VGA_G	<= "0000";
				next_VGA_B	<= "0000";
				-- Sync high
				next_VGA_HS <= '1';
				next_VGA_VS <= '1';
				
				if KEY(0) = '0' then
					-- Reset counters
					next_pix_count <= 0;
					next_lin_count <= to_unsigned(0, lin_count'length);
					next_timer <= 0;
					VGA_next_state <= Clear;
				else				
					-- Prep for state A
					next_pix_count <= A_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= A;
				end if;
				
			-- Horizontal A
			when A => 
				
				-- Drive data low --
				next_VGA_R	<= "0000";
				next_VGA_G	<= "0000";
				next_VGA_B	<= "0000";
				
				-- In Horizontal A
				if pix_count /= 0 then 
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= A;
					-- Hor Sync high
					next_VGA_HS <= '1';
					-- If in vertical A
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						-- Vert Sync low
						next_VGA_VS <= '0';
					else
						-- Vert Sync high
						next_VGA_VS <= '1';
					end if;
					
				-- Last pixel in horizontal A
				else
					next_pix_count <= B_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= B;
					
					-- Hor Sync low
					next_VGA_HS <= '0';
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				end if;
				
			-- Horizontal B
			when B => 
			
				-- Drive data low --
				next_VGA_R	<= "0000";
				next_VGA_G	<= "0000";
				next_VGA_B	<= "0000";
				-- Sync low
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= B;
					next_VGA_HS <= current_VGA_HS;
					next_VGA_VS <= current_VGA_VS;
				else
					next_pix_count <= C_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= C;
					next_VGA_HS <= '1';
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				end if;
				
			-- Horizontal C
			when C => 
				
				-- Sync high
				next_VGA_HS <= '1';
				if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				-- If in Hor C
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= C;
					next_VGA_R <= "0000";
					next_VGA_G <= "0000";
					next_VGA_B <= "0000";				
				else
					next_pix_count <= D_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= D;
					if lin_count > LAST_C_V then
						-- Initial Pixel Column Data Here --
						-- Always starts black
						next_VGA_R <= "0000";
						next_VGA_G <= "0000";
						next_VGA_B <= "0000";				
					else
						-- Always starts black
						next_VGA_R <= "0000";
						next_VGA_G <= "0000";
						next_VGA_B <= "0000";				
					end if;
				end if;
				
			-- Horizontal D
			when D =>
				next_VGA_R  <= current_VGA_R; 
				next_VGA_G  <= current_VGA_G; 
				next_VGA_B  <= current_VGA_B;
				-- Sync high
				next_VGA_HS <= '1';
				
				-- If in data
				if pix_count /= 0 then
				
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					VGA_next_state <= D;
					
					-- If in Vert B
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						-- Reset Vert Sync
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;					
					if lin_count > LAST_C_V then

						-- Display Pixel Data Here --
						-- If inside vertical boundaries
						if (lin_count > Border_Line_Top) and (lin_count < Border_Line_Bottom + Border_Line_Thickness) then
						
							-- If inside horizontal boundaries
							
							if (pix_count < Border_Line_Left) and (pix_count > Border_Line_Right-Border_Line_Thickness) then
							
								-- If on the top or bottom lines
								if(lin_count < Border_Line_Top+Border_Line_Thickness) or (lin_count > Border_Line_Bottom) then
									-- Display white
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
									
								-- Or if on left or right sides, and not in goal
								elsif ((pix_count > Border_Line_Left - Border_Line_Thickness) or (pix_count < Border_Line_Right)) and ((lin_count < Border_Goal_Top) or (lin_count > Border_Goal_Bottom))then
									-- Display white
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
													
								-- Or if at center obstacle
								elsif (pix_count < C_OB_Pixel and pix_count > C_OB_Pixel-OB_Width) and (lin_count > C_OB_Line and lin_count < C_OB_Line + OB_Width) then
									-- Display Red
									next_VGA_R <= "1111";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								
								-- Or if at top row of obstacles
								elsif (lin_count > Top_OB_Line and lin_count < Top_OB_Line+OB_Width) and (pix_count < OB_COL_1) and (pix_count > OB_COL_4 - OB_WIDTH) then
									-- If first column
									if (pix_count < OB_Col_1 and pix_count > OB_Col_1-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If second column
									elsif (pix_count < OB_Col_2 and pix_count > OB_Col_2-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If third column
									elsif (pix_count < OB_Col_3 and pix_count > OB_Col_3-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If fourth column
									elsif (pix_count < OB_Col_4 and pix_count > OB_Col_4-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- In between columns
									else
										-- If right above ball
										if (lin_count >= ball_current_line) and ((lin_count - ball_current_line) <= ball_radius) then
											
											-- Just left of ball
											if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											-- Just right of ball
											elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											else
												-- Blackspace
												next_VGA_R <= "0000";
												next_VGA_G <= "0000";
												next_VGA_B <= "0000";
											end if;
										
										-- If right below ball
										elsif (lin_count < ball_current_line) and ((ball_current_line - lin_count) <= ball_radius) then
											
											-- Just left of ball
											if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											-- Just right of ball
											elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											else
												-- Blackspace
												next_VGA_R <= "0000";
												next_VGA_G <= "0000";
												next_VGA_B <= "0000";
											end if;
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									end if;
								
								-- Or if at bottom row of obstacles
								elsif (lin_count > Bottom_OB_Line and lin_count < Bottom_OB_Line+OB_Width) and (pix_count < OB_COL_1) and (pix_count > OB_COL_4 - OB_WIDTH) then
									-- If first column
									if (pix_count < OB_Col_1 and pix_count > OB_Col_1-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If second column
									elsif (pix_count < OB_Col_2 and pix_count > OB_Col_2-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If third column
									elsif (pix_count < OB_Col_3 and pix_count > OB_Col_3-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- If fourth column
									elsif (pix_count < OB_Col_4 and pix_count > OB_Col_4-OB_Width) then
										-- Display Red
										next_VGA_R <= "1111";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									-- In between obstacles
									else
										-- If right above ball
										if (lin_count >= ball_current_line) and ((lin_count - ball_current_line) <= ball_radius) then
											
											-- Just left of ball
											if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											-- Just right of ball
											elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											else
												-- Blackspace
												next_VGA_R <= "0000";
												next_VGA_G <= "0000";
												next_VGA_B <= "0000";
											end if;
										
										-- If right below ball
										elsif (lin_count < ball_current_line) and ((ball_current_line - lin_count) <= ball_radius) then
											
											-- Just left of ball
											if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											-- Just right of ball
											elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
												-- Paint ball
												next_VGA_R <= "1111";
												next_VGA_G <= "1111";
												next_VGA_B <= "1111";
											
											else
												-- Blackspace
												next_VGA_R <= "0000";
												next_VGA_G <= "0000";
												next_VGA_B <= "0000";
											end if;
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									end if;	
		
								--Paddle 1
								elsif (pix_count >= 37) and (pix_count < 42) and (lin_count > 65) and (lin_count < 385) and (lin_count >= player_1) and (lin_count < player_1 + 40) then
									if (player_1 > 65) and (player_1 < 345) then
										if (lin_count >= player_1) and (lin_count < player_1 + 40) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										elsif (lin_count < player_1) and (lin_count > player_1) then
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif player_1 <= 65 then
										if (lin_count >= 65) and (lin_count < 105) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif player_1 >= 345 then
										if (lin_count >= 345) and (lin_count < 385) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								--Paddle 2
								elsif (pix_count >= 597) and (pix_count < 602) and (lin_count > 65) and (lin_count < 385) and (lin_count >= player_2) and (lin_count < player_2 + 40)then
									if (player_2 > 65) and (player_2 < 345) then
										if (lin_count >= player_2) and (lin_count < player_2 + 40) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif player_2 <= 65 then
										if (lin_count >= 65) and (lin_count < 105) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif player_2 >= 345 then
										if (lin_count >= 345) and (lin_count < 385) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1010";
											next_VGA_B <= "0100";
										else
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
									
								-- Else empty board space
								else
									-- If right above ball
									if (lin_count >= ball_current_line) and ((lin_count - ball_current_line) <= ball_radius) then
										
										-- Just left of ball
										if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
											-- Paint ball
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										
										-- Just right of ball
										elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
											-- Paint ball
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										
										else
											-- Blackspace
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									
									-- If right below ball
									elsif (lin_count < ball_current_line) and ((ball_current_line - lin_count) <= ball_radius) then
										
										-- Just left of ball
										if (pix_count <= ball_current_pixel) and ((ball_current_pixel - pix_count) <= ball_radius) then
											-- Paint ball
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										
										-- Just right of ball
										elsif (pix_count > ball_current_pixel) and ((pix_count - ball_current_pixel) <= ball_radius) then
											-- Paint ball
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										
										else
											-- Blackspace
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;

									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								end if;
							else
								next_VGA_R <= "0000";
								next_VGA_G <= "0000";
								next_VGA_B <= "0000";
							end if;
						--Add Scoring
						elsif (lin_count > 400)  and (lin_count <= 430) then
							if (pix_count <= 490) and (pix_count > 470) then
								if score_1 = 0 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif ((pix_count <= 490) and (pix_count > 486)) or ((pix_count < 475) and (pix_count > 470)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_1 = 1 then
									if (pix_count <= 475) and (pix_count > 470) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_1 = 2 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 475) and (pix_count > 470) then
										if (lin_count > 405) and (lin_count <= 412) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (pix_count <= 490) and (pix_count > 485) then
										if (lin_count >= 418) and (lin_count <= 425) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_1 = 3 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 475) and (pix_count > 470) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_1 = 4 then
									if (lin_count >= 400) and (lin_count < 412) then
										if (pix_count <= 490) and (pix_count > 486) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										elsif (pix_count <= 475) and (pix_count > 470) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (lin_count >= 412) and (lin_count < 418) then
										if (pix_count <= 490) and (pix_count > 470) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (lin_count >= 418) and (lin_count < 430) then
										if (pix_count < 475) and (pix_count > 470) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_1 = 5 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 490) and (pix_count > 485) then
										if (lin_count > 405) and (lin_count <= 412) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (pix_count <= 475) and (pix_count > 470) then
										if (lin_count >= 418) and (lin_count <= 425) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								end if;
							elsif (pix_count <= 140) and (pix_count > 120) then
								if score_2 = 0 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif ((pix_count <= 140) and (pix_count > 136)) or ((pix_count < 125) and (pix_count > 120)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_2 = 1 then
									if (pix_count <= 125) and (pix_count > 120) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_2 = 2 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 125) and (pix_count > 120) then
										if (lin_count > 405) and (lin_count <= 412) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (pix_count <= 140) and (pix_count > 135) then
										if (lin_count >= 418) and (lin_count <= 425) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_2 = 3 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 125) and (pix_count > 120) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_2 = 4 then
									if (lin_count >= 400) and (lin_count < 412) then
										if (pix_count <= 140) and (pix_count > 135) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										elsif (pix_count <= 125) and (pix_count > 120) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (lin_count >= 412) and (lin_count < 418) then
										if (pix_count <= 140) and (pix_count > 120) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (lin_count >= 418) and (lin_count < 430) then
										if (pix_count < 125) and (pix_count > 120) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								elsif score_2 = 5 then
									if ((lin_count > 400) and (lin_count <= 405)) or ((lin_count > 412) and (lin_count < 418)) or ((lin_count > 425) and (lin_count <= 430)) then
										next_VGA_R <= "1111";
										next_VGA_G <= "1111";
										next_VGA_B <= "1111";
									elsif (pix_count <= 140) and (pix_count > 135) then
										if (lin_count > 405) and (lin_count <= 412) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									elsif (pix_count <= 125) and (pix_count > 120) then
										if (lin_count >= 418) and (lin_count <= 425) then
											next_VGA_R <= "1111";
											next_VGA_G <= "1111";
											next_VGA_B <= "1111";
										else 
											next_VGA_R <= "0000";
											next_VGA_G <= "0000";
											next_VGA_B <= "0000";
										end if;
									else 
										next_VGA_R <= "0000";
										next_VGA_G <= "0000";
										next_VGA_B <= "0000";
									end if;
								end if;
							else 
								next_VGA_R <= "0000";
								next_VGA_G <= "0000";
								next_VGA_B <= "0000";
							end if;
						else
							next_VGA_R <= "0000";
							next_VGA_G <= "0000";
							next_VGA_B <= "0000";
						end if;
						
						
					else
						next_VGA_R <= "0000";
						next_VGA_G <= "0000";
						next_VGA_B <= "0000";
					end if;
				
				-- Last pixel
				else
				
					-- Reset pix_count to Hor A
					next_pix_count <= A_COUNT_H;
										
					-- If Last line
					if lin_count = L_COUNT then					
						-- Reset lin_count
						next_lin_count <= to_unsigned(0, lin_count'length);
						
--					elsif (lin_count > LAST_C_V) then
--						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
					else
						-- Else increment lin_count
						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
					end if;
					next_timer <= timer;
					VGA_next_state <= A;
					next_VGA_R <= "0000";
					next_VGA_G <= "0000";
					next_VGA_B <= "0000";
					next_VGA_HS <= current_VGA_HS;
					if (lin_count >= LAST_A_V) and (lin_count < LAST_B_V) then
							next_VGA_VS <= '0';
						else
							next_VGA_VS <= '1';
						end if;
				end if;
				
			when Debounce =>
				--If timer = DELAY
				if timer = DELAY then
					--If add is still pressed
					if KEY(1) = '0' then
						--Next state is pressed
						next_pix_count <= D_COUNT_H;
						next_lin_count <= lin_count;
						next_timer <= timer;
						VGA_next_state <= Debounce;
						next_VGA_R 	<= current_VGA_R;
						next_VGA_G 	<= current_VGA_G;
						next_VGA_B 	<= current_VGA_B;
						next_VGA_HS <= current_VGA_HS;
						next_VGA_VS <= current_VGA_VS;
					else
						next_pix_count <= A_COUNT_H;
						next_lin_count <= to_unsigned(0, lin_count'length);
						next_timer <= 0;
						VGA_next_state <= A;
						next_VGA_R 	<= "0000";
						next_VGA_G 	<= "0000";
						next_VGA_B 	<= "0000";
						next_VGA_HS <= '1';
						next_VGA_VS <= '1';
					end if;
				else
					--Increment timer
					next_pix_count <= pix_count;
					next_lin_count <= lin_count;
					next_timer <= timer + 1;
					VGA_next_state <= Debounce;
					next_VGA_R 	<= current_VGA_R;
					next_VGA_G 	<= current_VGA_G;
					next_VGA_B 	<= current_VGA_B;
					next_VGA_HS <= current_VGA_HS;
					next_VGA_VS <= current_VGA_VS;
				end if;
				
			when others =>
				next_pix_count <= pix_count;
				next_lin_count <= lin_count;
				next_timer <= timer;
				VGA_next_state  <= Clear;
				next_VGA_R  <= current_VGA_R;
				next_VGA_G  <= current_VGA_G;
				next_VGA_B  <= current_VGA_B;
				next_VGA_HS <= current_VGA_HS;
				next_VGA_VS <= current_VGA_VS;
			
		end case;
	end process;
	
	-- Send current_VGA data to outputs
	process ( current_VGA_R, current_VGA_G, current_VGA_B, current_VGA_HS, current_VGA_VS )
	begin
		VGA_R  <= current_VGA_R;
		VGA_G  <= current_VGA_G;
		VGA_B  <= current_VGA_B;
		VGA_HS <= current_VGA_HS;
		VGA_VS <= current_VGA_VS;
	end process;
	
	-- Timing Controller --
	process (MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then
			if sample_counter < SAMPLE_PERIOD - 1 then
				sample_counter <= sample_counter + 1;
				sample_trigger <= '0';
			else
				sample_counter <= 0;
				sample_trigger <= '1';
			end if;
		end if;
	end process;
	
	-- Sampling controller --
	process (MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then
			if (response_valid = '1') then
				if command_channel = "00001" then
					temp_player <= to_integer(shift_right(response_data,2));
					if (temp_player >= 345) then
						player_1 <= to_unsigned(345, 13);
					elsif (temp_player <= 65) then
						player_1 <= to_unsigned(65, 13);
					else
						player_1 <= to_unsigned(temp_player, player_1'length);
					end if;
					command_channel <= "00010";
				elsif command_channel = "00010" then
					temp_player <= to_integer(shift_right(response_data, 2));
					if (temp_player >= 345) then
						player_2 <= to_unsigned(345, 13);
					elsif (temp_player <= 65) then
						player_2 <= to_unsigned(65, 13);
					else
						player_2 <= to_unsigned(temp_player, player_2'length);
					end if;
					command_channel <= "00001";
				end if;
			end if;
		end if;
	end process;

end architecture behavioral;
