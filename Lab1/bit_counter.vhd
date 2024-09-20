library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_counter is
	generic (
		N : integer := 10;
		T : integer := 5_000_000 -- Using the 10MHz clock and we want to trigger the counter every 0.5 seconds. 10MHz = 10M cycles per second => 5M cycles per half-second
	);
	port (
		ADC_CLK_10 : in std_logic;
		KEY : in std_logic_vector(1 downto 0);
		LEDR  : out unsigned((N-1) downto 0)
	);
end entity bit_counter;

architecture behavioral of bit_counter is

	signal sum : unsigned((N-1) downto 0);
	signal count : integer;

begin

	process (ADC_CLK_10, KEY)
	begin
		if KEY(0) = '0' then
			count <= 0;
			sum <= (others => '0');
		elsif rising_edge(ADC_CLK_10) then
			if count < T then
				count <= count + 1;
			else
				count <= 0;
				sum <= sum + 1;
			end if;
		end if;
	end process;

	LEDR <= sum;

end architecture behavioral;