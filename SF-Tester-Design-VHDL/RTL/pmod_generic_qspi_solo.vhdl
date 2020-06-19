--------------------------------------------------------------------------------
-- MIT License
--
-- Copyright (c) 2020 Timothy Stotts
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--------------------------------------------------------------------------------
-- \file pmod_generic_qspi_solo.vhdl
--
-- \brief Custom SPI driver for generic usage, able to operate Enhanced SPI on a
-- Quad I/O SPI bus. Quad I/O is stubbed, but incomplete.
--
-- \description A new SPI transaction can be issued when \ref o_spi_idle
-- indicates a '1'.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--------------------------------------------------------------------------------
entity pmod_generic_qspi_solo is
	generic(
		-- Ratio of i_ext_spi_clk_x to SPI sck bus output.
		parm_ext_spi_clk_ratio : natural := 32;
		-- LOG2 of the TX FIFO max count
		parm_tx_len_bits : natural := 9;
		-- LOG2 of max Wait Cycles count between end of TX and start of RX
		parm_wait_cyc_bits : natural := 9;
		-- LOG2 of the RX FIFO max count
		parm_rx_len_bits : natural := 9
	);
	port(
		-- system clock and reset, with clock being MMCM generated as 4x the
		-- SPI bus speed
		i_ext_spi_clk_x : in std_logic;
		i_srst          : in std_logic;
		i_spi_ce_4x     : in std_logic;
		-- SPI machine system interfaces
		i_go_stand  : in  std_logic;
		i_go_quadio : in  std_logic;
		o_spi_idle  : out std_logic;
		i_tx_len    : in  std_logic_vector((parm_tx_len_bits - 1) downto 0);
		i_wait_cyc  : in  std_logic_vector((parm_wait_cyc_bits - 1) downto 0);
		i_rx_len    : in  std_logic_vector((parm_rx_len_bits - 1) downto 0);
		-- SPI machine FIFO interfaces for TX
		i_tx_data    : in  std_logic_vector(7 downto 0);
		i_tx_enqueue : in  std_logic;
		o_tx_ready   : out std_logic;
		-- SPI machine FIFO interfaces for RX
		o_rx_data    : out std_logic_vector(7 downto 0);
		i_rx_dequeue : in  std_logic;
		o_rx_valid   : out std_logic;
		o_rx_avail   : out std_logic;
		-- SPI machine external interface to top-level
		eio_sck_o      : out std_logic;
		eio_sck_t      : out std_logic;
		eio_ssn_o      : out std_logic;
		eio_ssn_t      : out std_logic;
		eio_mosi_dq0_o : out std_logic;
		eio_mosi_dq0_i : in  std_logic;
		eio_mosi_dq0_t : out std_logic;
		eio_miso_dq1_o : out std_logic;
		eio_miso_dq1_i : in  std_logic;
		eio_miso_dq1_t : out std_logic;
		eio_wrpn_dq2_o : out std_logic;
		eio_wrpn_dq2_i : in  std_logic;
		eio_wrpn_dq2_t : out std_logic;
		eio_hldn_dq3_o : out std_logic;
		eio_hldn_dq3_i : in  std_logic;
		eio_hldn_dq3_t : out std_logic
	);
