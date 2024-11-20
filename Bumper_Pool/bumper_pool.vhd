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
	signal Border_Line_Thickness	: integer := 3;
	signal Border_Line_Top		: integer := 17;
	signal Border_Line_Left		: integer := 17;

	-- FSM States
	type state_type is (
		Clear,
		A,
		B,
		C,
		D,
		Debounce
		);
	
	signal current_state, next_state: state_type;

begin

	-- Define module behavior here --
	
	-- Make future the present --
	process ( MAX10_CLK1_50 ) -- Sensitivity list goes in ()
	begin
		if rising_edge( MAX10_CLK1_50 ) then
			-- Only trigger every other clock cycle (25 MHz)
			if clk_count = 1 then
				clk_count <= 0;
				
				-- If Reset
				if KEY(0) = '0' then
					-- Reset behavior --
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					timer <= next_timer;
					current_VGA_R  <= next_VGA_R; 
					current_VGA_G  <= next_VGA_G; 
					current_VGA_B  <= next_VGA_B; 
					current_VGA_HS <= next_VGA_HS;
					current_VGA_VS <= next_VGA_VS;
					current_state <= Clear;
				-- If next
				elsif KEY(1) = '0' then
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					timer	<= next_timer;
					current_VGA_R  <= next_VGA_R; 
					current_VGA_G  <= next_VGA_G; 
					current_VGA_B  <= next_VGA_B; 
					current_VGA_HS <= next_VGA_HS;
					current_VGA_VS <= next_VGA_VS;
					current_state <= Debounce;
					-- Continue same flag
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
					current_state <= next_state;
				end if;
			else
				clk_count <= clk_count + 1;
			end if;
		end if;
	end process;
	
	
	-- Determine the future --
	process ( current_state, pix_count, KEY, lin_count, timer )
	begin
		case current_state is
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
					next_state <= Clear;
				else				
					-- Prep for state A
					next_pix_count <= A_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= A;
				end if;
				
			when A => 
				-- Drive data low --
				next_VGA_R	<= "0000";
				next_VGA_G	<= "0000";
				next_VGA_B	<= "0000";
				-- Sync high
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= A;
					next_VGA_HS <= '1';
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				else
					next_pix_count <= B_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= B;
					next_VGA_HS <= '0';
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				end if;
				
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
					next_state <= B;
					next_VGA_HS <= current_VGA_HS;
					next_VGA_VS <= current_VGA_VS;
				else
					next_pix_count <= C_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= C;
					next_VGA_HS <= '1';
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				end if;
				
			when C => 
				-- Sync high
				next_VGA_HS <= '1';
				if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= C;
					next_VGA_R <= "0000";
					next_VGA_G <= "0000";
					next_VGA_B <= "0000";				
				else
					next_pix_count <= D_COUNT_H;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= D;
					if lin_count > LAST_C_V then

						-- Initial Pixel Column Data Here --
					else
						next_VGA_R <= "1111";
						next_VGA_G <= "1111";
						next_VGA_B <= "1111";				
					end if;
				end if;
				
			when D =>
				-- Sync high
				next_VGA_HS <= '1';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_timer <= timer;
					next_state <= D;
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
					if lin_count > LAST_C_V then

						-- Display Pixel Data Here --
						next_VGA_R <= "1111";	
						next_VGA_G <= "1111";	
						next_VGA_B <= "1111";	
					else
						next_VGA_R <= "0000";
						next_VGA_G <= "0000";
						next_VGA_B <= "0000";
					end if;
				-- Last pixel
				else
					next_pix_count <= A_COUNT_H;
					if lin_count = L_COUNT then
						next_lin_count <= to_unsigned(0, lin_count'length);
					elsif (lin_count > LAST_C_V) then
						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
					else
						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
					end if;
					next_timer <= timer;
					next_state <= A;
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
						next_state <= Debounce;
						next_VGA_R 	<= current_VGA_R;
						next_VGA_G 	<= current_VGA_G;
						next_VGA_B 	<= current_VGA_B;
						next_VGA_HS <= current_VGA_HS;
						next_VGA_VS <= current_VGA_VS;
					else
						next_pix_count <= A_COUNT_H;
						next_lin_count <= to_unsigned(0, lin_count'length);
						next_timer <= 0;
						next_state <= A;
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
					next_state <= Debounce;
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
				next_state  <= Clear;
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
