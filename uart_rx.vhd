library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_rx is

	generic (
	clock_freq : integer;
	baud_rate : integer);

	port (
	clock : in std_logic;
	reset : in std_logic;
	rx : in std_logic;
	rx_byte : out std_logic_vector(7 downto 0);
	rx_complete : out std_logic;
	rx_error : out std_logic);

end uart_rx;

architecture behavioural of uart_rx is

	constant clock_div : integer := clock_freq / baud_rate / 16;
	constant clock_div_bits : integer := integer(log2(real(clock_div)));

	signal clock_counter : unsigned(clock_div_bits downto 0);

	signal sample_clock : std_logic;

	type rx_state is (idle, start_bit, nth_bit, done);
	signal current_state, next_state : rx_state;

	signal shift_en : std_logic;
	signal rx_error_update : std_logic;
	signal rx_complete_reset  : std_logic;
	signal rx_complete_set  : std_logic;

	signal counter : unsigned(7 downto 0);
	signal counter_rst : std_logic;

	alias bit_count is counter(7 downto 4);
	alias sample_count is counter(3 downto 0);

	signal rsr : std_logic_vector(8 downto 0);

begin

	rx_byte <= rsr(7 downto 0);

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

	process (current_state, rx, sample_count, sample_clock, bit_count)
	begin
		case (current_state) is
			when idle =>
				next_state <= idle;

				if rx = '0' then
					next_state <= start_bit;
				end if;

			when start_bit =>
				next_state <= start_bit;

				if sample_count = "0111" and sample_clock = '1' then
					next_state <= nth_bit;
				end if;

			when nth_bit =>
				next_state <= nth_bit;

				if bit_count = "1001" then
					next_state <= done;
				end if;

			when done =>
				next_state <= done;

				if rx = '0' then
					next_state <= start_bit;
				end if;
		end case;
	end process;

	process (current_state, rx, sample_clock, sample_count)
	begin
		counter_rst <= '0';
		shift_en <= '0';
		rx_error_update <= '0';
		rx_complete_reset <= '0';
		rx_complete_set <= '0';

		case (current_state) is
			when idle =>
				if rx = '0' then
					counter_rst <= '1';
					rx_complete_reset <= '1';
				end if;

			when start_bit =>
				if sample_count = "0111" and sample_clock = '1' then
					counter_rst <= '1';
				end if;

			when nth_bit =>
				if sample_count = "1111" and sample_clock = '1' then
					shift_en <= '1';
				end if;

			when done =>
				rx_error_update <= '1';

				if rx = '0' then
					counter_rst <= '1';
					rx_complete_set <= '0';
					rx_complete_reset <= '1';
				else
					rx_complete_set <= '1';
				end if;
		end case;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1'  or rx_complete_reset = '1' then
				rx_complete <= '0';
			elsif rx_complete_set  = '1' then
				rx_complete  <= '1';
			end if;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				rx_error <= '0';
			elsif rx_error_update = '1' then
				rx_error <= not rsr(8);
			end if;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				rsr <= (others => '0');
			elsif shift_en = '1' then
				rsr <= rx & rsr(8 downto 1);
			end if;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' or clock_counter = clock_div then
				clock_counter <= to_unsigned(0, clock_div_bits + 1);
			else
				clock_counter <= clock_counter + 1;
			end if;
		end if;
	end process;

	process (clock_counter)
	begin
		sample_clock <= '0';

		if clock_counter = to_unsigned(clock_div, clock_div_bits + 1) then
			sample_clock <= '1';
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if counter_rst = '1' or reset = '1' then
				counter <= (others => '0');
			elsif sample_clock = '1' then
				counter <= counter + 1;
			end if;
		end if;
	end process;

end behavioural;