end entity pmod_generic_qspi_solo;
--------------------------------------------------------------------------------
architecture spi_hybrid_fsm of pmod_generic_qspi_solo is
	COMPONENT fifo_generator_3
		PORT (
			clk        : IN  STD_LOGIC;
			srst       : IN  STD_LOGIC;
			din        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			wr_en      : IN  STD_LOGIC;
			rd_en      : IN  STD_LOGIC;
			dout       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			full       : OUT STD_LOGIC;
			empty      : OUT STD_LOGIC;
			valid      : OUT STD_LOGIC;
			data_count : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT fifo_generator_4
		PORT (
			clk        : IN  STD_LOGIC;
			srst       : IN  STD_LOGIC;
			din        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			wr_en      : IN  STD_LOGIC;
			rd_en      : IN  STD_LOGIC;
			dout       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			full       : OUT STD_LOGIC;
			empty      : OUT STD_LOGIC;
			valid      : OUT STD_LOGIC;
			data_count : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
		);
	END COMPONENT;

	-- SPI FSM state declarations
	type t_spi_state is (
			-- Enhanced SPI with single MOSI, MISO states
			ST_IDLE_STAND, ST_START_D_STAND, ST_START_S_STAND,
			ST_TX_STAND, ST_WAIT_STAND, ST_RX_STAND, ST_STOP_S_STAND,
			ST_STOP_D_STAND,
			-- Quad I/O SPI with quad DQ3:DQ0 states
			ST_IDLE_QUADIO, ST_START_D_QUADIO, ST_START_S_QUADIO, ST_TX_QUADIO,
			ST_WAIT_QUADIO, ST_RX_QUADIO, ST_STOP_S_QUADIO, ST_STOP_D_QUADIO);

	signal s_spi_pr_state                      : t_spi_state := ST_IDLE_STAND;
	signal s_spi_nx_state                      : t_spi_state := ST_IDLE_STAND;
	signal s_spi_pr_state_delayed1             : t_spi_state := ST_IDLE_STAND;
	signal s_spi_pr_state_delayed2             : t_spi_state := ST_IDLE_STAND;
	signal s_spi_pr_state_delayed3             : t_spi_state := ST_IDLE_STAND;
	attribute fsm_encoding                     : string;
	attribute fsm_encoding of s_spi_pr_state   : signal is "gray";
	attribute fsm_safe_state                   : string;
	attribute fsm_safe_state of s_spi_pr_state : signal is "default_state";

	-- Data start FSM state declarations
	type t_dat_state is (
			ST_WAIT_PULSE, ST_HOLD_PULSE_0, ST_HOLD_PULSE_1, ST_HOLD_PULSE_2,
			ST_HOLD_PULSE_3);
	signal s_dat_pr_state                      : t_dat_state := ST_WAIT_PULSE;
	signal s_dat_nx_state                      : t_dat_state := ST_WAIT_PULSE;
	attribute fsm_encoding of s_dat_pr_state   : signal is "gray";
	attribute fsm_safe_state of s_dat_pr_state : signal is "default_state";

	-- Timer signals and constants
	constant c_t_stand_wait_ss  : natural := 4;
	constant c_t_stand_max_tx   : natural := 2096;
	constant c_t_stand_max_wait : natural := 512;
	constant c_t_stand_max_rx   : natural := 2088;

	constant c_t_quadio_wait_ss  : natural := 16;
	constant c_t_quadio_max_tx   : natural := 2096;
	constant c_t_quadio_max_wait : natural := 512;
	constant c_t_quadio_max_rx   : natural := 2088;

	constant c_tmax : natural := c_t_stand_max_tx - 1;

	signal s_t          : natural range 0 to c_tmax;
	signal s_t_delayed1 : natural range 0 to c_tmax;
	signal s_t_delayed2 : natural range 0 to c_tmax;
	signal s_t_delayed3 : natural range 0 to c_tmax;

	signal s_t_inc : natural range 1 to 4;

	-- SPI 4x and 1x clocking signals and enables
	signal s_spi_ce_4x   : std_logic;
	signal s_spi_clk_1x  : std_logic;
	signal s_spi_rst_1x  : std_logic;
	signal s_spi_clk_ce0 : std_logic;
	signal s_spi_clk_ce1 : std_logic;
	signal s_spi_clk_ce2 : std_logic;
	signal s_spi_clk_ce3 : std_logic;

	-- FSM pulse stretched
	signal s_go_stand  : std_logic;
	signal s_go_quadio : std_logic;

	-- FSM auxiliary registers
	signal s_tx_len_val    : unsigned((parm_tx_len_bits - 1) downto 0);
	signal s_tx_len_aux    : unsigned((parm_tx_len_bits - 1) downto 0);
	signal s_rx_len_val    : unsigned((parm_rx_len_bits - 1) downto 0);
	signal s_rx_len_aux    : unsigned((parm_rx_len_bits - 1) downto 0);
	signal s_wait_cyc_val  : unsigned((parm_wait_cyc_bits - 1) downto 0);
	signal s_wait_cyc_aux  : unsigned((parm_wait_cyc_bits - 1) downto 0);
	signal s_go_stand_val  : std_logic;
	signal s_go_stand_aux  : std_logic;
	signal s_go_quadio_val : std_logic;
	signal s_go_quadio_aux : std_logic;

	-- FSM output status
	signal s_spi_idle : std_logic;

	-- Mapping for FIFO RX
	signal s_data_fifo_rx_in            : std_logic_vector(7 downto 0);
	signal s_data_fifo_rx_out           : std_logic_vector(7 downto 0);
	signal s_data_fifo_rx_re            : std_logic;
	signal s_data_fifo_rx_we            : std_logic;
	signal s_data_fifo_rx_full          : std_logic;
	signal s_data_fifo_rx_empty         : std_logic;
	signal s_data_fifo_rx_valid         : std_logic;
	signal s_data_fifo_rx_valid_stretch : std_logic;
	signal s_data_fifo_rx_count         : std_logic_vector((parm_rx_len_bits - 1) downto 0);

	-- Mapping for FIFO TX
	signal s_data_fifo_tx_in    : std_logic_vector(7 downto 0);
	signal s_data_fifo_tx_out   : std_logic_vector(7 downto 0);
	signal s_data_fifo_tx_re    : std_logic;
	signal s_data_fifo_tx_we    : std_logic;
	signal s_data_fifo_tx_full  : std_logic;
	signal s_data_fifo_tx_empty : std_logic;
	signal s_data_fifo_tx_valid : std_logic;
	signal s_data_fifo_tx_count : std_logic_vector((parm_tx_len_bits - 1) downto 0);

	signal v_phase_counter : natural range 0 to (parm_ext_spi_clk_ratio - 1);

begin
	o_spi_idle <= '1' when ((s_spi_idle = '1') and (s_dat_pr_state = ST_WAIT_PULSE)) else '0';

	-- In this implementation, the 4x SPI clock is operated by a clock enable against
	-- the system clock \ref i_ext_spi_clk_x .
	s_spi_ce_4x <= i_spi_ce_4x;

	-- Mapping of the RX FIFO to external control and reception of datafor
	-- readingoperations
	o_rx_avail        <= (not s_data_fifo_rx_empty) and s_spi_ce_4x;
	o_rx_valid        <= s_data_fifo_rx_valid_stretch and s_spi_ce_4x;
	s_data_fifo_rx_re <= i_rx_dequeue and s_spi_ce_4x;
	o_rx_data         <= s_data_fifo_rx_out;

	u_pulse_stretch_fifo_rx_0 : entity work.pulse_stretcher_synch(moore_fsm_timed)
		generic map(
			par_T_stretch_count => (parm_ext_spi_clk_ratio / 4 - 1)
		)
		port map(
			o_y   => s_data_fifo_rx_valid_stretch,
			i_clk => i_ext_spi_clk_x,
			i_rst => i_srst,
			i_x   => s_data_fifo_rx_valid
		);

	u_fifo_rx_0 : fifo_generator_3
		PORT MAP (
			clk        => i_ext_spi_clk_x,
			srst       => i_srst,
			din        => s_data_fifo_rx_in,
			wr_en      => s_data_fifo_rx_we,
			rd_en      => s_data_fifo_rx_re,
			dout       => s_data_fifo_rx_out,
			full       => s_data_fifo_rx_full,
			empty      => s_data_fifo_rx_empty,
			valid      => s_data_fifo_rx_valid,
			data_count => s_data_fifo_rx_count
		);

	-- Mapping of the TX FIFO to external control and transmission of data for
	-- PAGE PROGRAM operations
	s_data_fifo_tx_in <= i_tx_data;
	s_data_fifo_tx_we <= i_tx_enqueue and s_spi_ce_4x;
	o_tx_ready        <= (not s_data_fifo_tx_full) and s_spi_ce_4x;

	u_fifo_tx_0 : fifo_generator_4
		PORT MAP (
			clk        => i_ext_spi_clk_x,
			srst       => i_srst,
			din        => s_data_fifo_tx_in,
			wr_en      => s_data_fifo_tx_we,
			rd_en      => s_data_fifo_tx_re,
			dout       => s_data_fifo_tx_out,
			full       => s_data_fifo_tx_full,
			empty      => s_data_fifo_tx_empty,
			valid      => s_data_fifo_tx_valid,
			data_count => s_data_fifo_tx_count
		);

	-- spi clock for SCK output, generated clock
	-- requires create_generated_clock constraint in XDC
	u_spi_1x_clock_divider : entity work.clock_divider(rtl)
		generic map(
			par_clk_divisor => parm_ext_spi_clk_ratio
		)
		port map(
			o_clk_div => s_spi_clk_1x,
			o_rst_div => open,
			i_clk_mhz => i_ext_spi_clk_x,
			i_rst_mhz => i_srst
		);

	-- 25% point clock enables for period of 4 times SPI CLK output based on s_spi_ce_4x
	p_phase_4x_ce : process(i_ext_spi_clk_x)
	begin
		if rising_edge(i_ext_spi_clk_x) then
			if (i_srst = '1') then
				v_phase_counter <= 0;
			else
				if (v_phase_counter < parm_ext_spi_clk_ratio - 1) then
					v_phase_counter <= v_phase_counter + 1;
				else
					v_phase_counter <= 0;
				end if;
			end if;
		end if;
	end process p_phase_4x_ce;

	s_spi_clk_ce0 <= '1' when (v_phase_counter = parm_ext_spi_clk_ratio / 4 * 0) and (s_spi_ce_4x = '1') else '0';
	s_spi_clk_ce1 <= '1' when (v_phase_counter = parm_ext_spi_clk_ratio / 4 * 1) and (s_spi_ce_4x = '1') else '0';
	s_spi_clk_ce2 <= '1' when (v_phase_counter = parm_ext_spi_clk_ratio / 4 * 2) and (s_spi_ce_4x = '1') else '0';
	s_spi_clk_ce3 <= '1' when (v_phase_counter = parm_ext_spi_clk_ratio / 4 * 3) and (s_spi_ce_4x = '1') else '0';

	-- Timer 1 (Strategy #1) with modifiable timer increment
	p_timer_1 : process(i_ext_spi_clk_x)
	begin
		if rising_edge(i_ext_spi_clk_x) then
			if (i_srst = '1') then
				s_t          <= 0;
				s_t_delayed1 <= 0;
				s_t_delayed2 <= 0;
				s_t_delayed3 <= 0;
				s_t_inc      <= 1;
			else
				if (i_spi_ce_4x = '1') then
					s_t_delayed3 <= s_t_delayed2;
					s_t_delayed2 <= s_t_delayed1;
					s_t_delayed1 <= s_t;
				end if;

				-- clock enable on falling SPIedge
				-- for timerchange
				if (s_spi_clk_ce2 = '1') then
					if (s_spi_pr_state /= s_spi_nx_state) then
						s_t <= 0;
					elsif (s_t < c_tmax) then
						s_t <= s_t + s_t_inc;
					end if;
				end if;

				if (s_go_stand = '1') then
					s_t_inc <= 1;
				elsif (s_go_quadio = '1') then
					s_t_inc <= 4;
				end if;
			end if;
		end if;
	end process p_timer_1;

	-- FSM for holding control inputs upon system 4x clock cycle pulse on
	-- i_go_stand or i_go_quadio .
	p_dat_fsm_state_aux : process(i_ext_spi_clk_x)
	begin
		if rising_edge(i_ext_spi_clk_x) then
			if (i_srst = '1') then
				s_dat_pr_state <= ST_WAIT_PULSE;

				s_tx_len_aux    <= (others => '0');
				s_rx_len_aux    <= (others => '0');
				s_wait_cyc_aux  <= (others => '0');
				s_go_stand_aux  <= '0';
				s_go_quadio_aux <= '0';

			elsif (s_spi_ce_4x = '1') then
				-- no clock enable as this is a system-side interface
				s_dat_pr_state <= s_dat_nx_state;

				-- auxiliary assignments
				s_tx_len_aux    <= s_tx_len_val;
				s_rx_len_aux    <= s_rx_len_val;
				s_wait_cyc_aux  <= s_wait_cyc_val;
				s_go_stand_aux  <= s_go_stand_val;
				s_go_quadio_aux <= s_go_quadio_val;
			end if;
		end if;
	end process p_dat_fsm_state_aux;

	-- Pass the auxiliary signals that last for a single iteration of allfour
	-- i_spi_ce_4x clock enables on to the \ref p_spi_fsm_comb
	s_go_stand  <= s_go_stand_aux;
	s_go_quadio <= s_go_quadio_aux;

	-- System Data GO data value holder and i_go_stand/i_go_quadio pulse stretcher for all
	-- four clock enables duration of the 4x clock, starting at an clock enable
	-- position. Combinatorial logic paired with the \ref p_dat_fsm_state
	-- assignments.
	p_dat_fsm_comb : process(s_dat_pr_state, i_go_stand, i_go_quadio,
			i_tx_len, i_rx_len, i_wait_cyc, s_tx_len_aux, s_rx_len_aux,
			s_wait_cyc_aux, s_go_stand_aux, s_go_quadio_aux)
	begin
		s_tx_len_val    <= s_tx_len_aux;
		s_rx_len_val    <= s_rx_len_aux;
		s_wait_cyc_val  <= s_wait_cyc_aux;
		s_go_stand_val  <= s_go_stand_aux;
		s_go_quadio_val <= s_go_quadio_aux;

		case (s_dat_pr_state) is
			when ST_HOLD_PULSE_0 =>
				-- Hold the GO signal and auxiliary for this cycle.
				s_dat_nx_state <= ST_HOLD_PULSE_1;

			when ST_HOLD_PULSE_1 =>
				-- Hold the GO signal and auxiliary for this cycle.
				s_dat_nx_state <= ST_HOLD_PULSE_2;

			when ST_HOLD_PULSE_2 =>
				-- Hold the GO signal and auxiliary for this cycle.
				s_dat_nx_state <= ST_HOLD_PULSE_3;

			when ST_HOLD_PULSE_3 =>
				-- Reset the GO signal and and hold the auxiliary for this cycle.
				s_go_stand_val  <= '0';
				s_go_quadio_val <= '0';
				s_dat_nx_state  <= ST_WAIT_PULSE;

			when others => -- ST_WAIT_PULSE
				           -- If GO signal is 1, assign it and the auxiliary on the
				           -- transition to the first HOLD state. Otherwise, hold
				           -- the values already assigned.
				if ((i_go_stand = '1') or (i_go_quadio = '1')) then
					s_go_stand_val  <= i_go_stand;
					s_go_quadio_val <= i_go_quadio;
					s_tx_len_val    <= unsigned(i_tx_len);
					s_rx_len_val    <= unsigned(i_rx_len);
					s_wait_cyc_val  <= unsigned(i_wait_cyc);
					s_dat_nx_state  <= ST_HOLD_PULSE_0;
				else
					s_dat_nx_state <= ST_WAIT_PULSE;
				end if;
		end case;
	end process p_dat_fsm_comb;

	-- SPI bus control state machine assignments for falling edge of 1x clock
	-- assignment of state value, plus delayed state value for the RX capture
	-- on the SPI rising edge of 1x clock in a different process.
	p_spi_fsm_state : process(i_ext_spi_clk_x)
	begin
		if rising_edge(i_ext_spi_clk_x) then
			if (i_srst = '1') then
				s_spi_pr_state_delayed3 <= ST_IDLE_STAND;
				s_spi_pr_state_delayed2 <= ST_IDLE_STAND;
				s_spi_pr_state_delayed1 <= ST_IDLE_STAND;
				s_spi_pr_state          <= ST_IDLE_STAND;

			else
				if (s_spi_ce_4x = '1') then
					-- the delayed state value allows for registration of TX clock
					-- and double registration of RX value to capture after the
					-- registration of outputs and synchronization of inputs
					s_spi_pr_state_delayed3 <= s_spi_pr_state_delayed2;
					s_spi_pr_state_delayed2 <= s_spi_pr_state_delayed1;
					s_spi_pr_state_delayed1 <= s_spi_pr_state;
				end if;

				if (s_spi_clk_ce2 = '1') then -- clock enable on falling SPI edge
					                          -- for state change
					s_spi_pr_state <= s_spi_nx_state;
				end if;
			end if;
		end if;
	end process p_spi_fsm_state;

	-- SPI bus control state machine assignments for combinatorial assignmentto
	-- SPI bus outputs, timing of slave select, transmission of TXdata,
	-- holding for wait cycles, and timing for RX data where RX data iscaptured
	-- in a different synchronous state machine delayed from the state ofthis
	-- machine.
	p_spi_fsm_comb : process(s_spi_pr_state, s_spi_clk_1x, s_go_stand, s_go_quadio,
			s_tx_len_aux, s_rx_len_aux,
			s_wait_cyc_aux, s_t, s_t_inc,
			s_data_fifo_tx_empty, s_spi_clk_ce2, s_spi_clk_ce3,
			s_data_fifo_rx_full,
			s_data_fifo_tx_out,
			eio_mosi_dq0_i, eio_miso_dq1_i, eio_wrpn_dq2_i, eio_hldn_dq3_i,
			i_tx_len, i_rx_len, i_wait_cyc)
	begin
		-- default to not idle indication
		s_spi_idle <= '0';
		-- default to running the SPI clock
		-- the 5 other pins are controlled explicitly within each state
		eio_sck_o <= s_spi_clk_1x;
		eio_sck_t <= '0';
		-- default to holding the value of the auxiliary registers
		s_data_fifo_tx_re <= '0';

		case (s_spi_pr_state) is
			when ST_START_D_STAND =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- no chip select
				eio_ssn_o <= '1';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- wait for time to hold chip select value
				if (s_t = c_t_stand_wait_ss - s_t_inc) then
					s_spi_nx_state <= ST_START_S_STAND;
				else
					s_spi_nx_state <= ST_START_D_STAND;
				end if;

			when ST_START_S_STAND =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- wait for time to hold chip select value
				if (s_t = c_t_stand_wait_ss - s_t_inc) then
					if (s_data_fifo_tx_empty = '0') then
						-- Fetch the first byte from the TX FIFO
						s_data_fifo_tx_re <= s_spi_clk_ce3;
					end if;

					s_spi_nx_state <= ST_TX_STAND;
				else
					s_spi_nx_state <= ST_START_S_STAND;
				end if;

			when ST_TX_STAND =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';

				-- output currently dequeued byte
				if (s_t < 8 * unsigned(s_tx_len_aux)) then
					-- output current byte from fifo MSbit first
					eio_mosi_dq0_o <= s_data_fifo_tx_out(7 - (s_t mod 8));
				else
					eio_mosi_dq0_o <= '0';
				end if;

				eio_mosi_dq0_t <= '0';
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- If every bit from the FIFO according to i_tx_len value captured
				-- in s_tx_len_aux, then move to either WAIT for RX or STOP.
				if (s_t = (8 * unsigned(s_tx_len_aux)) - s_t_inc) then
					if (unsigned(s_rx_len_aux) > 0) then
						if (unsigned(s_wait_cyc_aux) > 0) then
							s_spi_nx_state <= ST_WAIT_STAND;
						else
							s_spi_nx_state <= ST_RX_STAND;
						end if;
					else
						s_spi_nx_state <= ST_STOP_S_STAND;
					end if;
				else
					-- only if on last bit, dequeue another byte
					if (s_t mod 8 = 7) then
						-- only if TX FIFO is not empty, dequeue another byte
						if (s_data_fifo_tx_empty = '0') then
							-- pass a clock enable
							-- so that the Read Enable only occurs
							-- for one clock cycle for the 4x SPI clock
							s_data_fifo_tx_re <= s_spi_clk_ce2;
						end if;
					end if;

					s_spi_nx_state <= ST_TX_STAND;
				end if;

			when ST_WAIT_STAND =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				if (s_t = unsigned(s_wait_cyc_aux) - s_t_inc) then
					s_spi_nx_state <= ST_RX_STAND;
				else
					s_spi_nx_state <= ST_WAIT_STAND;
				end if;

			when ST_RX_STAND =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- If every bit from the FIFO according to i_rx_len value captured
				-- in s_rx_len_aux, then move to STOP.
				if (s_t = (8 * unsigned(s_rx_len_aux)) - s_t_inc) then
					s_spi_nx_state <= ST_STOP_S_STAND;
				else
					s_spi_nx_state <= ST_RX_STAND;
				end if;

			when ST_STOP_S_STAND =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- wait for time to hold chip select value
				if (s_t = c_t_stand_wait_ss - s_t_inc) then
					s_spi_nx_state <= ST_STOP_D_STAND;
				else
					s_spi_nx_state <= ST_STOP_S_STAND;
				end if;

			when ST_STOP_D_STAND =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- assert chip select
				eio_ssn_o <= '1';
				eio_ssn_t <= '0';
				-- zero MOSI
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				-- High-Z MISO
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- Write Protect not asserted
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				-- Hold not asserted
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				-- wait for time to hold chip select value
				if (s_t = c_t_stand_wait_ss - s_t_inc) then
					s_spi_nx_state <= ST_IDLE_STAND;
				else
					s_spi_nx_state <= ST_STOP_D_STAND;
				end if;

			when ST_START_D_QUADIO =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- no chip select
				eio_ssn_o <= '1';
				eio_ssn_t <= '0';
				-- High-Z DQ0
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				-- wait for time to hold chip select value
				if (s_t = c_t_quadio_wait_ss - 4) then
					s_spi_nx_state <= ST_START_S_QUADIO;
				else
					s_spi_nx_state <= ST_START_D_QUADIO;
				end if;

			when ST_START_S_QUADIO =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- High-Z DQ0
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				-- wait for time to hold chip select value
				if (s_t = c_t_quadio_wait_ss - s_t_inc) then
					if (s_data_fifo_tx_empty = '0') then
						-- Fetch the first byte from the TX FIFO
						s_data_fifo_tx_re <= s_spi_clk_ce2;
					end if;

					s_spi_nx_state <= ST_TX_QUADIO;
				else
					s_spi_nx_state <= ST_START_S_QUADIO;
				end if;

			when ST_TX_QUADIO =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';

				-- output currently dequeued byte
				if (s_t < 8 * unsigned(s_tx_len_aux)) then
					-- output current byte nibble from fifo MSbit first
					eio_hldn_dq3_o <= s_data_fifo_tx_out(7 - (s_t mod 8));
					eio_wrpn_dq2_o <= s_data_fifo_tx_out(6 - (s_t mod 8));
					eio_miso_dq1_o <= s_data_fifo_tx_out(5 - (s_t mod 8));
					eio_mosi_dq0_o <= s_data_fifo_tx_out(4 - (s_t mod 8));
				else
					eio_hldn_dq3_o <= '0';
					eio_wrpn_dq2_o <= '0';
					eio_miso_dq1_o <= '0';
					eio_mosi_dq0_o <= '0';
				end if;

				-- Keep DQ3:DQ0 as not High-Z, but direct output instead
				eio_mosi_dq0_t <= '0';
				eio_miso_dq1_t <= '0';
				eio_wrpn_dq2_t <= '0';
				eio_hldn_dq3_t <= '0';

				-- If every bit from the FIFO according to i_tx_len value captured
				-- in s_tx_len_aux, then move to either WAIT for RX or STOP.
				if (s_t = (8 * unsigned(s_tx_len_aux)) - s_t_inc) then
					if (unsigned(s_rx_len_aux) > 0) then
						if (unsigned(s_wait_cyc_aux) > 0) then
							s_spi_nx_state <= ST_WAIT_QUADIO;
						else
							s_spi_nx_state <= ST_RX_QUADIO;
						end if;
					else
						s_spi_nx_state <= ST_STOP_S_QUADIO;
					end if;
				else
					-- only if on last bit, dequeue another byte
					if (s_t mod 8 = 4) then
						-- only if TX FIFO is not empty, dequeue another byte
						if (s_data_fifo_tx_empty = '0') then
							-- pass a clock enable
							-- so that the Read Enable only occurs
							-- for one clock cycle for the 4x SPI clock
							s_data_fifo_tx_re <= s_spi_clk_ce2;
						end if;
					end if;

					s_spi_nx_state <= ST_TX_QUADIO;
				end if;

			when ST_WAIT_QUADIO =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- High-Z DQ0
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				if (s_t = (s_t_inc * unsigned(s_wait_cyc_aux)) -
						s_t_inc) then
					s_spi_nx_state <= ST_RX_QUADIO;
				else
					s_spi_nx_state <= ST_WAIT_QUADIO;
				end if;

			when ST_RX_QUADIO =>
				-- run clock
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- High-Z DQ0 to input from the peripheral chip
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				-- If every bit from the FIFO according to i_rx_len value captured
				-- in s_rx_len_aux, then move to STOP.
				if (s_t = (8 * unsigned(s_rx_len_aux)) - s_t_inc) then
					s_spi_nx_state <= ST_STOP_S_QUADIO;
				else
					s_spi_nx_state <= ST_RX_QUADIO;
				end if;

			when ST_STOP_S_QUADIO =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- assert chip select
				eio_ssn_o <= '0';
				eio_ssn_t <= '0';
				-- High-Z DQ0
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				-- wait for time to hold chip select value
				if (s_t = c_t_quadio_wait_ss - s_t_inc) then
					s_spi_nx_state <= ST_STOP_D_QUADIO;
				else
					s_spi_nx_state <= ST_STOP_S_QUADIO;
				end if;

			when ST_STOP_D_QUADIO =>
				-- halt clock
				eio_sck_o <= '0';
				eio_sck_t <= '0';
				-- deassert chip select
				eio_ssn_o <= '1';
				eio_ssn_t <= '0';
				-- High-Z DQ0
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				-- High-Z DQ1
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				-- High-Z DQ2
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				-- High-Z DQ3
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				-- wait for time to hold chip select value
				if (s_t = c_t_quadio_wait_ss - s_t_inc) then
					s_spi_nx_state <= ST_IDLE_QUADIO;
				else
					s_spi_nx_state <= ST_STOP_D_QUADIO;
				end if;

			when ST_IDLE_QUADIO =>
				s_spi_idle     <= '1';
				eio_sck_o      <= '0';
				eio_sck_t      <= '0';
				eio_ssn_o      <= '1';
				eio_ssn_t      <= '0';
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '1';
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '1';
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '1';

				if (s_go_stand = '1') then
					s_spi_nx_state <= ST_START_D_STAND;

				elsif (s_go_quadio = '1') then
					s_spi_nx_state <= ST_START_D_QUADIO;

				else
					s_spi_nx_state <= ST_IDLE_QUADIO;
				end if;

			when others => -- ST_IDLE_STAND
				s_spi_idle     <= '1';
				eio_sck_o      <= '0';
				eio_sck_t      <= '0';
				eio_ssn_o      <= '1';
				eio_ssn_t      <= '0';
				eio_mosi_dq0_o <= '0';
				eio_mosi_dq0_t <= '0';
				eio_miso_dq1_o <= '0';
				eio_miso_dq1_t <= '1';
				eio_wrpn_dq2_o <= '1';
				eio_wrpn_dq2_t <= '0';
				eio_hldn_dq3_o <= '1';
				eio_hldn_dq3_t <= '0';

				if (s_go_stand = '1') then
					s_spi_nx_state <= ST_START_D_STAND;

				elsif (s_go_quadio = '1') then
					s_spi_nx_state <= ST_START_D_QUADIO;

				else
					s_spi_nx_state <= ST_IDLE_STAND;
				end if;
		end case;

	end process p_spi_fsm_comb;

	-- capture the RX inputs into the RX fifo
	-- note that the RX inputs are delayed by 3 clk_4x clock cycles
	-- before the delay, the falling edge would occur at the capture of
	-- clock enable 0; but with the delay of registering output and double
	-- registering input, the FSM state is delayed by 3 clock cycles for
	-- RX only and the clock enable to process on the effective falling edge of
	-- the bus SCK as perceived from propagation out and back in, is 3 clock
	-- cycles, thus CE 3 instead of CE 0.
	p_spi_fsm_inputs : process(i_ext_spi_clk_x)
	begin
		if rising_edge(i_ext_spi_clk_x) then
			if (i_srst = '1') then
				s_data_fifo_rx_we             <= '0';
				s_data_fifo_rx_in(7 downto 0) <= x"00";
			else
				s_data_fifo_rx_we <= '0';

				if (s_spi_clk_ce3 = '1') then
					if (s_spi_pr_state_delayed3 = ST_RX_STAND) then
						-- input current byte to enqueue

						if (s_t_delayed3 < 8 * unsigned(s_rx_len_aux)) then
							-- input current byte to RX fifo MSbit first
							-- FIXME: change this to a shift register instead of
							-- multiplexer for a more efficient implementation.
							s_data_fifo_rx_in(7 - (s_t_delayed3 mod 8)) <= eio_miso_dq1_i;
						else
							s_data_fifo_rx_in(7 downto 0) <= x"00";
						end if;

						-- only if on last bit, enqueue another byte
						if (s_t_delayed3 mod 8 = 7) then
							-- only if RX FIFO is not full, enqueue another byte
							if (s_data_fifo_rx_full = '0') then
								-- pass a clock enable
								-- so that the Read Enable only occurs
								-- for one clock cycle for the 4x SPI clock
								s_data_fifo_rx_we <= '1';
							end if;
						end if;

					elsif (s_spi_pr_state_delayed3 = ST_RX_QUADIO) then
						-- input current byte to enqueue

						if (s_t_delayed3 < 8 * unsigned(s_rx_len_aux)) then
							-- input current byte to RX fifo MSbit first
							-- FIXME: change this to a shift register instead of
							-- multiplexer for a more efficient implementation.
							s_data_fifo_rx_in(7 - (s_t_delayed3 mod 8)) <= eio_hldn_dq3_i;
							s_data_fifo_rx_in(6 - (s_t_delayed3 mod 8)) <= eio_wrpn_dq2_i;
							s_data_fifo_rx_in(5 - (s_t_delayed3 mod 8)) <= eio_miso_dq1_i;
							s_data_fifo_rx_in(4 - (s_t_delayed3 mod 8)) <= eio_mosi_dq0_i;
						else
							s_data_fifo_rx_in(7 downto 0) <= x"00";
						end if;

						-- only if on last bit, enqueue another byte
						if (s_t_delayed3 mod 8 = 4) then
							-- only if RX FIFO is not full, enqueue another byte
							if (s_data_fifo_rx_full = '0') then
								-- pass a clock enable
								-- so that the Read Enable only occurs
								-- for one clock cycle for the 4x SPI clock
								s_data_fifo_rx_we <= '1';
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process p_spi_fsm_inputs;

end architecture spi_hybrid_fsm;
--------------------------------------------------------------------------------
