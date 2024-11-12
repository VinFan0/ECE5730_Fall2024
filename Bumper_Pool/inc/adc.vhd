library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --
		SAMPLE_PERIOD : integer := 10000000

	);

	port (
	     	-- Declare module ports here --
		-- NAME : DIRECTION TYPE (separated by ; ) --
		
		-- CLK input --
		ADC_CLK_10	: in std_logic; -- 10 MHz
		--MAX10_CLK1_50 	: in std_logic; -- 50 MHz 1
		--MAX10_CLK2_50 	: in std_logic; -- 50 MHz 2

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
		
		-- Arduino Header --
		ARDUINO_IO			: inout std_logic_vector(15 downto 0);
		ARDUINO_RESET_N	: inout std_logic
		
	);

end entity adc;

architecture behavioral of adc is

	-- Components --
	-- ADC --
	component my_ADC is
		port (
			clock_clk              : in  std_logic                     := 'X';             -- clk
			reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
			adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
			command_valid          : in  std_logic                     := 'X';             -- valid
			command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_ready          : out std_logic;                                        -- ready
			response_valid         : out std_logic;                                        -- valid
			response_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_data          : out unsigned(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component my_ADC;
	
	-- PLL --
	component my_PLL IS
		PORT
		(
			areset	: IN STD_LOGIC  := '0';
			inclk0	: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC ;
			locked	: OUT STD_LOGIC 
		);
	END component;

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	
	-- ADC Command Signals --
	signal command_valid          : std_logic							  := '1';            -- valid
	signal command_channel        : std_logic_vector(4 downto 0)  := "00001";  		-- channel
	signal command_startofpacket  : std_logic                     := '1';            -- startofpacket
	signal command_endofpacket    : std_logic                     := '1';            -- endofpacket
	signal command_ready          : std_logic;                                       -- ready
	
	-- ADC Response Signals --
	signal response_valid         : std_logic;                                  		-- valid
	signal response_channel       : std_logic_vector(4 downto 0);               		-- channel
	signal response_data          : unsigned(11 downto 0);              		-- data
	signal response_startofpacket : std_logic;                                  		-- startofpacket
	signal response_endofpacket   : std_logic;                                  		-- endofpacket	
	
	-- PLL Signals --
	signal c0_sig					      :  std_logic                     := 'X';        -- clk
	signal locked_sig					   :  std_logic                     := 'X';        -- export
	
	
	--7-segment display
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F
	
	-- MISC --
	signal sample_counter : integer := 0;
	signal sample_trigger : std_logic;
	signal display : unsigned(11 downto 0) := (others => '0');
	signal next_display : unsigned(11 downto 0) := (others => '0');
	signal temp_display : integer;
	

begin
	
	-- Instantiate IP Blocks --

	-- ADC --
	u0 : component my_ADC
		port map (
			-- Input
			clock_clk              => ADC_CLK_10,             					--          clock.clk
			reset_sink_reset_n     => KEY(0),  				   					--     reset_sink.reset_n
			adc_pll_clock_clk      => c0_sig,      								--  adc_pll_clock.clk
			adc_pll_locked_export  => locked_sig,  								-- adc_pll_locked.export
			command_valid          => command_valid,          					--        command.valid
			command_channel        => command_channel,        					--               .channel
			command_startofpacket  => command_startofpacket,  					--               .startofpacket
			command_endofpacket    => command_endofpacket,    					--               .endofpacket
			-- Output
			command_ready          => command_ready,          					--               .ready
			response_valid         => response_valid,         					--       response.valid
			response_channel       => response_channel,       					--               .channel
			response_data          => response_data,          					--               .data
			response_startofpacket => response_startofpacket, 					--               .startofpacket
			response_endofpacket   => response_endofpacket    					--               .endofpacket
		);
		
	-- PLL --
	my_PLL_inst : my_PLL PORT MAP (
		areset	 => NOT KEY(0),
		inclk0	 => ADC_CLK_10,
		c0	 		 => c0_sig,
		locked	 => locked_sig
	);

	-- Timing Controller --
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			if sample_counter < SAMPLE_PERIOD - 1 then
				sample_counter <= sample_counter + 1;
				sample_trigger <= '0';
			else
				sample_counter <= 0;
				sample_trigger <= '1';
			end if;
		end if;
	end process;
	
	-- Sampling controller --
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			if (response_valid = '1') then
				temp_display <= to_integer(response_data) * 2 * 2500 / 4094;
				display <= to_unsigned(temp_display, display'length);
			end if;
		end if;
	end process;
	
	--process to drive 7 segment
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			if (sample_trigger = '1') then
				HEX0 <= table(to_integer(display(3 downto 0)));
				HEX1 <= table(to_integer(display(7 downto 4)));
				HEX2 <= table(to_integer(display(11 downto 8)));
				HEX3 <= X"FF";
				HEX4 <= X"FF";
				HEX5 <= X"FF";
			elsif KEY(0) = '0' then
				HEX0 <= table(0);
				HEX1 <= table(0);
				HEX2 <= table(0);
				HEX3 <= X"FF";
				HEX4 <= X"FF";
				HEX5 <= X"FF";
			end if;
		end if;
	end process;

end architecture behavioral;
