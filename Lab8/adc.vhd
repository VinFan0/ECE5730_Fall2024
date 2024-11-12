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
			response_data          : out std_logic_vector(11 downto 0);                    -- data
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
	
	-- ADC Signals --
	signal command_valid          : std_logic                     := 'X';             -- valid
	signal next_command_valid     : std_logic                     := 'X';             -- valid
	signal command_channel        : std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
	signal next_command_channel   : std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
	signal response_valid         : std_logic;                                        -- valid
	signal response_channel       : std_logic_vector(4 downto 0);                     -- channel
	signal response_data          : std_logic_vector(11 downto 0);                    -- data
	
	-- PLL Signals --
	-- signal areset						: std_logic 							:= '0';
	signal c0_sig					      :  std_logic                     := 'X';             -- clk
	signal locked_sig					   :  std_logic                     := 'X';             -- export
	
	-- UNUSED ADC ?? --
	signal command_startofpacket  : std_logic                     := 'X';             -- startofpacket
	signal command_endofpacket    : std_logic                     := 'X';             -- endofpacket
	signal command_ready          : std_logic;                                        -- ready
	signal response_startofpacket : std_logic;                                        -- startofpacket
	signal response_endofpacket   : std_logic;                                        -- endofpacket	
	
	--7-segment display
	type SEVEN_SEG is array (0 to 15) of std_logic_vector(7 downto 0); -- Define new type for lookup table
	constant table : SEVEN_SEG := (	
					X"C0", X"F9", X"A4", X"B0",  -- 0, 1, 2, 3
					X"99", X"92", X"82", X"F8",  -- 4, 5, 6, 7
					X"80", X"90", X"88", X"83",  -- 8, 9, A, B
					X"C6", X"A1", X"86", X"8E"); -- C, D, E, F
					
	-- FSM States
	type state_type is (
		IDLE, 
		START, 
		SEND, 
		WAIT_RESPONSE, 
		READ_DATA
		);
		
	signal state, next_state : state_type;
	
	-- MISC --
	signal sample_counter : integer := 0;
	signal next_sample_counter : integer := 0;
	signal display : unsigned(11 downto 0) := (others => '0');
	signal next_display : unsigned(11 downto 0) := (others => '0');
	

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
			command_channel        => "00000",        							--               .channel
			command_startofpacket  => 'X',  											--               .startofpacket
			command_endofpacket    => 'X',    										--               .endofpacket
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
		areset	 => KEY(0),
		inclk0	 => ADC_CLK_10,
		c0	 		 => c0_sig,
		locked	 => locked_sig
	);

	-- Define module behavior here --
	process(c0_sig)
	begin
		if rising_edge(c0_sig) then
			if KEY(0) = '0' then
				--Reset all signals
				state <= IDLE;
				sample_counter <= 0;
				command_valid <= '0';
				display <= (others => '0');
				--command_startofpacket <= '0';
				--command_endofpacket <= '0';
				--command_channel <= "00000";
				
			else
				--1 Hz Clock Divider
				if sample_counter < SAMPLE_PERIOD - 1 then
					sample_counter <= sample_counter + 1;
					state <= next_state;
					command_valid <= next_command_valid;
				else
					sample_counter <= 0;
					if state = IDLE then
						state <= START;
						command_valid <= next_command_valid;
					else
						state <= next_state;
						command_valid <= next_command_valid;
					end if;
				end if;
				display <= next_display;
			end if;
		end if;
	
	end process;
	
	process(state, command_ready, command_valid, response_valid)
	begin
		
		case state is
			when IDLE =>
				--Wait for sample counter to trigger
				next_command_valid <= '0';
				next_state <= state;
				next_display <= display;
				--command_startofpacket <= '0';
				--command_endofpacket <= '0';
			
			when START =>
				--Preparing to send the packet
				if command_ready = '1' then
					next_command_valid <= '1';
					--command_startofpacket <= '1';
					next_state <= SEND;
					next_display <= display;
				else
					next_command_valid <= command_valid;
					next_state <= state;
					next_display <= display;
				end if;
				
			when SEND =>
				--Finish sending packet
					--command_startofpacket <= '0';
					--command_endofpacket <= '1';
					next_state <= WAIT_RESPONSE;
					next_command_valid <= command_valid;
					next_display <= display;
			
			when WAIT_RESPONSE =>
				--Wait for ADC conversion to complete
				next_command_valid <= '0';
				next_display <= display;
				--command_endofpacket <= '0';
				if response_valid = '1' then
					next_state <= READ_DATA;
				else
					next_state <= state;
				end if;
				
			when READ_DATA =>
				--Read the response data
				next_display <= unsigned(response_data);
				next_state <= IDLE;
				next_command_valid <= command_valid;
				
			when others =>
				next_command_valid <= command_valid;
				next_state <= IDLE;
				next_display <= display;
			
			end case;
				
	end process;
	
	--process to update display?
	process (ADC_CLK_10)
	begin
		if rising_edge(ADC_CLK_10) then
			HEX0 <= table(to_integer(display(3 downto 0)));
			HEX1 <= table(to_integer(display(7 downto 4)));
			HEX2 <= table(to_integer(display(11 downto 8)));
			HEX3 <= X"FF";
			HEX4 <= X"FF";
			HEX5 <= X"FF";
		end if;
	end process;

end architecture behavioral;
