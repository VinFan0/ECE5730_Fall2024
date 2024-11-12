library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga is

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
		-- Stripe size generics for simulating
		START_LEFT_STRIPE : integer := 640;
		END_LEFT_STRIPE 	: integer := 427;
		START_RIGHT_STRIPE: integer := 213
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
	signal lin_count 			: unsigned(9 downto 0) := to_unsigned(0, 10);
	signal next_lin_count 	: unsigned(9 downto 0) := to_unsigned(0, 10);
	signal flg_count 			: integer := 0;
	signal next_flg_count 	: integer := 0;
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
	
	signal LEFT_EDGE_YELLOW		: integer := 163;
	signal RIGHT_EDGE_YELLOW	: integer := 0;
	signal next_LEFT_EDGE_YELLOW	: integer := 163;
	signal next_RIGHT_EDGE_YELLOW	: integer := 0;
	
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
					current_VGA_R  <= next_VGA_R; 
					current_VGA_G  <= next_VGA_G; 
					current_VGA_B  <= next_VGA_B; 
					current_VGA_HS <= next_VGA_HS;
					current_VGA_VS <= next_VGA_VS;
					current_state <= Clear;
					LEFT_EDGE_YELLOW		<= next_LEFT_EDGE_YELLOW;
					RIGHT_EDGE_YELLOW 	<= next_RIGHT_EDGE_YELLOW;
					
				-- If next
				elsif KEY(1) = '0' then
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					flg_count <= next_flg_count;
					timer	<= next_timer;
					current_VGA_R  <= next_VGA_R; 
					current_VGA_G  <= next_VGA_G; 
					current_VGA_B  <= next_VGA_B; 
					current_VGA_HS <= next_VGA_HS;
					current_VGA_VS <= next_VGA_VS;
					current_state <= Debounce;
					LEFT_EDGE_YELLOW		<= next_LEFT_EDGE_YELLOW;
					RIGHT_EDGE_YELLOW 	<= next_RIGHT_EDGE_YELLOW;
				-- Continue same flag
				else
					-- Normal behavior --
					pix_count <= next_pix_count;
					lin_count <= next_lin_count;
					flg_count <= next_flg_count;
					timer 	 <= next_timer;
					current_VGA_R  <= next_VGA_R; 
					current_VGA_G  <= next_VGA_G; 
					current_VGA_B  <= next_VGA_B; 
					current_VGA_HS <= next_VGA_HS;
					current_VGA_VS <= next_VGA_VS;
					current_state <= next_state;
					LEFT_EDGE_YELLOW		<= next_LEFT_EDGE_YELLOW;
					RIGHT_EDGE_YELLOW 	<= next_RIGHT_EDGE_YELLOW;
				end if;
			else
				clk_count <= clk_count + 1;
			end if;
		end if;
	end process;
	
	
	-- Determine the future --
	process ( current_state, pix_count, KEY, lin_count, timer, flg_count )
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
				
				next_LEFT_EDGE_YELLOW	<= 163;
				next_RIGHT_EDGE_YELLOW 	<= 0;
				
				if KEY(0) = '0' then
					-- Reset counters
					next_pix_count <= 0;
					next_lin_count <= to_unsigned(0, lin_count'length);
					next_flg_count <= 0;
					next_timer <= 0;
					next_state <= Clear;
				else				
					-- Prep for state A
					next_pix_count <= A_COUNT_H;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= A;
				end if;
				
			when A => 
				if lin_count = to_unsigned(0, lin_count'length) then
					next_LEFT_EDGE_YELLOW	<= 163;
					next_RIGHT_EDGE_YELLOW 	<= 0;
				else
					next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
					next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
				end if;
				-- Drive data low --
				next_VGA_R	<= "0000";
				next_VGA_G	<= "0000";
				next_VGA_B	<= "0000";
				-- Sync high
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
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
					next_flg_count <= flg_count;
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
				next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
				next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
				-- Sync low
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= B;
					next_VGA_HS <= current_VGA_HS;
					next_VGA_VS <= current_VGA_VS;
				else
					next_pix_count <= C_COUNT_H;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
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
				next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
				next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
				if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= C;
					next_VGA_R <= "0000";
					next_VGA_G <= "0000";
					next_VGA_B <= "0000";				
				else
					next_pix_count <= D_COUNT_H;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= D;
					if lin_count > LAST_C_V then
						case flg_count is
							when 0 => 
								-- France
								next_VGA_R <= "0000";
								next_VGA_G <= "0010";
								next_VGA_B <= "1001";
							when 1 =>
								-- Italy
								next_VGA_R <= "0000";
								next_VGA_G <= "1001";
								next_VGA_B <= "0100";
							when 2=>
								-- Ireland
								next_VGA_R <= "0001";
								next_VGA_G <= "1001";
								next_VGA_B <= "0110";
							when 3 =>
								-- Belgium
								next_VGA_R <= "0000";
								next_VGA_G <= "0000";
								next_VGA_B <= "0000";
							when 4 =>
								-- Mali
								next_VGA_R <= "0001";
								next_VGA_G <= "1011";
								next_VGA_B <= "0011";
							when 5 =>
								-- Chad
								next_VGA_R <= "0000";
								next_VGA_G <= "0010";
								next_VGA_B <= "0110";
							when 6 =>
								-- Nigeria
								next_VGA_R <= "0000";
								next_VGA_G <= "1000";
								next_VGA_B <= "0101";
							when 7 =>
								-- Ivory Coast
								next_VGA_R <= "1111";
								next_VGA_G <= "1001";
								next_VGA_B <= "0000";
							when 8 =>
								-- Poland
								if (lin_count > to_unsigned(44, lin_count'length)) and (lin_count <= to_unsigned(284, lin_count'length)) then
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif (lin_count > to_unsigned(284, lin_count'length)) and (lin_count <= to_unsigned(524, lin_count'length)) then
									next_VGA_R <= "1101";
									next_VGA_G <= "0001";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= "0000";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								end if;
							when 9 =>
								--Flag 9-Germany
								if (lin_count > to_unsigned(44, lin_count'length)) and (lin_count <= to_unsigned(204, lin_count'length)) then
									--BLACK = #000000
									next_VGA_R <= "0000";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								elsif (lin_count > to_unsigned(204, lin_count'length)) and (lin_count <= to_unsigned(364, lin_count'length)) then
									--RED = #dd0000
									next_VGA_R <= "1101";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								elsif (lin_count > to_unsigned(364, lin_count'length)) and (lin_count <= to_unsigned(524, lin_count'length)) then
									--YELLOW = #ffce00
									next_VGA_R <= "1111";
									next_VGA_G <= "1100";
									next_VGA_B <= "0000";
								else
									next_VGA_R <= "0000";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								end if;
								
							when 10 =>
								--Flag 10-Austria
								if (lin_count > to_unsigned(44, lin_count'length)) and (lin_count <= to_unsigned(204, lin_count'length)) then
									--RED = #ed2939
									next_VGA_R <= "1110";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								elsif (lin_count > to_unsigned(204, lin_count'length)) and (lin_count <= to_unsigned(364, lin_count'length)) then
									--WHITE = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif (lin_count > to_unsigned(364, lin_count'length)) and (lin_count <= to_unsigned(524, lin_count'length)) then
									--RED = #ed2939
									next_VGA_R <= "1110";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= "0000";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								end if;
								
							when 11 =>
								-- Congo
								next_VGA_R <= "0000";
								next_VGA_G <= "1001";
								next_VGA_B <= "0100";
								
							when others =>
								next_VGA_R <= "0000";
								next_VGA_G <= "0010";
								next_VGA_B <= "1001";
						end case;
					else
						next_VGA_R <= "0000";
						next_VGA_G <= "0000";
						next_VGA_B <= "0000";				
					end if;
				end if;
				
			when D =>
				-- Sync high
				next_VGA_HS <= '1';
				if pix_count /= 0 then
					next_pix_count <= pix_count - 1;
					next_lin_count <= lin_count;
					next_flg_count <= flg_count;
					next_timer <= timer;
					next_state <= D;
					next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
					next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;
					if lin_count > LAST_C_V then
						--Flag Case
						case flg_count is
							when 0 =>
								--Flag 0 - France
								if (pix_count > START_RIGHT_STRIPE) and (pix_count <= END_LEFT_STRIPE) then
									--White = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= START_RIGHT_STRIPE then
									--RED = #ed2939
									next_VGA_R <= "1110";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								else
									-- Outside of data or in first stripe, keep the same
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 1 =>
								--Flag 1-Italy
								if (pix_count > 213) and (pix_count <= 427) then
									--White = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= 213 then
									--RED = #ce2b37
									next_VGA_R <= "1100";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 2 =>
								--Flag 2-Ireland
								if (pix_count > 213) and (pix_count <= 427) then
									--White = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= 213 then
									--ORANGE = #ff883e
									next_VGA_R <= "1111";
									next_VGA_G <= "1000";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;	
								
							when 3 =>
								--Flag 3-Belgium
								if (pix_count > 213) and (pix_count <= 427) then
									--Yellow = #fae042
									next_VGA_R <= "1111";
									next_VGA_G <= "1110";
									next_VGA_B <= "0100";
								elsif pix_count <= 213 then
									--RED = #ed2939
									next_VGA_R <= "1110";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 4 =>
								--Flag 4-Mali	
								if (pix_count > 213) and (pix_count <= 427) then
									--Yellow = #fcd116
									next_VGA_R <= "1111";
									next_VGA_G <= "1101";
									next_VGA_B <= "0001";
								elsif pix_count <= 213 then
									--RED = #ce1126
									next_VGA_R <= "1100";
									next_VGA_G <= "0001";
									next_VGA_B <= "0010";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 5 =>
								--Flag 5-Chad	
								if (pix_count > 213) and (pix_count <= 427) then
									--Yellow = #fecb00
									next_VGA_R <= "1111";
									next_VGA_G <= "1100";
									next_VGA_B <= "0000";
								elsif pix_count <= 213 then
									--RED = #c60c30
									next_VGA_R <= "1100";
									next_VGA_G <= "0000";
									next_VGA_B <= "0011";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 6 =>
								--Flag 6-Nigeria
								if (pix_count > 213) and (pix_count <= 427) then
									--WHITE = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= 213 then
									--GREEN = #008751
									next_VGA_R <= "0000";
									next_VGA_G <= "1000";
									next_VGA_B <= "0101";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
							when 7 =>
								--Flag 7-Ivory Coast
								if (pix_count > 213) and (pix_count <= 427) then
									--WHITE = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= 213 then
									--GREEN = #009e60
									next_VGA_R <= "0000";
									next_VGA_G <= "1001";
									next_VGA_B <= "0110";
								else
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
							
							when 8 =>
								--Flag 8-Poland
								next_VGA_R <= current_VGA_R;
								next_VGA_G <= current_VGA_G;
								next_VGA_B <= current_VGA_B;
								
							when 9 =>
								-- Germany
								next_VGA_R <= current_VGA_R;
								next_VGA_G <= current_VGA_G;
								next_VGA_B <= current_VGA_B;
								
							when 10 =>
								-- Austria
								next_VGA_R <= current_VGA_R;
								next_VGA_G <= current_VGA_G;
								next_VGA_B <= current_VGA_B;
								
							when 11 =>
								--Flag 11-Republic of Congo
								if (pix_count > LEFT_EDGE_YELLOW) and (pix_count <= D_COUNT_H) then
									--GREEN = #009543
									next_VGA_R <= "0000";
									next_VGA_G <= "1001";
									next_VGA_B <= "0100";
								elsif(pix_count <= LEFT_EDGE_YELLOW) and (pix_count > RIGHT_EDGE_YELLOW) then
									--YELLOW = #fbde4a
									next_VGA_R <= "1111";
									next_VGA_G <= "1101";
									next_VGA_B <= "0100";
								elsif(pix_count <= RIGHT_EDGE_YELLOW) and (pix_count > 0) then
									--RED = #dc241f
									next_VGA_R <= "1101";
									next_VGA_G <= "0010";
									next_VGA_B <= "0001";
								else
									next_VGA_R <= "0000";
									next_VGA_G <= "0000";
									next_VGA_B <= "0000";
								end if;
							
							when others =>
								--Flag 0 - France
								if (pix_count > START_RIGHT_STRIPE) and (pix_count <= END_LEFT_STRIPE) then
									--White = #FFFFFF
									next_VGA_R <= "1111";
									next_VGA_G <= "1111";
									next_VGA_B <= "1111";
								elsif pix_count <= START_RIGHT_STRIPE then
									--RED = #ed2939
									next_VGA_R <= "1110";
									next_VGA_G <= "0010";
									next_VGA_B <= "0011";
								else
									-- Outside of data or in first stripe, keep the same
									next_VGA_R <= current_VGA_R;
									next_VGA_G <= current_VGA_G;
									next_VGA_B <= current_VGA_B;
								end if;
								
						end case;
						
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
						next_LEFT_EDGE_YELLOW	<= 163;
						next_RIGHT_EDGE_YELLOW 	<= 0;	
					elsif (lin_count > LAST_C_V) then
						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
						next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW + 1;
						next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW + 1;
					else
						next_lin_count <= lin_count + to_unsigned(1, lin_count'length);
						next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
						next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
					end if;
					next_flg_count <= flg_count;
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
						next_flg_count <= flg_count;
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
						if flg_count = F_COUNT then
							next_flg_count <= 0;
						else
							next_flg_count <= flg_count + 1;
						end if;
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
					next_flg_count <= flg_count;
					next_timer <= timer + 1;
					next_state <= Debounce;
					next_VGA_R 	<= current_VGA_R;
					next_VGA_G 	<= current_VGA_G;
					next_VGA_B 	<= current_VGA_B;
					next_VGA_HS <= current_VGA_HS;
					next_VGA_VS <= current_VGA_VS;
				end if;
				next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
				next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
				
			when others =>
				next_pix_count <= pix_count;
				next_lin_count <= lin_count;
				next_flg_count <= flg_count;
				next_timer <= timer;
				next_state  <= Clear;
				next_VGA_R  <= current_VGA_R;
				next_VGA_G  <= current_VGA_G;
				next_VGA_B  <= current_VGA_B;
				next_VGA_HS <= current_VGA_HS;
				next_VGA_VS <= current_VGA_VS;
				next_LEFT_EDGE_YELLOW	<= LEFT_EDGE_YELLOW;
				next_RIGHT_EDGE_YELLOW 	<= RIGHT_EDGE_YELLOW;
			
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
