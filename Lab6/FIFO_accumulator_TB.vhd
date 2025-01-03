library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO_accumulator_TB is
end entity FIFO_accumulator_TB;

architecture behavioral of FIFO_accumulator_TB is

	-- Instantiate component(s) to test --
	component fifo_accumulator is
		generic (
			-- Provide generic values --
			-- NAME : TYPE := INITIAL_VALUE (separated by ,) --
			DELAY : integer := 1		-- Number of clock cycles for debounce

		);
		port (
			-- Declare ports --
			-- NAME : DIRECTION TYPE --

			-- Inputs --
			-- Clocks --
			-- ADC_CLK_10 	: in std_logic;
			MAX10_CLK1_50 	: in std_logic;
			-- MAX10_CLK2_50 	: in std_logic;

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
			LEDR : out std_logic_vector(9 downto 0)
		);
	end component;

	-- Define internal signals/values
	-- signal NAME : TYPE := INITIAL_VALUE (separated by ; ) --

	-- Include CLK signal and all I/O)
	signal MAX10_CLK1_50 : std_logic;
	constant CLK_PERIOD : time := 10 ns;

	-- Generics --
	signal DELAY : integer := 4;

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
	uut : fifo_accumulator
		generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --
			DELAY => DELAY

		)
		port map (
			-- Map port connections --
			-- NAME => NAME (separated by , ) --
			MAX10_CLK1_50 => MAX10_CLK1_50,
			KEY 	=> KEY,
			HEX0 	=> HEX0,
			HEX1 	=> HEX1,
			HEX2 	=> HEX2,
			HEX3 	=> HEX3,
			HEX4 	=> HEX4,
			HEX5 	=> HEX5,
			SW 	=> SW,
			LEDR 	=> LEDR
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

			-- Initial RESET --
			wait for CLK_PERIOD * 6; 
			KEY(0) <= '0';            
			wait for CLK_PERIOD * 6;
			KEY(0) <= '1';

			-- Provide SW input --
			SW <= "0000000001";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;
		
			SW <= "0000000010";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000011";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000100";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000101";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 20;
			
			-- Provide SW input --
			SW <= "0000000001";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;
		
			SW <= "0000000010";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000011";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000100";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000101";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 20;

			KEY(0) <= '0';
			wait for CLK_PERIOD * 6;
			KEY(0) <= '1';
			wait for CLK_PERIOD * 6;
		
			-- Provide SW input --
			SW <= "0000000001";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;
		
			SW <= "0000000010";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000011";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000100";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			SW <= "0000000101";
			wait for CLK_PERIOD * 8;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 8;
			KEY(1) <= '1';
			wait for CLK_PERIOD * 2;

			wait;

		end process; 

end architecture behavioral;
