library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rng_TB is
end entity rng_TB; 

architecture behavioral of rng_TB is

	-- Instantiate component(s) to test --
	component rng is
		generic (
			-- Provide generic values --
			seed : std_logic_vector(15 downto 0) := X"A58B"
		);
		port (
			-- Declare ports --

			-- Inputs --
			-- Clocks --
			ADC_CLK_10 : in std_logic;
			-- MAX10_CLK1_50 	: in std_logic;
			-- MAX10_CLK2_50 	: in std_logic;

			-- Buttons --
			KEY : in std_logic_vector(1 downto 0);

			-- Outputs --
			-- LEDs --
			-- LEDR : out std_logic_vector(9 downto 0);
			
			-- 7 Segment --
			HEX0 : out std_logic_vector(7 downto 0);
			HEX1 : out std_logic_vector(7 downto 0);
			HEX2 : out std_logic_vector(7 downto 0);
			HEX3 : out std_logic_vector(7 downto 0);
			HEX4 : out std_logic_vector(7 downto 0);
			HEX5 : out std_logic_vector(7 downto 0)
		);
	end component;

	-- Define internal signals/values

	signal ADC_CLK_10 : std_logic := '0';
	signal KEY : std_logic_vector(1 downto 0);
	signal HEX0 : std_logic_vector(7 downto 0);
	signal HEX1 : std_logic_vector(7 downto 0);
	signal HEX2 : std_logic_vector(7 downto 0);
	signal HEX3 : std_logic_vector(7 downto 0);
	signal HEX4 : std_logic_vector(7 downto 0);
	signal HEX5 : std_logic_vector(7 downto 0);


	constant CLK_PERIOD : time := 10 ns;
begin

	-- Define unit under test --
	uut : rng
		generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --
			seed => X"A58B"
		)
		port map (
			-- Map port connections --
			-- NAME => NAME (separated by , ) --
			ADC_CLK_10 => ADC_CLK_10,
			KEY => KEY,
			HEX0 => HEX0,
			HEX1 => HEX1,
			HEX2 => HEX2,
			HEX3 => HEX3,
			HEX4 => HEX4,
			HEX5 => HEX5
		);

		-- Define processes --
		-- Clock --
		clk_process : process
		begin
			ADC_CLK_10 <= '0';
			wait for CLK_PERIOD / 2;
			ADC_CLK_10 <= '1';
			wait for CLK_PERIOD / 2;
		end process;

		-- Stimulation behavior --
		stm_process : process
		begin
			
			-- Initial values --
			KEY(0) <= '1';
			

			wait for CLK_PERIOD * 10; 
			KEY(0) <= '0';            -- Initial RESET --
			wait for CLK_PERIOD * 10;
			KEY(0) <= '1';

		end process; 

end architecture behavioral;
