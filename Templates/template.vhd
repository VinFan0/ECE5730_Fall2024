library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all;

entity MODULE_NAME is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		ADC_CLK_10	: in std_logic; -- 10 MHz
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
		MAX10_CLK2_50 	: in std_logic; -- 50 MHz 2

		-- Button input --
		KEY : in std_logic_vector (1 downto 0);

		-- 7-Segment output --
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);
		HEX6 : out std_logic_vector(7 downto 0)
	);

end entity MODULE_NAME;

architecture behavioral of MODULE_NAME is

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;

begin

	-- Define module behavior here --
	process (  ) -- Sensitivity list goes in ()
	begin
		if KEY(0) = '0' then
			-- Reset behavior --
		else
			-- Normal behavior --

		end if;
	end process;

end architecture behavioral;
