library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
 
entity uart_rx_tb is
end uart_rx_tb;
 
architecture behavior of uart_rx_tb is 
 
	component uart_rx
		port (
		clock : in  std_logic;
		reset : in  std_logic;
		rx : in  std_logic;
		rx_byte : out  std_logic_vector(7 downto 0);
		rx_complete : out  std_logic;
		rx_error : out	std_logic);
	end component;


	signal clock : std_logic := '0';
	signal reset : std_logic := '1';
	signal rx : std_logic := '1';

	signal rx_byte : std_logic_vector(7 downto 0);
	signal rx_complete : std_logic;
	signal rx_error : std_logic;

	constant clock_period : time := 20 ns;

	constant bit_period : time := 104166 ns;

	procedure send_bit(signal rx : out std_logic; constant value : std_logic) is
	begin
		rx <= value;

		wait for bit_period;
	end procedure;

	procedure send_byte(signal rx : out std_logic; constant value : unsigned(7 downto 0); constant stop : std_logic) is
	begin
		send_bit(rx, '0');

		for i in value'reverse_range loop
			send_bit(rx, value(i));
		end loop;

		send_bit(rx, stop);
	end procedure;

begin
 
	uut: uart_rx port map (
		clock => clock,
		reset => reset,
		rx => rx,
		rx_byte => rx_byte,
		rx_complete => rx_complete,
		rx_error => rx_error);

	clock_process :process
	begin
		clock <= '0';
		wait for clock_period / 2;
		clock <= '1';
		wait for clock_period / 2;
	end process;
 
	stim_proc: process
		variable s1, s2 : integer;
		variable r : real;
		variable rand_byte : unsigned(7 downto 0);
		variable rand_stop : std_logic;
	begin

		wait for clock_period * 10;

		reset <= '0';

		wait for 0.1 ms;

		while true loop
			uniform(s1, s2, r);
			rand_byte := to_unsigned(integer(r * 255.0), 8);
			rand_stop := std_logic(to_unsigned(integer(r * 2.0), 1)(0));
			--rand_stop := '1';
			report "random byte: " & integer'image(to_integer(rand_byte));
			report "random stop bit: " & std_logic'image(rand_stop);

			send_byte(rx, rand_byte, rand_stop);

			assert rx_complete = not rx_error report "rx_complete and rx_error both asserted!" severity error;
			assert rx_error = not rand_stop report "rx error!" severity error;
		end loop;

		wait;

	end process;

end;

