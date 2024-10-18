library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accumulator_TB is
end entity accumulator_TB;

architecture behavioral of accumulator_TB is

	-- Instantiate component(s) to test --
	component accumulator is
		--generic (
			-- Provide generic values --

		--);
		port (
			-- Declare ports --

			-- Clocks --
			-- ADC_CLK_10 	: in std_logic;
			MAX10_CLK1_50 	: in std_logic;
			-- MAX10_CLK2_50 	: in std_logic;

			-- Button inputs --
			KEY : in std_logic_vector(1 downto 0);

			-- 7-Segment output --
			HEX0: out std_logic_vector(7 downto 0);
			HEX1: out std_logic_vector(7 downto 0);
			HEX2: out std_logic_vector(7 downto 0);
			HEX3: out std_logic_vector(7 downto 0);
			HEX4: out std_logic_vector(7 downto 0);
			HEX5: out std_logic_vector(7 downto 0);

			-- Switch inputs --
			SW : in std_logic_vector(9 downto 0);

			-- LED outputs --
			LEDR : out std_logic_vector(9 downto 0)
		);

	end component;

	-- Define internal signals/values
	-- signal NAME : TYPE (:= INIT_VALUE) ending in ;

	-- Include CLK signal and all I/O
	-- signal ADC_CLK_10 	: in std_logic;
	signal MAX10_CLK1_50 	: std_logic;
	-- signal MAX10_CLK2_50 	: in std_logic;

	-- Button inputs --
	signal KEY : std_logic_vector(1 downto 0);

	-- 7-Segment output --
	signal HEX0: std_logic_vector(7 downto 0);
	signal HEX1: std_logic_vector(7 downto 0);
	signal HEX2: std_logic_vector(7 downto 0);
	signal HEX3: std_logic_vector(7 downto 0);
	signal HEX4: std_logic_vector(7 downto 0);
	signal HEX5: std_logic_vector(7 downto 0);

	-- Switch inputs --
	signal SW : std_logic_vector(9 downto 0);

	-- LED outputs --
	signal LEDR : std_logic_vector(9 downto 0);

	constant CLK_PERIOD : time := 10 ns;
begin

	-- Define unit under test --
	uut : accumulator
		-- generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --
		-- )
		port map (
			-- Map port connections --
			-- NAME => NAME (separated by , ) --
			MAX10_CLK1_50 => MAX10_CLK1_50,
			KEY => KEY,
			HEX0 => HEX0,
			HEX1 => HEX0,
			HEX2 => HEX0,
			HEX3 => HEX0,
			HEX4 => HEX0,
			HEX5 => HEX5,
			SW => SW,
			LEDR => LEDR
		);

		-- Define processes --
		-- Clock --
		clk_process : process
		begin
			MAX10_CLK1_50 <= '0';
			wait for CLK_PERIOD / 2;
			MAX10_CLK1_50 <= '1';
			wait for CLK_PERIOD / 2;
		end process;

		-- Stimulation behavior --
		stm_process : process
		begin
			
			-- Initial values --
			KEY(0) <= '1';
			KEY(1) <= '1';

			wait for CLK_PERIOD * 10; 
			KEY(0) <= '0';            -- Initial RESET --
			wait for CLK_PERIOD * 10;
			KEY(0) <= '1';
			wait for CLK_PERIOD * 5; 
			KEY(0) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(0) <= '1';
			SW <= (others => '0');
			SW(0) <= '1';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_Period * 5;
			KEY(1) <= '1';
			
			
			wait;

		end process; 

end architecture behavioral;
