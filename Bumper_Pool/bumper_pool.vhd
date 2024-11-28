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
		DELAY			: integer := 500000
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
		VGA_VS	: out std_logic
	);

end entity Bumper_Pool;

architecture behavioral of Bumper_Pool is

	-- Components --
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
		Moving
	);
	
	signal ball_current_state, ball_next_state: Ball_state_type;

begin

	-- Define module behavior here --
	-- Instantiate components --
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
			
			-- Normal behavior
			else
				-- State
				ball_current_state 	<= ball_next_state;
				
				-- Position and Velocity
				ball_current_pixel	<= ball_next_pixel;
				ball_current_line		<= ball_next_line;
				ball_current_x_vel	<= ball_next_x_vel;
				ball_current_y_vel	<= ball_next_y_vel;
			end if;
			
		end if;
	end process;
	
	-- Ball Control FSM --
	process ( KEY, ball_current_state, ball_current_pixel, ball_current_line, ball_current_x_vel, ball_current_y_vel, lin_count, VGA_current_state, pix_count, locked_sig )
	begin
		case ball_current_state is
			when Hidden =>
				-- If Reset pressed
				if (KEY(0) = '0')  or (locked_sig = '0') then
					ball_next_state	<= Hidden;
					ball_next_pixel	<= 0;
					ball_next_line		<= 0;
					ball_next_x_vel	<= 0;
					ball_next_y_vel	<= 0;
				
				-- If New-Ball pressed
				elsif KEY(1) = '0' then
					ball_next_state 	<= Waiting;
					ball_next_pixel	<= to_integer(OB_Col_4)-43;--320;
					ball_next_line 	<= to_integer(Top_OB_Line);--to_integer(last_C_V) + 60;
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
				-- If New-Ball released
				if KEY(1) = '1' then
					ball_next_state <= Moving;
					ball_next_x_vel <= -5;
					ball_next_y_vel <= 0;
					
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
				-- If Reset pressed
				if (KEY(0) = '0')  or (locked_sig = '0') then
					ball_next_state	<= Hidden;
					ball_next_pixel 	<= 0;
					ball_next_line 	<= 0;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel	<= 0;
				
				-- If New-Ball pressed
				elsif KEY(1) = '0' then
					ball_next_state	<= Waiting;
					ball_next_pixel 	<= to_integer(OB_Col_4)-43;--320;
					ball_next_line 	<= to_integer(Top_OB_Line);--to_integer(last_C_V) + 60;
					ball_next_x_vel 	<= 0;
					ball_next_y_vel 	<= 0;
		
				-- Normal Behavior
				else
					-- If going to hit left wall
					if (ball_current_pixel + ball_radius - ball_current_x_vel) >= (Border_Line_Left - Border_Line_Thickness) then
						ball_next_state	<= moving;
						ball_next_pixel 	<= ball_current_pixel;
						ball_next_line 	<= ball_current_line;
						ball_next_x_vel 	<= 0 - ball_current_x_vel;
						ball_next_y_vel 	<= ball_current_y_vel;
						
					-- If going to hit right wall
					elsif (ball_current_pixel - ball_radius - ball_current_x_vel) <= Border_Line_Right then
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
					
					-- If traveling upwards
						-- If going to hit obstacle 1
							-- If top of ball above bottom of obstacle
								-- Bounce vertically
							-- If top of ball below bottom of obstable
								-- Bounce horizontally
						-- If going to hit obstacle 2
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 3
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 4
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit center obstacle
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 5
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 6
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 7
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- If going to hit obstacle 8
							-- If top of ball above bottom of obstacle
								-- Bounce horizontally
							-- If top of ball below bottom of obstable
								-- Bounce vertically
						-- Otherwise
							-- No change
					
					-- If traveling downwards
						-- If going to hit obstacle 1
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 2
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 3
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 4
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit center obstacle
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 5
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 6
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 7
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- If going to hit obstacle 8
							-- If bottom of ball above top of obstacle
								-- Bounce vertically
							-- If bottom of ball below top of obstacle
								-- Bounce horizontally
						-- Otherwise
							-- No change
					
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
								elsif (lin_count > Top_OB_Line and lin_count < Top_OB_Line+OB_Width) then
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
								elsif (lin_count > Bottom_OB_Line and lin_count < Bottom_OB_Line+OB_Width) then
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

end architecture behavioral;
