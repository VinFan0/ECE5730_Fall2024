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
			A_COUNT : integer;
			B_COUNT : integer;
			C_COUNT : integer;
			D_COUNT : integer;
			L_COUNT : integer;
			F_COUNT	: integer;
			DELAY	: integer

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
	signal A_COUNT	: integer := 3;
	signal B_COUNT	: integer := 2;
	signal C_COUNT	: integer := 15;
	signal D_COUNT  : integer := 15;
	signal L_COUNT	: integer := 8;
	signal F_COUNT	: integer := 10;
	signal DELAY	: integer := 2;
	
begin

	-- Define unit under test --
	uut : vga
		generic map (
			-- Map generic values (separated by , )--
			-- NAME => value --
			DELAY	=> DELAY,
			F_COUNT	=> F_COUNT,
			L_COUNT	=> L_COUNT,
			D_COUNT => D_COUNT,
			C_COUNT	=> C_COUNT,
			B_COUNT	=> B_COUNT,
			A_COUNT	=> A_COUNT
			
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
			
			wait;

		end process; 

end architecture behavioral;
