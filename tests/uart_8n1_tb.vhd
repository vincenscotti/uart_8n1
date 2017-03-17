library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
 
entity uart_8n1_tb is
end uart_8n1_tb;
 
architecture behavior of uart_8n1_tb is 
 
	component uart_8n1
		generic (
		clock_freq : integer := 50e6;
		baud_rate : integer := 9600);

		port(
		clock : in  std_logic;
		reset : in  std_logic;
		rx : in  std_logic;
		tx_byte : in  std_logic_vector(7 downto 0);
		tx_start : in  std_logic;
		tx : out  std_logic;
		tx_idle : out  std_logic;
		rx_byte : out  std_logic_vector(7 downto 0);
		rx_complete : out  std_logic;
		rx_error : out  std_logic);
	end component;

	signal clock : std_logic := '0';
	signal reset : std_logic := '1';
	signal tx_byte : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_start : std_logic := '0';

	signal tx_idle : std_logic;
	signal rx_byte : std_logic_vector(7 downto 0);
	signal rx_complete : std_logic;
	signal rx_error : std_logic;

	signal cable : std_logic;

	constant clock_period : time := 10 ns;

begin

	uut: uart_8n1 generic map(
	clock_freq => 100e6,
	baud_rate => 115200
	) port map (
		clock => clock,
		reset => reset,
		rx => cable,
		tx_byte => tx_byte,
		tx_start => tx_start,
		tx => cable,
		tx_idle => tx_idle,
		rx_byte => rx_byte,
		rx_complete => rx_complete,
		rx_error => rx_error
	);

	clock_process :process
	begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
	end process;

	stim_proc: process
		variable s1, s2 : integer;
		variable r : real;
		variable rand_byte : std_logic_vector(7 downto 0);
	begin
		wait for clock_period * 10;

		reset <= '0';

		wait for 0.1 ms;

		while true loop
			uniform(s1, s2, r);
			rand_byte := std_logic_vector(to_unsigned(integer(r * 255.0), 8));
			report "random byte: " & integer'image(to_integer(unsigned(rand_byte)));

			tx_byte <= rand_byte;
			tx_start <= '1';

			wait for clock_period;
			tx_start <= '0';

			wait until tx_idle = '1' and rx_complete = '1';
			assert rx_byte = tx_byte report "Tx and rx differ!" severity error;
		end loop;

		wait;
	end process;

end;

