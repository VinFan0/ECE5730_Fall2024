library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity rng is

	generic(
		seed : std_logic_vector(15 downto 0) := X"A58B"

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
		HEX5 : out std_logic_vector(7 downto 0)
	);

end entity rng;

architecture behavioral of rng is

	signal lfsr : STD_LOGIC_VECTOR(15 downto 0) := "1010010110001011";	-- LFSR defaults to A58B
   signal bit1  : STD_LOGIC;
	signal place1 : integer;
	signal place2 : integer;
	signal ready : integer := 0;
	
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
       			X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F

begin
	-- Define module behavior here --
	process (ADK_CLK_10, KEY) -- Sensitivity list goes in ()
	begin
		if KEY(0) = '0' then
			-- Reset behavior --
			ready <= 1;
			place1 <= X"B";
			place2 <= x"8";
			HEX0 <= table(place1); 	--Display seed value
			HEX1 <= table(place2); 	--Display seed value
			lfsr <= seed; --lfsr equals seed value
		elsif KEY(1) = '0' then
			-- Want to only show a new number when button pressed --
			if ready = 1 then
				HEX0 <= table(place1); -- update first digit display
				HEX1 <= table(place2); -- upadate second digit display
				ready <= 0;	
			end if;
		else
			ready <= 1;
		end if;
		-- Update LFSR constantly to assist in randomness --

		bit1 <= (lfsr(0) xor lfsr(2) xor lfsr(3) xor lfsr(5)) and '1';  -- Tabs: 16, 14, 13, 11
		lfsr <= lfsr(14 downto 0) & bit1; -- update lfsr with generated number
		place1 <= to_integer(unsigned(lfsr(3 downto 0))); --converting bits 3-0 of lfsr to integer
		place2 <= to_integer(unsigned(lfsr(7 downto 4))); --converting bits 4-7 of lfsr to integer

	end process;
	
	process (ADK_CLK_10)
	begin
		-- Clear unused 7-segments
		HEX2 <= X"FF"; --Display off
		HEX3 <= X"FF"; --Display off
		HEX4 <= X"FF"; --Display off
		HEX5 <= X"FF"; --Display off
	end process;

end architecture behavioral;
