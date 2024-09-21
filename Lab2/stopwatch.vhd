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

	signal count : integer := 0;		-- tracks clock cycles for incrementing timer
	signal tick : integer := 0;
	
	type SEVEN_SEG is array (0 to 9) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (X"C0", X"F9", X"A4", X"B0", X"99",  -- 0, 1, 2, 3, 4
       				  X"92", X"82", X"F8", X"80", X"90"); -- 5, 6, 7, 8, 9
	constant DEC : std_logic_vector (7 downto 0) := X"7F"; 	-- constant for decimal point, if a segment needs decimal, we can
								-- OR the value with DEC

	-- Variables for stopwatch display numbers
	signal M_Tens     : integer := 0;
	signal M_Ones     : integer := 0;
	signal S_Tens     : integer := 0;
	signal S_Ones     : integer := 0;
	signal Tenths     : integer := 0;
	signal Hundredths : integer := 0;

begin

	-- Track reset and control timing of the stopwatch
	process (ADC_CLK_10, KEY)
	begin
		if KEY(0) = '0' then -- Reset behavior
			count <= 0;
			tick <= 0;
		elsif KEY(1) = '0' then -- Start pressed
			if rising_edge(ADC_CLK_10) then
				if count < T then
					count <= count + 1; -- Increment count
					tick <= 0;
				else 
					count <= 0; -- Reset after reaching T value
					tick <= 1; -- signal timer to increment
				end if;
			end if;
		end if;
	end process;

	-- Control the counting of the stopwatch
	process (tick)
	begin
		if tick = 1 then						-- If tick
			if Hundredths = 9 then				-- If top of hundredths
				Hundredths <= 0;					-- Reset Hundreths
				
				if Tenths = 9 then					-- If top of Tenths
					Tenths <= 0;						-- Reset Tenths
			
					if S_Ones = 9 then					-- If top of S_Ones
						S_Ones <= 0;						-- Reset S_Ones
				
						if S_Tens = 5 then					-- If top of S_Tens
							S_Tens <= 0;						-- Reset S_Tens
					
							if M_Ones = 9 then					-- If top of M_Ones
								M_Ones <= 0;						-- Reset M_Ones
				
								if M_Tens = 5 then					-- If top of M_Tens
									M_Tens <= 0;						-- Reset M_Tens
								else
									M_Tens <= M_Tens + 1;			-- else increment M_Tens
								end if; -- M_Tens
							else
								M_Ones <= M_Ones + 1;			-- else increment M_Ones
							end if; -- M_Ones
						else
							S_Tens <= S_Tens + 1;			-- else increment S_Tens
						end if; -- S_Tens
					else
						S_Ones <= S_Ones + 1;			-- else increment S_Ones
					end if; -- S_Ones
				else
					Tenths <= Tenths + 1;			-- else increment Tenths
				end if; -- Tenths
			else
				Hundredths <= Hundredths + 1;	-- else increment Hundreths
			end if; -- Hundreths
			
		end if;
	end process;

end architecture behavioral;
