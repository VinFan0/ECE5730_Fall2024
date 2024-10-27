library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all;

entity FIFO is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		ADC_CLK_10	: in std_logic; -- 10 MHz
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
		MAX10_CLK2_50 	: in std_logic; -- 50 MHz 2

		-- Button input --
		KEY : in std_logic_vector (1 downto 0);

		-- 7-Segment output --
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);
		HEX6 : out std_logic_vector(7 downto 0)

		-- Switches --
		SW : in std_logic_vector(9 downto 0);
		
		-- LEDs --
		LEDR : out std_logic_vector(9 downto 0)
	);

end entity FIFO;

architecture behavioral of FIFO is

	--Variables 
	signal add 	 	: unsigned(9 downto 0);
	signal sum 	 	: unsigned(23 downto 0);
	signal Timer 	: integer := 0;
	signal wr_en 	: integer := 0;
	signal rd_en 	: integer := 0;
	signal wr_data : unsigned(9 downto 0);

	--FSM States
	type state1 is (Clear, Waiting, Debounce, Pressed, Check, Writing);
	type state2 is (Clear, Waiting Accumulate, Display);
	
	signal current_state1, next_state1: state1;
	signal current_state2, next_state2: state2;

	--7-segment display
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F

begin

	-- Define module behavior here --
	process (  ) -- Sensitivity list goes in ()
	begin
		if KEY(0) = '0' then
			-- Reset behavior --
		else
			-- Normal behavior --

		end if;
	end process;

end architecture behavioral;