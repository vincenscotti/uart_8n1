library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
 
entity uart_tx_tb is
end uart_tx_tb;
 
architecture behavior of uart_tx_tb is 
 
	component uart_tx
	port (
		clock : in  std_logic;
		reset : in  std_logic;
		tx_byte : in  std_logic_vector(7 downto 0);
		tx_start : in  std_logic;
		tx : out  std_logic;
		tx_idle : out  std_logic);
	end component;

	signal clock : std_logic := '0';
	signal reset : std_logic := '1';
	signal tx_byte : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_start : std_logic := '0';

	signal tx : std_logic;
	signal tx_idle : std_logic;

	constant clock_period : time := 20 ns;
 
begin
 
	uut: uart_tx port map (
		clock => clock,
		reset => reset,
		tx_byte => tx_byte,
		tx_start => tx_start,
		tx => tx,
		tx_idle => tx_idle);

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

			wait until tx_idle = '1';
		end loop;

		wait;
	end process;

end;

