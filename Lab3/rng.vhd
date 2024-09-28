library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rng is

	generic(
		seed : integer := 16#A58B#

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		ADK_CLK_10	: in std_logic; -- 10 MHz
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
		HEX6 : out std_logic_vector(7 downto 0)
	);

end entity rng;

architecture behavioral of rng is

	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (X"C0", X"F9", X"A4", X"B0", X"99",  -- 0, 1, 2, 3, 4
       				  X"92", X"82", X"F8", X"80", X"90",	-- 5, 6, 7, 8, 9
						  X"88", X"83", X"C6", X"A1", X"86", X"8E"); --A, B, C, D, E, F

begin

	-- Define module behavior here --
	process (ADK_CLK_10, KEY) -- Sensitivity list goes in ()
	begin
		if KEY(0) = '0' then
			-- Reset behavior --
			HEX0 <= table(16#B#);
			HEX1 <= table(8);
		elsif KEY(1) = '0' then
			
			-- Normal behavior --

		end if;
	end process;
	
	process (ADK_CLK_10)
	begin
		HEX2 <= X"FF"; --Display off
		HEX3 <= X"FF"; --Display off
		HEX4 <= X"FF"; --Display off
		HEX5 <= X"FF"; --Display off
	end process;

end architecture behavioral;
