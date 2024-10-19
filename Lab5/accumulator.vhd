library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator is

	-- generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --

	-- );

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		ADC_CLK_10	: in std_logic; -- 10 MHz
		--MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
		--MAX10_CLK2_50 	: in std_logic; -- 50 MHz 2

		-- Button input --
		KEY : in std_logic_vector (1 downto 0);

		-- 7-Segment output --
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);

		--Switches--
		SW : in std_logic_vector(9 downto 0);
		
		--LEDS--
		LEDR : out std_logic_vector(9 downto 0)
		
	);

end entity accumulator;

architecture behavioral of accumulator is

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	signal add : unsigned(9 downto 0);
	signal sum : unsigned(23 downto 0);
	
	type state_type is (CLEAR, WAITING, DEBOUNCE, ACCUMULATE, DISPLAY);
	signal current_state, next_state: state_type;
	
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F

begin

	-- State Controller --
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			if KEY(0) = '0' then
				current_state <= CLEAR;
			else
				current_state <= next_state;
			end if;
		end if;
	end process;
	
	-- Behavior Controller --
	process (current_state, KEY)
	begin
		case current_state is
		
			when CLEAR =>
				-- Reset sum and add
				add <= (others => '0');
				sum <= (others => '0');
				
				-- If no RESET pressed
				if KEY(0) = '1' then
					-- Move to WAITING
					next_state <= WAITING;
				end if;
				
			when WAITING =>
				-- Clear add
				add <= (others => '0');
				
				-- If RESET
				if KEY(0) = '0' then
					-- Move to CLEAR
					next_state <= CLEAR;
				-- Else if ADD
				elsif KEY(1) = '0' then
					-- Move to DEBOUNCE
					next_state <= DEBOUNCE;
				end if;

			when DEBOUNCE =>
				-- If ADD released
				if KEY(1) = '1' then
					-- Move to ACCUMULATE
					next_state <= ACCUMULATE;
					-- Capture Switch input for addition
					add <= unsigned(SW);
				end if;
				
			when ACCUMULATE =>
				-- Increase sum
				sum <= sum + add;
				-- Move to DISPLAY
				next_state <= DISPLAY;
				
			when DISPLAY => 
				-- Move to WAITING
				next_state <= WAITING;
			
			when others =>  
				-- DEFAULT: Move to WAITING
				next_state <= WAITING;
				
		end case;
				
	end process;
	
	-- LEDR and 7-segment Controller --
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			-- Update LEDR with SW input
			LEDR <= SW;
			-- Update 7-Segment --
			HEX0 <= table(to_integer(sum(3 downto 0)));
			HEX1 <= table(to_integer(sum(7 downto 4)));
			HEX2 <= table(to_integer(sum(11 downto 8)));
			HEX3 <= table(to_integer(sum(15 downto 12)));
			HEX4 <= table(to_integer(sum(19 downto 16)));
			HEX5 <= table(to_integer(sum(23 downto 20)));	
			
		end if;
	end process;

end architecture behavioral;
