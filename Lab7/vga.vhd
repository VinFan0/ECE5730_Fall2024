library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by ; ) --
		A_COUNT : integer := 16;
		B_COUNT : integer := 96;
		C_COUNT : integer := 48;
		D_COUNT : integer := 640;
		L_COUNT : integer := 525;
		F_COUNT	: integer := 12;
		DELAY	: integer := 2500000
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

end entity vga;

architecture behavioral of vga is

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	
	signal pix_count 			: integer := 0;
	signal next_pix_count	: integer := 0;
	signal lin_count 			: integer := 0;
	signal next_lin_count 	: integer := 0;
	signal flg_count 			: integer := 0;
	signal next_flg_count 	: integer := 0;
	signal clk_count 			: integer := 0;
	signal next_clk_count 	: integer := 0;
	
	signal timer 				: integer := 0;	-- Timer for debounce
	signal next_timer 		: integer := 0;
	
	signal next_VGA_R  		: std_logic_vector(3 downto 0);
	signal next_VGA_G  		: std_logic_vector(3 downto 0);
	signal next_VGA_B  		: std_logic_vector(3 downto 0);
	signal next_VGA_HS 		: std_logic;
	signal next_VGA_VS 		: std_logic;
	
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
					flg_count <= next_flg_count;
					timer <= next_timer;
					VGA_R  <= next_VGA_R; 
					VGA_G  <= next_VGA_G; 
					VGA_B  <= next_VGA_B; 
					VGA_HS <= next_VGA_HS;
					VGA_VS <= next_VGA_VS;
					current_state <= Clear;
					
				-- If next
				elsif KEY(1) = '0' then
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					flg_count <= next_flg_count;
					timer	<= next_timer;
					VGA_R  <= next_VGA_R; 
					VGA_G  <= next_VGA_G; 
					VGA_B  <= next_VGA_B; 
					VGA_HS <= next_VGA_HS;
					VGA_VS <= next_VGA_VS;
					current_state <= Debounce;
				-- Continue same flag
				else
					-- Normal behavior --
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					flg_count <= next_flg_count;
					timer 	 <= next_timer;
					VGA_R  <= next_VGA_R; 
					VGA_G  <= next_VGA_G; 
					VGA_B  <= next_VGA_B; 
					VGA_HS <= next_VGA_HS;
					VGA_VS <= next_VGA_VS;
					current_state <= next_state;
				end if;
			else
				clk_count <= clk_count + 1;
			end if;
		end if;
	end process;
	
	
	-- Determine the future --
	process ( current_state, pix_count, KEY, lin_count, timer, flg_count)
	begin
		case current_state is
			when Clear => 
				next_VGA_R	= '0000'
				next_VGA_G	= '0000'
				next_VGA_B	= '0000'
				next_VGA_HS = '1';
				next_VGA_VS = '1';
				if KEY(0) = '0' then
					-- Reset counters
					next_pix_count <= 0;
					next_lin_count <= 0;
					next_flg_count <= 0;
					next_timer <= 0;
					next_state <= Clear;
				else				
					-- Prep for state A
					next_pix_count <= A_COUNT;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= A;
				end if;
				
			when A => 
				next_VGA_R	= '0000'
				next_VGA_G	= '0000'
				next_VGA_B	= '0000'
				next_VGA_HS = '1';
				next_VGA_VS = '1';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= A;
				else
					next_pix_count <= B_COUNT;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= B;
					
					
				end if;
				
			when B => 
				next_VGA_R	= '0000'
				next_VGA_G	= '0000'
				next_VGA_B	= '0000'
				next_VGA_HS = '0';
				next_VGA_VS = '0';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= B;
				else
					next_pix_count <= C_COUNT;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= C;
				end if;
				
			when C => 
				next_VGA_R	= '0000'
				next_VGA_G	= '0000'
				next_VGA_B	= '0000'
				next_VGA_HS = '1';
				next_VGA_VS = '1';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= C;
				else
					next_pix_count <= D_COUNT;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= D;
				end if;
				
			when D =>
				next_VGA_HS = '1';
				next_VGA_VS = '1';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= D;
					--Flag Case
					case flg_count is
						when 0 =>
							--Flag 0 - France
							if (pix_count > 427) and (pix_count <= 640) then
								--BLUE = #002395
								VGA_R <= '0000';
								VGA_G <= '0010';
								VGA_B <= '1001';
							elsif (pix_count > 213) and (pix_count <= 427) then
								--White = #FFFFFF
								VGA_R <= '1111';
								VGA_G <= '1111';
								VGA_B <= '1111';
							elsif pix_count <= 213 then
								--RED = #ed2939
								VGA_R <= '1110';
								VGA_G <= '0010';
								VGA_B <= '0011';
							end if;
					end case;		
				else
					next_pix_count <= A_COUNT;
					if lin_count = L_COUNT then
						next_lin_count <= 0;
					else
						next_lin_count <= lin_count + 1;
					end if;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= A;
				end if;
				
			when Debounce =>
				--If timer = DELAY
				if timer = DELAY then
					--If add is still pressed
					if KEY(1) = '0' then
						--Next state is pressed
						next_pix_count <= D_COUNT;
						next_lin_count <= lin_count;
						next_flg_count <= flg_count;
						next_timer <= timer;
						next_state <= Debounce;
					else
						next_pix_count <= A_COUNT;
						next_lin_count <= 0;
						if flg_count = F_COUNT then
							next_flg_count <= 0;
						else
							next_flg_count <= flg_count + 1;
						end if;
						next_timer <= 0;
						next_state <= A;
					end if;
				else
					--Increment timer
					next_pix_count <= pix_count;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer + 1;
					next_state <= Debounce;
				end if;
				
			when others =>
				next_pix_count <= pix_count;
				next_lin_count <= lin_count;
				next_flg_count <= flg_count;
				next_timer <= timer;
				next_state <= Clear;
			
		end case;
	end process;

end architecture behavioral;
