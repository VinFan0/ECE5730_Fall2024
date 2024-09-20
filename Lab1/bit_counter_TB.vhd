library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_counter_TB is
end bit_counter_TB;

architecture behavioral of bit_counter_TB is

	component bit_counter is
		generic (
			N : integer := 4;
			T : integer := 5000000
		);
		port (
			ADC_CLK_10 : in std_logic;
			KEY : in std_logic_vector(1 downto 0);
			LEDR  : out unsigned((N-1) downto 0)
		);
	end component;
	
	signal ADC_CLK_10 : std_logic := '0';
	signal KEY : std_logic_vector (1 downto 0);
	signal LEDR : unsigned (2 downto 0);
	
	constant CLK_PERIOD : time := 10 ns;

begin

	uut : bit_counter
		generic map(
			N => 3,
			T => 5
		)
		port map(
			ADC_CLK_10 => ADC_CLK_10,
			KEY => KEY,
			LEDR => LEDR
		);
		
		clk_process : process
		begin
			ADC_CLK_10 <= '0';
			wait for CLK_PERIOD / 2;
			ADC_CLK_10 <= '1';
			wait for CLK_PERIOD /2;
		end process;
		
		stm_process : process
		begin
			KEY(0) <= '1';
			KEY(1) <= '0'; -- Clearing BTN 1 input
			wait for CLK_PERIOD * 10;
			KEY(0) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(0) <= '1';
			wait for CLK_PERIOD * 20;
			KEY(0) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(0) <= '1';
			wait;
		end process;

end architecture behavioral;