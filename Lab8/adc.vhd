library ieee;
use ieee.std_logic_1164.all
use ieee.numeric_std.all;

entity adc is

	generic(
		--     Add generics here     --
		-- NAME : TYPE := DEFAULT_VALUE (separated by , ) --

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
		HEX6 : out std_logic_vector(7 downto 0)
		
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
			response_data          : out std_logic_vector(11 downto 0);                    -- data
			response_startofpacket : out std_logic;                                        -- startofpacket
			response_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component my_ADC;
	
	-- PLL --
	--------------------------------------------------------------------------
										-- FILL THIS IN --
	--------------------------------------------------------------------------
	

	-- Declare internal signals here -- (terminated by ; )
	-- signal NAME : TYPE ;
	
	-- ADC Signals --
	signal clock_clk              : in  std_logic                     := 'X';             -- clk
	signal reset_sink_reset_n     : in  std_logic                     := 'X';             -- reset_n
	signal adc_pll_clock_clk      : in  std_logic                     := 'X';             -- clk
	signal adc_pll_locked_export  : in  std_logic                     := 'X';             -- export
	signal command_valid          : in  std_logic                     := 'X';             -- valid
	signal command_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
	signal command_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
	signal command_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
	signal command_ready          : out std_logic;                                        -- ready
	signal response_valid         : out std_logic;                                        -- valid
	signal response_channel       : out std_logic_vector(4 downto 0);                     -- channel
	signal response_data          : out std_logic_vector(11 downto 0);                    -- data
	signal response_startofpacket : out std_logic;                                        -- startofpacket
	signal response_endofpacket   : out std_logic                                         -- endofpacket	
	
	

begin
	
	-- Instantiate IP Blocks --

	-- ADC --
	--------------------------------------------------------------------------
										-- FILL THIS IN --
	--------------------------------------------------------------------------
	u0 : component my_ADC
		port map (
			clock_clk              => CONNECTED_TO_clock_clk,              --          clock.clk
			reset_sink_reset_n     => CONNECTED_TO_reset_sink_reset_n,     --     reset_sink.reset_n
			adc_pll_clock_clk      => CONNECTED_TO_adc_pll_clock_clk,      --  adc_pll_clock.clk
			adc_pll_locked_export  => CONNECTED_TO_adc_pll_locked_export,  -- adc_pll_locked.export
			command_valid          => CONNECTED_TO_command_valid,          --        command.valid
			command_channel        => CONNECTED_TO_command_channel,        --               .channel
			command_startofpacket  => CONNECTED_TO_command_startofpacket,  --               .startofpacket
			command_endofpacket    => CONNECTED_TO_command_endofpacket,    --               .endofpacket
			command_ready          => CONNECTED_TO_command_ready,          --               .ready
			response_valid         => CONNECTED_TO_response_valid,         --       response.valid
			response_channel       => CONNECTED_TO_response_channel,       --               .channel
			response_data          => CONNECTED_TO_response_data,          --               .data
			response_startofpacket => CONNECTED_TO_response_startofpacket, --               .startofpacket
			response_endofpacket   => CONNECTED_TO_response_endofpacket    --               .endofpacket
		);
		
	-- PLL --
	--------------------------------------------------------------------------
										-- FILL THIS IN --
	--------------------------------------------------------------------------
	

	-- Define module behavior here --
	process(PLL_ADC, reset)
	begin
		if Key(0) = '0' then
			--Reset all signals
			next_state <= IDLE;
			sample_counter <= 0;
			commmand_valid <= '0';
			command_startofpacket <= '0';
			command_endofpacket <= '0';
			command_channel <= "00000";
			
		elsif rising_edge(PLL_ADC) then
			--1 Hz Clock Divider
			if sample_counter < SAMPLE_PERIOD - 1 then
				next_sample_counter <= sample_counter + 1;
			else
				sample_counter <= 0;
				if next_state = IDLE then
					next_state <= START;
				end if;
			end if;
		end if;
		case next_state is
			when IDLE =>
				--Wait for sample counter to trigger
				command_valid <= '0';
				command_startofpacket <= '0';
				command_endofpacket <= '0';
			
			when START =>
				--Preparing to send the packet
				if command_ready = '1' then
					command_valid <= '1';
					command_startofpacket <= '1';
					next_state <= SEND;
				end if;
				
			when SEND =>
				--Finish sending packet
					command_startofpacket <= '0';
					command_endofpacket <= '1';
					next_state <= WAIT_RESPONSE;
			
			when WAIT_RESPONSE =>
				--Wait for ADC conversion to complete
				command_valid <= '0';
				command_endofpacket <= '0';
				if response_valid = '1' then
					next_state <= READ_DATA;
				end if;
				
			when READ_DATA =>
				--Read the response data
				current_display <= response_data;
				next_state <= IDLE;
				
			when others =>
				state <= IDLE;
			
			end case;
				
	end process;
	
	--process to update display?

end architecture behavioral;
