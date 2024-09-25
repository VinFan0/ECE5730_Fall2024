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

			-- Outputs --
			-- LEDs --
			LEDR : out std_logic_vector(9 downto 0);
		);
	end component;

	-- Define internal signals/values

	constant CLK_PERIOD : time := 10 ns;
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
