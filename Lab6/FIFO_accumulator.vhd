library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_accumulator is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by ; ) --
		DELAY : integer := 2500000 	-- Number of clock cycles for debounce

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

		-- Switches --
		SW : in std_logic_vector(9 downto 0);
		
		-- LEDs --
		LEDR : out std_logic_vector(9 downto 0)
	);

end entity fifo_accumulator;

architecture behavioral of fifo_accumulator is

	-- Components --
	-- FIFO --
	component accum_FIFO IS
		PORT
		(
			aclr		: IN STD_LOGIC  := '0';
			data		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q			: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);
			rdempty	: OUT STD_LOGIC ;
			rdusedw	: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
			wrusedw	: OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
		);
	END component;
	
	-- PLL --
	component my_PLL IS
		PORT
		(
			areset	: IN STD_LOGIC  := '0';
			inclk0	: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC ;
			c1			: OUT STD_LOGIC ;
			locked	: OUT STD_LOGIC 
		);
	END component;

	-- Variables 
	signal add		: integer;
	signal sum 	 	: unsigned(23 downto 0);	-- Accumulated total
	signal timer 	: integer := 0;				-- Timer for debounce
	
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
	
	-- PLL Signals --
	signal pll_Reset		: std_logic := '0';	-- Reset PLL
	signal pll_outCLK1	: std_logic;			-- PLL output clock 1
   signal pll_outCLK2	: std_logic;			-- PLL output clock 2
	signal pll_locked		: std_logic;			-- PLL Locked
	
	-- FSM1 Signals --
	signal wr_en 			: std_logic;							-- Enable write to FIFO
	signal wr_data 		: std_logic_vector(9 downto 0);	-- Data to write to FIFO
	signal fifo_full 		: std_logic;							-- Binary signal flag for fifo is full	(also used in FSM2)
	signal word_count_wr : std_logic_vector(6 downto 0);	-- How many words are used write side
	
	-- FSM2 Signals --	
	signal rd_data	 		: std_logic_vector(9 downto 0);	-- Data to read from FIFO
	signal fifo_empty		: std_logic;							-- Binary signal flag for fifo is empty
	signal rd_en 			: std_logic;							-- Enable read from FIFO
	signal fifo_clear		: std_logic;							-- Set to clear FIFO
	signal word_count_rd	: std_logic_vector(6 downto 0);	-- How many words are used read side
	
	-- Misc FIFO Signals --
	signal aclr_sig : STD_LOGIC;
	
	
