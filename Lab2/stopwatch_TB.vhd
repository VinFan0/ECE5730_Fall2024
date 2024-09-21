library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch_TB is
end entity stopwatch_TB;

architecture behavioral of stopwatch_TB is

	component stopwatch is
		generic (
			-- T: how many clock cycles until count increments
			T : integer := 5
		);
		port (
			-- Inputs
			ADC_CLK_10 : in std_logic;
			KEY : in std_logic_vector(1 downto 0);

			-- Outputs
			HEX0: out std_logic_vector(7 downto 0);
			HEX1: out std_logic_vector(7 downto 0);
			HEX2: out std_logic_vector(7 downto 0);
			HEX3: out std_logic_vector(7 downto 0);
			HEX4: out std_logic_vector(7 downto 0);
			HEX5: out std_logic_vector(7 downto 0);
			HEX6: out std_logic_vector(7 downto 0)
		);
	end component;

	signal ADC_CLK_10 : std_logic := '0';
	signal KEY : std_logic_vector(1 downto 0);
	signal HEX0 : std_logic_vector(7 downto 0);
	signal HEX1 : std_logic_vector(7 downto 0);
	signal HEX2 : std_logic_vector(7 downto 0);
	signal HEX3 : std_logic_vector(7 downto 0);
	signal HEX4 : std_logic_vector(7 downto 0);
	signal HEX5 : std_logic_vector(7 downto 0);
	signal HEX6 : std_logic_vector(7 downto 0);

	constant CLK_PERIOD : time := 10 ns;
	
begin
	uut : stopwatch
		generic map (
			T => 5
		)
		port map (
			ADC_CLK_10 => ADC_CLK_10,
			KEY => KEY,
			HEX0 => HEX0,
			HEX1 => HEX0,
			HEX2 => HEX0,
			HEX3 => HEX0,
			HEX4 => HEX0,
			HEX5 => HEX0,
			HEX6 => HEX0

		);

		clk_process : process
		begin
			ADC_CLK_10 <= '0';
			wait for CLK_PERIOD / 2;
			ADC_CLK_10 <= '1';
			wait for CLK_PERIOD / 2;
		end process;

		stm_process : process
		begin
			KEY(0) <= '1'; 			-- Initial RST button
			KEY(1) <= '1';			-- Initail START button
			wait for CLK_PERIOD * 5;
			KEY(0) <= '0';			-- Toggle RST
			wait for CLK_PERIOD * 5;
			KEY(0) <= '1';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';			-- Toggle START
			wait;
		end process;
end architecture behavioral;		
