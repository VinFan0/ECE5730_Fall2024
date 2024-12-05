library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC_Test is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --
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
		SAMPLE_PERIOD : integer := 10000000;
		Counter : integer := 50000000

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1

		-- 7-Segment output --
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);
		HEX6 : out std_logic_vector(7 downto 0);
		
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

end entity ADC_Test;

architecture behavioral of ADC_Test is

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
	signal change : integer := 0;
	signal help : std_logic := '1';
	signal score_1 : integer := 0;
	signal score_2 : integer := 0;
	signal count : integer := 0;
	
	
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

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	
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
	signal response_endofpacket   : std_logic;                                  		-- endofpacket	
	
	-- PLL Signals --
	signal c0_sig					      :  std_logic                     := 'X';        -- clk
	signal locked_sig					   :  std_logic                     := 'X';        -- export
	
	
	--7-segment display
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F
	
	-- MISC --
	signal sample_counter : integer := 0;
	signal sample_trigger : std_logic;
	signal display_0 : unsigned(12 downto 0) := (others => '0');
	signal display_1 : unsigned(12 downto 0) := (others => '0');
	signal next_display : unsigned(12 downto 0) := (others => '0');
	signal temp_display : integer;
	
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
	-- Instantiate IP Blocks --

	-- ADC --
	u0 : component my_ADC
		port map (
			-- Input
			clock_clk              => MAX10_CLK1_50,             					--          clock.clk
			reset_sink_reset_n     => help,  				   					--     reset_sink.reset_n
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
		
	-- PLL --
	my_PLL_inst : my_PLL PORT MAP (
		areset	 => NOT help,
		inclk0	 => MAX10_CLK1_50,
		c0	 		 => c0_sig,
		locked	 => locked_sig
	);

	
	-- Make future the present --
	process ( MAX10_CLK1_50 ) -- Sensitivity list goes in ()
	begin
		if rising_edge( MAX10_CLK1_50 ) then
			-- Only trigger every other clock cycle (25 MHz)
			if clk_count = 1 then
				clk_count <= 0;
				
				-- If Reset
				if change = 0 then
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
					change <= change + 1;	
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
	process ( current_state, pix_count, change, lin_count, timer )
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
				
				if change = 0 then
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
					next_state <= A;
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
					next_state <= B;
	
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
					next_state <= D;
					
					-- If in Vert B
					if (lin_count > LAST_A_V) and (lin_count <= LAST_B_V) then
						-- Reset Vert Sync
						next_VGA_VS <= '0';
					else
						next_VGA_VS <= '1';
					end if;					
					if lin_count > LAST_C_V then
						if (lin_count > 400)  and (lin_count <= 430) then
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
						end if;
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
					if change = 2 then
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
					temp_display <= to_integer(response_data) * 1 / 4;
					display_0 <= to_unsigned(temp_display, display_0'length);
					command_channel <= "00010";
				elsif command_channel = "00010" then
					temp_display <= to_integer(response_data) * 1 / 4;
					display_1 <= to_unsigned(temp_display, display_1'length);
					command_channel <= "00001";
				end if;
			end if;
		end if;
	end process;
	
	--process to drive 7 segment
	process (MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then
			if (sample_trigger = '1') then
				HEX0 <= table(to_integer(display_0(3 downto 0)));
				HEX1 <= table(to_integer(display_0(7 downto 4)));
				HEX2 <= table(to_integer(display_0(11 downto 8)));
				HEX3 <= X"FF";
				HEX4 <= X"FF";
				HEX5 <= X"FF";
			elsif help = '0' then
				HEX0 <= table(0);
				HEX1 <= table(0);
				HEX2 <= table(0);
				HEX3 <= X"FF";
				HEX4 <= X"FF";
				HEX5 <= X"FF";
			end if;
		end if;
	end process;


end architecture behavioral;
