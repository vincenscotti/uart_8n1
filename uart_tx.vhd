library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tx is

	generic (
	clock_freq : integer;
	baud_rate : integer);

	port (
	clock : in  std_logic;
	reset : in  std_logic;
	tx_byte : in  std_logic_vector(7 downto 0);
	tx_start : in  std_logic;
	tx : out  std_logic;
	tx_idle : out  std_logic);

end uart_tx;

architecture behavioral of uart_tx is

	constant clock_div : integer := clock_freq / baud_rate;
	constant clock_div_bits : integer := integer(ceil(log2(real(clock_div))));

	signal clock_counter : unsigned(clock_div_bits downto 0);
	signal clock_counter_rst : std_logic;

	signal tx_clock : std_logic;

	type tx_state is (idle, nth_bit);
	signal current_state, next_state : tx_state;

	signal shift_en : std_logic;
	signal shift_ld : std_logic;
	signal tx_idle_rst : std_logic;
	signal tx_idle_set : std_logic;

	signal bit_counter : unsigned(7 downto 0);
	signal bit_counter_rst : std_logic;

	signal rsr : std_logic_vector(9 downto 0) := (others => '1');

begin

	tx <= rsr(0);

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

	process (current_state, tx_start, tx_clock, bit_counter)
	begin
		case (current_state) is
			when idle =>
				next_state <= idle;

				if tx_start = '1' then
					next_state <= nth_bit;
				end if;

			when nth_bit =>
				next_state <= nth_bit;

				if bit_counter = "1001" and tx_clock = '1' then
					next_state <= idle;
				end if;
		end case;
	end process;

	process (current_state, tx_start, tx_clock)
	begin
		bit_counter_rst <= '0';
		clock_counter_rst <= '0';
		shift_en <= '0';
		shift_ld <= '0';
		tx_idle_rst <= '0';
		tx_idle_set <= '0';

		case (current_state) is
			when idle =>
				if tx_start = '1' then
					bit_counter_rst <= '1';
					clock_counter_rst <= '1';
					shift_ld <= '1';
					tx_idle_rst <= '1';
				else
					tx_idle_set <= '1';
				end if;

			when nth_bit =>
				if tx_clock = '1' then
					shift_en <= '1';
				end if;
		end case;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1'  or tx_idle_rst = '1' then
				tx_idle <= '0';
			elsif tx_idle_set   = '1' then
				tx_idle  <= '1';
			end if;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				rsr <= (others => '1');
			elsif shift_ld = '1' then
				rsr <= '1' & tx_byte & '0';
			elsif shift_en = '1' then
				rsr <= '1' & rsr(9 downto 1);
			end if;
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if reset = '1' or clock_counter_rst = '1' or clock_counter = clock_div then
				clock_counter <= to_unsigned(0, clock_div_bits + 1);
			else
				clock_counter <= clock_counter + 1;
			end if;
		end if;
	end process;

	process (clock_counter)
	begin
		tx_clock <= '0';

		if clock_counter = to_unsigned(clock_div, clock_div_bits + 1) then
			tx_clock <= '1';
		end if;
	end process;

	process (clock)
	begin
		if rising_edge(clock) then
			if bit_counter_rst = '1' or reset = '1' then
				bit_counter <= (others => '0');
			elsif tx_clock = '1' then
				bit_counter <= bit_counter + 1;
			end if;
		end if;
	end process;

end behavioral;

