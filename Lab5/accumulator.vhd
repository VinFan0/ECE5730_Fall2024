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

		--Switches--
		SW : in std_logic_vector(9 downto 0);
		
		--LEDS--
		LEDR : out std_logic_vector(9 downto 0)
		
	);

end entity accumulator;

architecture behavioral of accumulator is

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	signal add : integer;
	signal sum : integer;
	
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
			if KEY(0) = '0' then
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
				
				add <= 0;
				if KEY(0) = '1' then
					next_state <= WAITING;
				end if;
			when WAITING =>
				if KEY(0) = '0' then
					next_state <= CLEAR;
				elsif KEY(1) = '0' then
					next_state <= DEBOUNCE;
				end if;
				-- Update LEDR with SW input
				LEDR <= SW;

			when DEBOUNCE =>
				if KEY(1) = '1' then
					next_state <= ACCUMULATE;
				end if;
			
			when ACCUMULATE =>
				-- Update LEDR with SW input
				LEDR <= SW;
		end case;
				
	end process;

end architecture behavioral;
