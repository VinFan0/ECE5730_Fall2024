library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all;

entity Accumulator is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		--ADC_CLK_10	: in std_logic; -- 10 MHz
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
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
		HEX6 : out std_logic_vector(7 downto 0);
		
		--Switches--
		SW : in std_logic_vector(9 downto 0);
		
		--LEDS--
		LEDR : out std_logic_vector(9 downto 0)
		
	);

end entity Accumulator;

architecture behavioral of Accumulator is

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	signal count : integer := 0;
	signal add : integer := 0;

	type state_type is (CLEAR, WAITING, DEBOUNCE, ACCUMULATE);
	signal current_state, next_state: state_type;
	
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
       			X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F

begin

	-- Define module behavior here --
	process (MAX10_CLK1_50) -- Sensitivity list goes in ()
	begin
		if rising_edge(MAX10_CLK1_50) then
			if rst= '1' then
				current_state <= CLEAR;
			else
				current_state <= next_state;
			end if;
		end if;
	end process;
	
	process (current_state, KEY, SW)
	begin
		case current_state is
		
			when CLEAR =>
				HEX0 <= table(0); --Display 0
				HEX1 <= table(0); --Display 0
				HEX2 <= table(0); --Display 0
				HEX3 <= table(0); --Display 0
				HEX4 <= table(0); --Display 0
				HEX5 <= table(0); --Display 0
				
				count <= 0;
				next_state <= WAITING;
				
			when WAITING =>
				if KEY(0) = '0' then
					next_state <= CLEAR;
				elsif KEY(1) = '0' then
					next_state <= DEBOUNCE;
				end if;
				LEDR <= SW;
				
			when DEBOUNCE =>
				if KEY(1) = '1' then
					next_state <= ACCUMULATE;
				end if;
			
			when ACCUMULATE =>
				add <= SW;
				count <= count + add;
				
	end process;

end architecture behavioral;