begin

	-- Instantiate FIFO IP --
	accum_FIFO_inst : accum_FIFO PORT MAP (
		aclr	 	=> aclr_sig,		-- Ansychronous clear
		data	 	=> wr_data,			-- Data into FIFO
		rdclk	 	=> MAX10_CLK1_50, -- Change to PLL output FMS2
		rdreq	 	=> rd_en,			-- Read acknowledge
		wrclk	 	=> MAX10_CLK1_50, -- Change to PLL output FMS1
		wrreq		=> wr_en,			-- Write enable
		q	 		=> rd_data,			-- Data out of FIFO
		rdempty	=> fifo_empty,		-- Read side empty
		rdusedw	=> word_count_rd,	-- Read side word count
		wrusedw	=> word_count_wr	-- Write side word count
	);

	
	-- Instantiate PLL IP --
	my_PLL_inst : my_PLL 
		PORT MAP (
			areset	=> pll_Reset,
			inclk0	=> MAX10_CLK1_50,
			c0	 		=> pll_outCLK1,
			c1	 		=> pll_outCLK2,
			locked	=> pll_locked	
		);
		
	-- Asynchronous Clear of FIFO --
	process ( KEY(0) )
	begin
		if (KEY(0) = '0') then
			aclr_sig <= '1';
		else
			aclr_sig <= '0';
		end if;
	end process;
	
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
	process ( KEY, timer, fifo_full, MAX10_CLK1_50 )
	begin
		--case FSM1_current_state is
		if rising_edge(MAX10_CLK1_50) then
			case FSM1_current_state is
				when Clear =>
					--Reset
					wr_data <= (others => '0');
					wr_en <= '0';
					timer <= 0;
					--If reset is released
					if KEY(0) = '1' then
						--Move to next state
						FSM1_next_state <= Waiting;
					else 
						FSM1_next_state <= Clear;
					end if;
					
				when Waiting =>
					--If reset is pushed
					wr_data <= (others => '0');
					wr_en <= '0';
					timer <= 0;
					if KEY(0) = '0' then
						--Go to clear
						FSM1_next_state <= Clear;
					--If add is pressed
					elsif KEY(1) = '0' then
						--Next state is debounce
						FSM1_next_state <= Debounce;
					end if;
				
				when Debounce =>
					wr_data <= (others => '0');
					wr_en <= '0';
					--If timer = DELAY
					if timer = DELAY then
						--If add is still pressed
						if KEY(1) = '0' then
							--Next state is pressed
							FSM1_next_state <= Pressed;
						else
							--Next state is waiting
							FSM1_next_state <= Waiting;
						end if;
					else
						--Increment timer
						timer <= timer + 1;
						FSM1_next_state <= Debounce;
					end if;
					
				when Pressed =>
					timer <= 0;
					--Wait for add to be released
					if KEY(1) = '1' then
						wr_en <= '0';
						--Next state is check
						FSM1_next_state <= Check;
						--Write data to fifo
						wr_data <= SW;
					else 
						wr_en <= '0';
						wr_data <= (others => '0');
						FSM1_next_state <= Pressed;
					end if;
					
				when Check =>
					timer <= 0;
					--If FIFO is full
					if word_count_wr = "0000101" then
						wr_en <= '0';
						wr_data <= (others => '0');
						--Next state is waiting
						FSM1_next_state <= Waiting;
					--If fifo is not full
					else
						--Next state is Writing
						if wr_en = '1' then
							wr_en <= '0';
						else
							wr_en <= '1';
						end if;
						FSM1_next_state <= Writing;
					end if;
					
				when Writing =>
					timer <= 0;
					--Disable wr_en
					wr_data <= (others => '0');
					--Next state is waiting
					FSM1_next_state <= Waiting;
					
				when others => 
					--Default to waiting
					FSM1_next_state <= Waiting;
					wr_data <= (others => '0');
					wr_en <= '0';
					timer <= 0;
					
			end case;
		end if;
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
				FSM2_current_state <= FSM2_next_state;
			end if;
		end if;
	end process;
	
	
	
	
	
	
	
	-- FSM2 Behavior Controller --
	process ( KEY, fifo_empty, fifo_full, MAX10_CLK1_50, rd_en )
	begin
		if rising_edge(MAX10_CLK1_50) then
			case FSM2_current_state is
				when Clear =>
					--Reset 
					sum <= (others => '0');
					add <= 0;
					rd_en <= '0';
					-- Clear 7 Segment
					HEX0 <= table(0);
					HEX1 <= table(0);
					HEX2 <= table(0);
					HEX3 <= table(0);
					HEX4 <= table(0);
					HEX5 <= table(0);
					
					--If reset is released
					if KEY(0) = '1' then
						--Enable Read
						fifo_clear <= '1';
						--Move to next state
						FSM2_next_state <= Empty;
					else 
						FSM2_next_state <= Clear;
					end if;
				when Empty =>
					--If fifo is empty
					if fifo_empty = '1' then
						--Disable read
						fifo_clear <= '0';
						--Next State is waiting
						FSM2_next_state <= Waiting;
					end if;
				
				when Waiting =>
						if word_count_rd = "0000101" then
							--Next state is accumulate
							FSM2_next_state <= Accumulate;
							-- Set read enable
							rd_en <= '0';
						else
							FSM2_next_state <= Waiting;
						end if;
				
				when Accumulate =>
					--If fifo_empty
					if fifo_empty = '1' then
						--disable read
						rd_en <= '0';
						--if MAX10_CLK1_50 = '0' then
						
							--add sum with rd_data
							sum <= sum + unsigned(rd_data);
							
						--end if;
						--Next state display
						FSM2_next_state <= Display;
					else
						rd_en <= '1';
						if rd_en = '1' then
							--add sum with rd_data
							sum <= sum + unsigned(rd_data);
						end if;
							
						FSM2_next_state <= Accumulate;
					--end if;
					end if;
				
				when Display => 
					-- Update 7-Segment --
					HEX0 <= table(to_integer(sum(3 downto 0)));
					HEX1 <= table(to_integer(sum(7 downto 4)));
					HEX2 <= table(to_integer(sum(11 downto 8)));
					HEX3 <= table(to_integer(sum(15 downto 12)));
					HEX4 <= table(to_integer(sum(19 downto 16)));
					HEX5 <= table(to_integer(sum(23 downto 20)));
					FSM2_next_state <= Waiting;
		
				when others => 
					--Default to Waiting
					FSM2_next_state <= Waiting;
				
			end case;
		end if;
	end process;
	
	
	-- Constant update LEDR Process --
	process (MAX10_CLK1_50)
	begin
		if rising_edge(MAX10_CLK1_50) then
			LEDR <= SW;
		end if;
	end process;
	
	
	

end architecture behavioral;
