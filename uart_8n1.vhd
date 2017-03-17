library ieee;
use ieee.std_logic_1164.all;

entity uart_8n1 is

	generic (
	clock_freq : integer;
	baud_rate : integer);

	port ( clock : in  std_logic;
	reset : in  std_logic;
	rx : in  std_logic;
	tx_byte : in  std_logic_vector(7 downto 0);
	tx_start : in  std_logic;
	tx : out  std_logic;
	tx_idle : out  std_logic;
	rx_byte : out  std_logic_vector(7 downto 0);
	rx_complete : out  std_logic;
	rx_error : out  std_logic);

end uart_8n1;

architecture behavioral of uart_8n1 is

	component uart_rx
		generic (
		clock_freq : integer;
		baud_rate : integer);

		port(
		clock : in std_logic;
		reset : in std_logic;
		rx : in std_logic;          
		rx_byte : out std_logic_vector(7 downto 0);
		rx_complete : out std_logic;
		rx_error : out std_logic);
	end component;

	component uart_tx
		generic (
		clock_freq : integer;
		baud_rate : integer);

		port(
		clock : in std_logic;
		reset : in std_logic;
		tx_byte : in std_logic_vector(7 downto 0);
		tx_start : in std_logic;          
		tx : out std_logic;
		tx_idle : out std_logic);
	end component;
begin

	inst_uart_rx: uart_rx generic map(
		clock_freq => clock_freq,
		baud_rate => baud_rate
	) port map(
		clock => clock,
		reset => reset,
		rx => rx,
		rx_byte => rx_byte,
		rx_complete => rx_complete,
		rx_error => rx_error);

	inst_uart_tx: uart_tx generic map(
		clock_freq => clock_freq,
		baud_rate => baud_rate
	) port map(
		clock => clock,
		reset => reset,
		tx_byte => tx_byte,
		tx_start => tx_start,
		tx => tx,
		tx_idle => tx_idle);

end behavioral;

