library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_accumulator is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by ; ) --
		W : integer := 10;		-- Width of SW input
		DELAY : integer := 5 	-- Number of clock cycles for debounce

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		-- ADC_CLK_10	: in std_logic; -- 10 MHz
		MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
		-- MAX10_CLK2_50 	: in std_logic; -- 50 MHz 2

		-- Button input --
		KEY : in std_logic_vector (1 downto 0);

		-- 7-Segment output --
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0);
		HEX6 : out std_logic_vector(7 downto 0);

		-- Switches --
		SW : in std_logic_vector((W-1) downto 0);
		
		-- LEDs --
		LEDR : out std_logic_vector((W-1) downto 0)
	);

end entity fifo_accumulator;

architecture behavioral of fifo_accumulator is

	-- Variables 
	signal add 	 	: unsigned((W-1) downto 0);	-- Next value to write to FIFO (potentially unnecessary)
	signal sum 	 	: unsigned(23 downto 0);		-- Accumulated total
	signal timer 	: integer := 0;					-- Timer for debounce
	
	--7-segment display
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F
	
	-- FSM States
	type state_type is (
		Clear, 
		Waiting, 
		Debounce, 
		Pressed, 
		Check, 
		Writing,
		Empty,
		Accumulate,
		Display
		);
	
	signal FSM1_current_state, FSM1_next_state, FSM2_current_state, FSM2_next_state: state_type;
	
	
	-- FSM1 Signals --
	signal wr_en 		: integer := 0;					-- Enable write to FIFO
	signal wr_data 	: unsigned((W-1) downto 0);	-- Data to write to FIFO
	signal fifo_full 	: std_logic;						-- Binary signal flag for fifo is full	(also used in FSM2)
	
	-- FSM2 Signals --	
	signal rd_data 	: unsigned((W-1) downto 0);	-- Data to read from FIFO
	signal fifo_empty : std_logic;					-- Binary signal flag for fifo is empty
	signal rd_en 		: integer := 0;					-- Enable read from FIFO
		

begin

	-- FSM1 State Controller --
	-- Replace MAX10_CLK1_50 with output from PLL --
	process ( MAX10_CLK1_50 )
	begin
		if rising_edge(MAX10_CLK1_50) then
			if KEY(0) = '0' then
				-- Reset behavior --
				FSM1_current_state <= Clear;
			else
				-- Normal behavior --
				FSM1_current_state <= FSM1_next_state;
			end if;
		end if;
	end process;
	
	
	
	
	
	
	
	-- FSM1 Behavior Controller --
	process ( KEY, timer, fifo_full )
	begin
		--case FSM1_current_state is
			
			
			
		--end case;
	end process;
	
	
	
	
	
	
	
	-- FSM2 State Controller --
	-- Replace MAX10_CLK1_50 with output from PLL --
	process ( MAX10_CLK1_50 )
	begin
		if rising_edge(MAX10_CLK1_50) then
			if KEY(0) = '0' then
				-- Reset behavior --
				FSM2_current_state <= Clear;
			else
				-- Normal behavior --
				FSM2_current_state <= FSM1_next_state;
			end if;
		end if;
	end process;
	
	
	
	
	
	
	
	-- FSM2 Behavior Controller --
	process ( KEY, fifo_empty, fifo_full )
	begin
		--case FSM2_current_case is
		
		
		
		--end case;
	end process;
	
	
	-- Constant update LEDR Process --
	process (MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then
			LEDR <= SW;
		end if;
	end process;
	
	
	

end architecture behavioral;
