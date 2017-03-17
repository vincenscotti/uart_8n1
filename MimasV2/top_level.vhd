library ieee;
use ieee.std_logic_1164.all;

entity top_level is
	port ( clock : in  std_logic;
	reset_n : in  std_logic;
	rx : in  std_logic;
	tx : out  std_logic;
	rx_byte : out  std_logic_vector(7 downto 0));
end top_level;

architecture behavioral of top_level is

	component uart_8n1
		generic (
		clock_freq : integer;
		baud_rate : integer);

		port(
		clock : in std_logic;
		reset : in std_logic;
		rx : in std_logic;
		tx_byte : in std_logic_vector(7 downto 0);
		tx_start : in std_logic;          
		tx : out std_logic;
		tx_idle : out std_logic;
		rx_byte : out std_logic_vector(7 downto 0);
		rx_complete : out std_logic;
		rx_error : out std_logic);
	end component;

	signal reset : std_logic;
	signal rx_error : std_logic;
	signal rx_complete : std_logic;
	signal tx_start : std_logic;
	signal rx_byte_internal : std_logic_vector(7 downto 0);

	type FSM_State is (idle, echo, done);
	signal current_state, next_state : FSM_State;

begin

	inst_uart_8n1: uart_8n1 generic map (
		clock_freq => 100e6,
		baud_rate => 19200
	) port map (
		clock => clock,
		reset => reset,
		rx => rx,
		tx_byte => rx_byte_internal,
		tx_start => tx_start,
		tx => tx,
		tx_idle => open,
		rx_byte => rx_byte_internal,
		rx_complete => rx_complete,
		rx_error => rx_error
	);

	rx_byte <= rx_byte_internal;

	reset <= not reset_n;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				current_state <= idle;
			else
				current_state <= next_state;
			end if;
		end if;
	end process;

	process (current_state, rx_complete)
	begin
		case (current_state) is
			when idle =>
				next_state <= idle;

				if rx_complete = '1' then
					next_state <= echo;
				end if;

			when echo =>
				next_state <= done;

			when done =>
				next_state <= done;

				if rx_complete = '0' then
					next_state <= idle;
				end if;
		end case;
	end process;

	process (current_state, rx_complete)
	begin

		case (current_state) is
			when idle =>
				tx_start <= '0';

			when echo =>
				tx_start <= '1';

			when done =>
				tx_start <= '0';
		end case;
	end process;

end behavioral;

