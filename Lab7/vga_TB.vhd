library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_TB is
end entity vga_TB;

architecture behavioral of vga_TB is

	-- Instantiate component(s) to test --
	component vga is
		generic (
			-- Provide generic values --
			-- NAME : TYPE := INITIAL_VALUE (separated by ,) --
			A_COUNT_H 	: integer;
			B_COUNT_H 	: integer;
			C_COUNT_H 	: integer;
			D_COUNT_H 	: integer;
			LAST_A_V	: integer;
			LAST_B_V	: integer;
			LAST_C_V	: integer;
			LAST_D_V	: integer;
			L_COUNT 	: integer;
			F_COUNT		: integer;
			DELAY		: integer;
			-- Stripe size generics for simulating
			START_LEFT_STRIPE 	: integer;
			END_LEFT_STRIPE 	: integer;
			START_RIGHT_STRIPE	: integer

		);
		port (
			-- Declare ports --

			-- Inputs --
			-- Clocks --
			MAX10_CLK1_50 	: in std_logic;

			-- Buttons --
			KEY : in std_logic_vector(1 downto 0);
			
			-- VGA --
			VGA_R 	: out std_logic_vector(3 downto 0);
			VGA_G 	: out std_logic_vector(3 downto 0);
			VGA_B 	: out std_logic_vector(3 downto 0);
			VGA_HS	: out std_logic;
			VGA_VS	: out std_logic
		
		);
	end component;

	-- Define internal signals/values

	-- Include CLK signal and all I/)
	signal MAX10_CLK1_50 : std_logic;
	constant CLK_PERIOD : time := 10 ns;

	-- Button input --
	signal KEY : std_logic_vector(1 downto 0);
	
	-- VGA output --
	signal VGA_R 	: std_logic_vector(3 downto 0);
	signal VGA_G 	: std_logic_vector(3 downto 0);
	signal VGA_B 	: std_logic_vector(3 downto 0);
	signal VGA_HS	: std_logic;
	signal VGA_VS	: std_logic;
	
	-- Generics
	signal A_COUNT_H	: integer := 2;
	signal B_COUNT_H	: integer := 4;
	signal C_COUNT_H	: integer := 2;
	signal D_COUNT_H  	: integer := 10;
	signal LAST_A_V		: integer := 2;
	signal LAST_B_V		: integer := 4;
	signal LAST_C_V		: integer := 7;
	signal LAST_D_V		: integer := 9;
	signal L_COUNT		: integer := 10;
	signal F_COUNT		: integer := 11;
	signal DELAY		: integer := 2;
	-- Stripe size generics for simulating
	signal START_LEFT_STRIPE 	: integer := 9;
	signal END_LEFT_STRIPE 		: integer := 7;
	signal START_RIGHT_STRIPE	: integer := 3;
	
begin

	-- Define unit under test --
	uut : vga
		generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --
			DELAY				=> DELAY,
			F_COUNT				=> F_COUNT,
			L_COUNT				=> L_COUNT,
			D_COUNT_H 			=> D_COUNT_H,
			C_COUNT_H			=> C_COUNT_H,
			B_COUNT_H			=> B_COUNT_H,
			A_COUNT_H			=> A_COUNT_H,
			LAST_A_V			=> LAST_A_V,
			LAST_B_V			=> LAST_B_V,
			LAST_C_V			=> LAST_C_V,
			LAST_D_V			=> LAST_D_V,
			START_LEFT_STRIPE	=> START_LEFT_STRIPE, 
			END_LEFT_STRIPE     => END_LEFT_STRIPE, 
			START_RIGHT_STRIPE  => START_RIGHT_STRIPE
		)
		port map (
			-- Map port connections --
			-- NAME => NAME (separated by , ) --
			MAX10_CLK1_50	=> MAX10_CLK1_50,
			KEY				=> KEY,
			VGA_R 			=> VGA_R,
			VGA_G 			=> VGA_G,
			VGA_B 			=> VGA_G,
			VGA_HS			=> VGA_HS,
			VGA_VS			=> VGA_VS
			
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
			wait for CLK_PERIOD * 10; 
			KEY(0) <= '0';            
			wait for CLK_PERIOD * 10;
			KEY(0) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 10;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			-- Test next Button
			wait for CLK_PERIOD * 5;
			KEY(1) <= '0';
			wait for CLK_PERIOD * 5;
			KEY(1) <= '1';
			
			
			wait;

		end process; 

end architecture behavioral;
