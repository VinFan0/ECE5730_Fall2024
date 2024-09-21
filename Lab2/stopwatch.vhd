library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch is
	
	generic(
		-- T is number of clock cycles for each tick of the counter
		T : integer := 100_000
	);
	
	port (
		-- CLK input
		ADC_CLK_10 : in std_logic;		-- 10 MHz
		-- MAX10_CLK1_50 : in std_logic;	-- 50 MHz 1
		-- MAX10_CLK2_50 : in std_logic;	-- 50 MHz 2
		
		-- Button input
		KEY : in std_logic_vector(1 downto 0);
		
		-- 7-Segment output
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);
		HEX6 : out std_logic_vector(7 downto 0)
		);
end entity stopwatch;

architecture behavioral of stopwatch is

	signal count : integer;

	type 7SEG is array (0 to 9) of std_logic_vector(7 downto 0);
	constant table : 7SEG := (X"C0", X"F9", X"A4", X"B0", X"99",  -- 0, 1, 2, 3, 4
       				  X"92", X"82", X"F8", X"80", X"90"); -- 5, 6, 7, 8, 9
	constant DEC : std_logic_vector (7 downto 0) := X"7F"				  

begin

	process (ADC_CLK_10, KEY)
	begin
		if KEY(0) = '0' then -- Reset behavior
			count <= 0;
			start <= 0;
		elsif KEY(1) = '0' then -- Start pressed
			if rising_edge(ADC_CLK_10) then
				if count < T then
					count <= count + 1; -- Increment count
				else 
					count <= 0; -- Reset after reaching T value
				end if;
			end if;
		end if;
	end process;
end architecture behavioral;
