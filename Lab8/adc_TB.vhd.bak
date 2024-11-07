library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_NAME is
end entity TB_NAME;

architecture behavioral of TB_NAME is

	-- Instantiate component(s) to test --
	component MODULE is
		generic (
			-- Provide generic values --

		);
		port (
			-- Declare ports --

			-- Inputs --
			-- Clocks --
			ADC_CLK_10 	: in std_logic;
			MAX10_CLK1_50 	: in std_logic;
			MAX10_CLK2_50 	: in std_logic;

			-- Buttons --
			KEY : in std_logic_vector(1 downto 0);

		
			-- 7-Segment output --
			HEX0: out std_logic_vector(7 downto 0);
			HEX1: out std_logic_vector(7 downto 0);
			HEX2: out std_logic_vector(7 downto 0);
			HEX3: out std_logic_vector(7 downto 0);
			HEX4: out std_logic_vector(7 downto 0);
			HEX5: out std_logic_vector(7 downto 0);

			-- Switch input --
			SW : in std_logic_vector(9 downto 0);
			
			-- LED output --
			LEDR : out std_logic_vector(9 downto 0);
		);
	end component;

	-- Define internal signals/values

	-- Include CLK signal and all I/)
	signal ADC_CLK_10 : std_logic;
	constant CLK_PERIOD : time := 10 ns;

	-- Button input --
	signal KEY : std_logic_vector(1 downto 0);

	-- 7-Segment output --
	signal HEX0 : std_logic_vector(7 downto 0);
	signal HEX1 : std_logic_vector(7 downto 0);
	signal HEX2 : std_logic_vector(7 downto 0);
	signal HEX3 : std_logic_vector(7 downto 0);
	signal HEX4 : std_logic_vector(7 downto 0);
	signal HEX5 : std_logic_vector(7 downto 0);

	-- Switch input --
	signal SW : std_logic_vector(9 downto 0);

	-- LED output --
	signal LEDR : std_logic_vector(9 downto 0);

begin

	-- Define unit under test --
	uut : MODULE
		generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --

		)
		port map (
			-- Map port connections --
			-- NAME => NAME (separated by , ) --
		);

		-- Define processes --
		-- Clock --
		clk_process : process
		begin
			CLOCK_NAME <= '0';
			wait for CLK_PERIOD / 2;
			CLOCK_NAME <= '1';
			wait for CLK_PERIOD / 2;
		end process;

		-- Stimulation behavior --
		stm_process : process
		begin
			
			-- Initial values --
			KEY(0) <= '1';

			-- Initial RESET --
			wait for CLK_PERIOD * 10; 
			KEY(0) <= '0';            
			wait for CLK_PERIOD * 10;
			KEY(0) <= '1';

		end process; 

end architecture behavioral;
