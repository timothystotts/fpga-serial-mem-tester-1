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
-- \file fpga_serial_mem_tester.vhdl
--
-- \brief A FPGA top-level design with the PMOD SF3 custom driver.
-- This design erases a subsector, programs the subsector, and then byte
-- compares the contents of the subsector. The data is displayed on a PMOD
-- CLS 16x2 dot-matrix LCD.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lcd_text_functions_pkg.all;
use work.led_pwm_driver_pkg.all;
--------------------------------------------------------------------------------
entity fpga_serial_mem_tester is
	generic(
		parm_fast_simulation : integer := 0
	);
	port(
		-- Board clock
		CLK100MHZ : in std_logic;
		i_resetn  : in std_logic;
		-- PMOD SF3 Quad SPI
		eo_pmod_sf3_sck       : out   std_logic;
		eo_pmod_sf3_ssn       : out   std_logic;
		eio_pmod_sf3_mosi_dq0 : inout std_logic;
		eio_pmod_sf3_miso_dq1 : inout std_logic;
		eio_pmod_sf3_wrpn_dq2 : inout std_logic;
		eio_pmod_sf3_hldn_dq3 : inout std_logic;
		-- blue LEDs of the multicolor
		eo_led0_b : out std_logic;
		eo_led1_b : out std_logic;
		eo_led2_b : out std_logic;
		eo_led3_b : out std_logic;
		-- red LEDs of the multicolor
		eo_led0_r : out std_logic;
		eo_led1_r : out std_logic;
		eo_led2_r : out std_logic;
		eo_led3_r : out std_logic;
		-- green LEDs of the multicolor
		eo_led0_g : out std_logic;
		eo_led1_g : out std_logic;
		eo_led2_g : out std_logic;
		eo_led3_g : out std_logic;
		-- green LEDs of the regular LEDs
		eo_led4 : out std_logic;
		eo_led5 : out std_logic;
		eo_led6 : out std_logic;
		eo_led7 : out std_logic;
		-- four switches
		ei_sw0 : in std_logic;
		ei_sw1 : in std_logic;
		ei_sw2 : in std_logic;
		ei_sw3 : in std_logic;
		-- four buttons
		ei_bt0 : in std_logic;
		ei_bt1 : in std_logic;
		ei_bt2 : in std_logic;
		ei_bt3 : in std_logic;
		-- PMOD CLS SPI bus 4-wire
		eo_pmod_cls_ssn : out std_logic;
		eo_pmod_cls_sck : out std_logic;
		eo_pmod_cls_dq0 : out std_logic;
		ei_pmod_cls_dq1 : in  std_logic;
		-- Arty A7-100T UART TX and RX signals
		eo_uart_tx : out std_logic;
		ei_uart_rx : in  std_logic
	);
end entity fpga_serial_mem_tester;
--------------------------------------------------------------------------------
architecture rtl of fpga_serial_mem_tester is

	-- Frequency of the clk_out1 clock output
	constant c_FCLK : natural := 40_000_000;

	-- Clocking Wizard IP module
	-- (provides MMCM functions)
	component clk_wiz_0
		port
		(    -- Clock in ports
			 -- Clock out ports
			clk_out1 : out std_logic;
			clk_out2 : out std_logic;
			-- Status and control signals
			resetn  : in  std_logic;
			locked  : out std_logic;
			clk_in1 : in  std_logic
		);
	end component;

	-- Processing System Reset IP module
	-- (for 20 MHz clock for general purpose)
	-- (provides synchronous reset functions)
	COMPONENT proc_sys_reset_0
		PORT (
			slowest_sync_clk     : IN  STD_LOGIC;
			ext_reset_in         : IN  STD_LOGIC;
			aux_reset_in         : IN  STD_LOGIC;
			mb_debug_sys_rst     : IN  STD_LOGIC;
			dcm_locked           : IN  STD_LOGIC;
			mb_reset             : OUT STD_LOGIC;
			bus_struct_reset     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			peripheral_reset     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			interconnect_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			peripheral_aresetn   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
		);
	END COMPONENT;

	-- Processing System Reset IP module
	-- (for 7.37 MHz clock for TX ONLY UART function)
	-- (provides synchronous reset functions)
	COMPONENT proc_sys_reset_1
		PORT (
			slowest_sync_clk     : IN  STD_LOGIC;
			ext_reset_in         : IN  STD_LOGIC;
			aux_reset_in         : IN  STD_LOGIC;
			mb_debug_sys_rst     : IN  STD_LOGIC;
			dcm_locked           : IN  STD_LOGIC;
			mb_reset             : OUT STD_LOGIC;
			bus_struct_reset     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			peripheral_reset     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			interconnect_aresetn : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
			peripheral_aresetn   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
		);
	END COMPONENT;

	-- MMCM and Processor System Reset signals for PLL clock generation from the
	-- Clocking Wizard and Synchronous Reset generation from the Processor System
	-- Reset module.
	signal s_mmcm_locked       : std_logic;
	signal s_clk_40mhz         : std_logic;
	signal s_rst_40mhz         : std_logic;
	signal s_clk_7_37mhz       : std_logic;
	signal s_rst_7_37mhz       : std_logic;
	signal s_ce_2_5mhz         : std_logic;
	signal s_sf3_ce_div        : std_logic;
	signal sc_aux_reset_in     : std_logic;
	signal sc_mb_debug_sys_rst : std_logic;
	signal s_20_periph_reset   : std_logic_vector(0 downto 0);
	signal s_737_periph_reset  : std_logic_vector(0 downto 0);

	-- Definitions of the Quad SPI driver to pass to the SF3 driver
	constant c_quad_spi_tx_fifo_count_bits : natural := 9;
	constant c_quad_spi_rx_fifo_count_bits : natural := 9;
	constant c_quad_spi_wait_count_bits    : natural := 9;

	-- Definitions of the Standard SPI driver to pass to the CLS driver
	constant c_stand_spi_tx_fifo_count_bits : natural := 5;
	constant c_stand_spi_rx_fifo_count_bits : natural := 5;
	constant c_stand_spi_wait_count_bits    : natural := 2;

	-- SPI signals to external tri-state
	signal sio_sf3_sck_o      : std_logic;
	signal sio_sf3_sck_t      : std_logic;
	signal sio_sf3_ssn_o      : std_logic;
	signal sio_sf3_ssn_t      : std_logic;
	signal sio_sf3_mosi_dq0_o : std_logic;
	signal sio_sf3_mosi_dq0_i : std_logic;
	signal sio_sf3_mosi_dq0_t : std_logic;
	signal sio_sf3_miso_dq1_o : std_logic;
	signal sio_sf3_miso_dq1_i : std_logic;
	signal sio_sf3_miso_dq1_t : std_logic;
	signal sio_sf3_wrpn_dq2_o : std_logic;
	signal sio_sf3_wrpn_dq2_i : std_logic;
	signal sio_sf3_wrpn_dq2_t : std_logic;
	signal sio_sf3_hldn_dq3_o : std_logic;
	signal sio_sf3_hldn_dq3_i : std_logic;
	signal sio_sf3_hldn_dq3_t : std_logic;

	signal s_sf3_command_ready       : std_logic;
	signal s_sf3_address_of_cmd      : std_logic_vector(31 downto 0);
	signal s_sf3_cmd_erase_subsector : std_logic;
	signal s_sf3_cmd_page_program    : std_logic;
	signal s_sf3_cmd_random_read     : std_logic;
	signal s_sf3_len_random_read     : std_logic_vector(8 downto 0);
	signal s_sf3_wr_data_stream      : std_logic_vector(7 downto 0);
	signal s_sf3_wr_data_valid       : std_logic;
	signal s_sf3_wr_data_ready       : std_logic;
	signal s_sf3_rd_data_stream      : std_logic_vector(7 downto 0);
	signal s_sf3_rd_data_valid       : std_logic;
	signal s_sf3_reg_status          : std_logic_vector(7 downto 0);
	signal s_sf3_reg_flag            : std_logic_vector(7 downto 0);

	-- Display update FSM state declarations
	type t_cls_update_state is (ST_CLS_IDLE, ST_CLS_CLEAR, ST_CLS_LINE1, ST_CLS_LINE2);

	signal s_cls_upd_pr_state : t_cls_update_state;
	signal s_cls_upd_nx_state : t_cls_update_state;

	-- Timer steps for the continuous refresh of the PMOD CLS display:
	-- Wait 0.2 seconds
	-- Clear Display
	-- Wait 1.0 milliseconds
	-- Write Line 1
	-- Wait 1.0 milliseconds
	-- Write Line 2
	-- Repeat the above.
	constant c_cls_i_subsecond_fast : natural := (2500000 / 100 - 1);
	constant c_cls_i_subsecond      : natural := (2500000 / 5 - 1);
	constant c_cls_i_one_ms         : natural := 2500 - 1;
	constant c_cls_i_step           : natural := 4 - 1;
	constant c_cls_i_max            : natural := c_cls_i_subsecond;

	signal s_cls_i : natural range 0 to c_cls_i_max;

	-- Signals for controlling the PMOD CLS custom driver.
	signal s_cls_command_ready             : std_logic;
	signal s_cls_sf3_command_ready         : std_logic;
	signal s_cls_wr_clear_display          : std_logic;
	signal s_cls_wr_text_line1             : std_logic;
	signal s_cls_wr_text_line2             : std_logic;
	signal s_cls_txt_ascii_pattern_1char   : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_address_8char   : std_logic_vector((8*8-1) downto 0);
	signal s_cls_txt_ascii_sf3mode_3char   : std_logic_vector((3*8-1) downto 0);
	signal s_cls_txt_ascii_errcntdec_8char : std_logic_vector(8*8-1 downto 0);
	signal s_cls_txt_ascii_errcntdec_char0 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char1 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char2 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char3 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char4 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char5 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char6 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_errcntdec_char7 : std_logic_vector(7 downto 0);
	signal s_cls_txt_ascii_line1           : std_logic_vector((16*8-1) downto 0);
	signal s_cls_txt_ascii_line2           : std_logic_vector((16*8-1) downto 0);

	-- UART TX update FSM state declarations
	type t_uarttx_feed_state is (ST_UARTFEED_IDLE, ST_UARTFEED_DATA, ST_UARTFEED_WAIT);

	signal s_uartfeed_pr_state : t_uarttx_feed_state;
	signal s_uartfeed_nx_state : t_uarttx_feed_state;

	constant c_uart_k_preset : natural := 34;

	-- UART TX signals for UART TX update FSM
	signal s_uart_dat_ascii_line : std_logic_vector((35*8-1) downto 0);
	signal s_uart_tx_go          : std_logic;
	signal s_uart_txdata         : std_logic_vector(7 downto 0);
	signal s_uart_txvalid        : std_logic;
	signal s_uart_txready        : std_logic;
	signal s_uart_k_val          : natural range 0 to 63;
	signal s_uart_k_aux          : natural range 0 to 63;

	-- Signals for inferring tri-state buffer for CLS SPI bus outputs.
	signal so_pmod_cls_sck_o  : std_logic;
	signal so_pmod_cls_sck_t  : std_logic;
	signal so_pmod_cls_ssn_o  : std_logic;
	signal so_pmod_cls_ssn_t  : std_logic;
	signal so_pmod_cls_mosi_o : std_logic;
	signal so_pmod_cls_mosi_t : std_logic;

	-- button inputs debounced
	signal si_switches : std_logic_vector(3 downto 0);
	signal s_sw_deb    : std_logic_vector(3 downto 0);

	-- button inputs debounced
	signal si_buttons : std_logic_vector(3 downto 0);
	signal s_btns_deb : std_logic_vector(3 downto 0);

	-- system control of N25Q state machine
	--constant c_max_possible_byte_count  : natural := 67_108_864; -- 512 Mbit
	constant c_max_possible_byte_count  : natural := 33_554_432; -- 256 Mbit
	constant c_total_iteration_count    : natural := 32;
	constant c_per_iteration_byte_count : natural :=
		c_max_possible_byte_count / c_total_iteration_count;
	constant c_last_starting_byte_addr : natural :=
		c_per_iteration_byte_count * (c_total_iteration_count - 1);

	type t_tester_state is (ST_WAIT_BUTTON_DEP, ST_WAIT_BUTTON0_REL,
			ST_WAIT_BUTTON1_REL, ST_WAIT_BUTTON2_REL, ST_WAIT_BUTTON3_REL,
			ST_SET_PATTERN_A, ST_SET_PATTERN_B, ST_SET_PATTERN_C, ST_SET_PATTERN_D,
			ST_SET_START_ADDR_A, ST_SET_START_WAIT_A,
			ST_SET_START_ADDR_B, ST_SET_START_WAIT_B,
			ST_SET_START_ADDR_C, ST_SET_START_WAIT_C,
			ST_SET_START_ADDR_D, ST_SET_START_WAIT_D,
			ST_CMD_ERASE_START, ST_CMD_ERASE_WAIT, ST_CMD_ERASE_NEXT,
			ST_CMD_ERASE_DONE, ST_CMD_PAGE_START, ST_CMD_PAGE_BYTE, ST_CMD_PAGE_WAIT,
			ST_CMD_PAGE_NEXT, ST_CMD_PAGE_DONE, ST_CMD_READ_START, ST_CMD_READ_BYTE,
			ST_CMD_READ_WAIT, ST_CMD_READ_NEXT, ST_CMD_READ_DONE, ST_DISPLAY_FINAL
		);

	constant c_sf3_subsector_addr_incr : natural := 4096;
	constant c_sf3_page_addr_incr      : natural := 256;

	constant c_tester_subsector_cnt_per_iter : natural := 8192 / c_total_iteration_count;
	constant c_tester_page_cnt_per_iter      : natural := 131072 / c_total_iteration_count;

	constant c_tester_pattern_startval_a : unsigned(7 downto 0) := x"00";
	constant c_tester_patterh_incrval_a  : unsigned(7 downto 0) := x"01";

	constant c_tester_pattern_startval_b : unsigned(7 downto 0) := x"08";
	constant c_tester_patterh_incrval_b  : unsigned(7 downto 0) := x"07";

	constant c_tester_pattern_startval_c : unsigned(7 downto 0) := x"10";
	constant c_tester_patterh_incrval_c  : unsigned(7 downto 0) := x"0F";

	constant c_tester_pattern_startval_d : unsigned(7 downto 0) := x"18";
	constant c_tester_patterh_incrval_d  : unsigned(7 downto 0) := x"17";

	constant c_sf3_tester_ce_div_ratio : natural := 2;
	
	function fn_set_t_max(fclk : natural; div_ratio : natural; fast_sim : integer)
		return natural is
	begin
		if (fast_sim = 0) then
			return fclk / div_ratio * 3 - 1;
		else
			return fclk / div_ratio * 3 / 1000 - 1;
		end if;
	end function fn_set_t_max;

	-- Maximum count is three seconds c_FCLK / c_sf3_tester_ce_div_ratio * 3 - 1;
	constant c_t_max : natural := fn_set_t_max(c_FCLK, c_sf3_tester_ce_div_ratio, parm_fast_simulation);

	signal s_t : natural range 0 to c_t_max;

	signal s_tester_pr_state       : t_tester_state;
	signal s_tester_nx_state       : t_tester_state;
	signal s_sf3_dat_wr_cntidx_val : natural range 0 to 255;
	signal s_sf3_dat_wr_cntidx_aux : natural range 0 to 255;
	signal s_sf3_dat_rd_cntidx_val : natural range 0 to 255;
	signal s_sf3_dat_rd_cntidx_aux : natural range 0 to 255;
	signal s_sf3_test_pass_val     : std_logic;
	signal s_sf3_test_pass_aux     : std_logic;
	signal s_sf3_test_done_val     : std_logic;
	signal s_sf3_test_done_aux     : std_logic;
	signal s_sf3_err_count_val     : natural range 0 to c_max_possible_byte_count;
	signal s_sf3_err_count_aux     : natural range 0 to c_max_possible_byte_count;

	signal s_sf3_pattern_start_val : std_logic_vector(7 downto 0);
	signal s_sf3_pattern_start_aux : std_logic_vector(7 downto 0);
	signal s_sf3_pattern_incr_val  : std_logic_vector(7 downto 0);
	signal s_sf3_pattern_incr_aux  : std_logic_vector(7 downto 0);
	signal s_sf3_pattern_track_val : std_logic_vector(7 downto 0);
	signal s_sf3_pattern_track_aux : std_logic_vector(7 downto 0);
	signal s_sf3_addr_start_val    : std_logic_vector(31 downto 0);
	signal s_sf3_addr_start_aux    : std_logic_vector(31 downto 0);
	signal s_sf3_start_at_zero_val : std_logic;
	signal s_sf3_start_at_zero_aux : std_logic;
	signal s_sf3_i_val             : natural range 0 to c_tester_page_cnt_per_iter;
	signal s_sf3_i_aux             : natural range 0 to c_tester_page_cnt_per_iter;

	signal s_sf3_err_count_divide7 : natural range 0 to 9;
	signal s_sf3_err_count_divide6 : natural range 0 to 9;
	signal s_sf3_err_count_divide5 : natural range 0 to 9;
	signal s_sf3_err_count_divide4 : natural range 0 to 9;
	signal s_sf3_err_count_divide3 : natural range 0 to 9;
	signal s_sf3_err_count_divide2 : natural range 0 to 9;
	signal s_sf3_err_count_divide1 : natural range 0 to 9;
	signal s_sf3_err_count_divide0 : natural range 0 to 9;
	signal s_sf3_err_count_digit7  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit6  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit5  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit4  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit3  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit2  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit1  : std_logic_vector(3 downto 0);
	signal s_sf3_err_count_digit0  : std_logic_vector(3 downto 0);

	-- LED color palletes
	signal s_color_led_red_value   : t_led_color_values((4 - 1) downto 0);
	signal s_color_led_green_value : t_led_color_values((4 - 1) downto 0);
	signal s_color_led_blue_value  : t_led_color_values((4 - 1) downto 0);
	signal s_basic_led_lumin_value : t_led_color_values((4 - 1) downto 0);

begin
	-- Clocking Wizard module with MMCM. Two clocks are generated from the 100 MHz
	-- input: 20 MHz to operate the SF3 and CLS, and 7.37 MHz to operate the TX UART.
	u_clk_wiz_0 : clk_wiz_0
		port map (
			-- Clock out ports  
			clk_out1 => s_clk_40mhz,
			clk_out2 => s_clk_7_37mhz,
			-- Status and control signals                
			resetn => i_resetn,
			locked => s_mmcm_locked,
			-- Clock in ports
			clk_in1 => CLK100MHZ
		);

	-- Wiring between the Clocking Wizard and the Processor System Reset being used
	-- to provide extended synchronous reset to the custom FPGA design.
	sc_aux_reset_in     <= '0';
	sc_mb_debug_sys_rst <= '0';
	s_rst_7_37mhz       <= s_737_periph_reset(0);
	s_rst_40mhz         <= s_20_periph_reset(0);

	-- Process System Reset module for 20 MHz clock.
	u_proc_sys_reset_0 : proc_sys_reset_0
		PORT MAP (
			slowest_sync_clk     => s_clk_40mhz,
			ext_reset_in         => i_resetn,
			aux_reset_in         => sc_aux_reset_in,
			mb_debug_sys_rst     => sc_mb_debug_sys_rst,
			dcm_locked           => s_mmcm_locked,
			mb_reset             => open,
			bus_struct_reset     => open,
			peripheral_reset     => s_20_periph_reset,
			interconnect_aresetn => open,
			peripheral_aresetn   => open
		);

	-- Process System Reset module for 7.37 MHz clock.
	u_proc_sys_reset_1 : proc_sys_reset_1
		port map (
			slowest_sync_clk     => s_clk_7_37mhz,
			ext_reset_in         => i_resetn,
			aux_reset_in         => sc_aux_reset_in,
			mb_debug_sys_rst     => sc_mb_debug_sys_rst,
			dcm_locked           => s_mmcm_locked,
			mb_reset             => open,
			bus_struct_reset     => open,
			peripheral_reset     => s_737_periph_reset,
			interconnect_aresetn => open,
			peripheral_aresetn   => open
		);

	-- Color and Basic LED operation by 8-bit scalar per filament
	u_led_pwm_driver : entity work.led_pwm_driver(rtl)
		generic map (
			parm_color_led_count         => 4,
			parm_basic_led_count         => 4,
			parm_FCLK                    => c_FCLK,
			parm_pwm_period_milliseconds => 10
		)
		port map (
			i_clk                   => s_clk_40mhz,
			i_srst                  => s_rst_40mhz,
			i_color_led_red_value   => s_color_led_red_value,
			i_color_led_green_value => s_color_led_green_value,
			i_color_led_blue_value  => s_color_led_blue_value,
			i_basic_led_lumin_value => s_basic_led_lumin_value,
			eo_color_leds_r(3)      => eo_led3_r,
			eo_color_leds_r(2)      => eo_led2_r,
			eo_color_leds_r(1)      => eo_led1_r,
			eo_color_leds_r(0)      => eo_led0_r,
			eo_color_leds_g(3)      => eo_led3_g,
			eo_color_leds_g(2)      => eo_led2_g,
			eo_color_leds_g(1)      => eo_led1_g,
			eo_color_leds_g(0)      => eo_led0_g,
			eo_color_leds_b(3)      => eo_led3_b,
			eo_color_leds_b(2)      => eo_led2_b,
			eo_color_leds_b(1)      => eo_led1_b,
			eo_color_leds_b(0)      => eo_led0_b,
			eo_basic_leds_l(3)      => eo_led7,
			eo_basic_leds_l(2)      => eo_led6,
			eo_basic_leds_l(1)      => eo_led5,
			eo_basic_leds_l(0)      => eo_led4
		);

	-- 4x spi clock enable divider for PMOD CLS SCK output. No
	-- generated clock constraint. The 80 MHz or 20 MHz clock is divided
	-- down to 2.5 MHz; and later divided down to 625 KHz on
	-- the PMOD CLS bus.
	u_2_5mhz_ce_divider : entity work.clock_enable_divider(rtl)
		generic map(
			par_ce_divisor => (c_FCLK / 625000 / 4)
		)
		port map(
			o_ce_div  => s_ce_2_5mhz,
			i_clk_mhz => s_clk_40mhz,
			i_rst_mhz => s_rst_40mhz,
			i_ce_mhz  => '1'
		);

	u_sf3_ce_divider : entity work.clock_enable_divider(rtl)
		generic map(
			par_ce_divisor => c_sf3_tester_ce_div_ratio
		)
		port map(
			o_ce_div  => s_sf3_ce_div,
			i_clk_mhz => s_clk_40mhz,
			i_rst_mhz => s_rst_40mhz,
			i_ce_mhz  => '1'
		);

	-- Synchronize and debounce the four input buttons on the Arty A7 to be
	-- debounced and exclusive of each other (ignored if more than one
	-- depressed at the same time).
	si_buttons <= ei_bt3 & ei_bt2 & ei_bt1 & ei_bt0;

	u_buttons_deb_0123 : entity work.multi_input_debounce(moore_fsm)
		generic map(
			FCLK => c_FCLK
		)
		port map(
			i_clk_mhz  => s_clk_40mhz,
			i_rst_mhz  => s_rst_40mhz,
			ei_buttons => si_buttons,
			o_btns_deb => s_btns_deb
		);

	-- Synchronize and debounce the four input switches on the Arty A7 to be
	-- debounced and exclusive of each other (ignored if more than one
	-- selected at the same time).
	si_switches <= ei_sw3 & ei_sw2 & ei_sw1 & ei_sw0;

	u_switches_deb_0123 : entity work.multi_input_debounce(moore_fsm)
		generic map(
			FCLK => c_FCLK
		)
		port map(
			i_clk_mhz  => s_clk_40mhz,
			i_rst_mhz  => s_rst_40mhz,
			ei_buttons => si_switches,
			o_btns_deb => s_sw_deb
		);

	-- Tri-state outputs of PMOD CLS custom driver.
	eo_pmod_cls_sck <= so_pmod_cls_sck_o  when so_pmod_cls_sck_t = '0' else 'Z';
	eo_pmod_cls_ssn <= so_pmod_cls_ssn_o  when so_pmod_cls_ssn_t = '0' else 'Z';
	eo_pmod_cls_dq0 <= so_pmod_cls_mosi_o when so_pmod_cls_mosi_t = '0' else 'Z';

	-- Instance of the PMOD CLS driver for 16x2 character LCD display for purposes
	-- of an output display.
	u_pmod_cls_custom_driver : entity work.pmod_cls_custom_driver(rtl)
		generic map (
			parm_fast_simulation   => parm_fast_simulation,
			parm_FCLK              => c_FCLK,
			parm_ext_spi_clk_ratio => (c_FCLK / 625000),
			parm_tx_len_bits       => c_stand_spi_tx_fifo_count_bits,
			parm_wait_cyc_bits     => c_stand_spi_wait_count_bits,
			parm_rx_len_bits       => c_stand_spi_rx_fifo_count_bits
		)
		port map (
			i_clk_mhz              => s_clk_40mhz,
			i_rst_mhz              => s_rst_40mhz,
			i_ce_2_5mhz            => s_ce_2_5mhz,
			eo_sck_t               => so_pmod_cls_sck_t,
			eo_sck_o               => so_pmod_cls_sck_o,
			eo_ssn_t               => so_pmod_cls_ssn_t,
			eo_ssn_o               => so_pmod_cls_ssn_o,
			eo_mosi_t              => so_pmod_cls_mosi_t,
			eo_mosi_o              => so_pmod_cls_mosi_o,
			ei_miso                => ei_pmod_cls_dq1,
			o_command_ready        => s_cls_command_ready,
			i_cmd_wr_clear_display => s_cls_wr_clear_display,
			i_cmd_wr_text_line1    => s_cls_wr_text_line1,
			i_cmd_wr_text_line2    => s_cls_wr_text_line2,
			i_dat_ascii_line1      => s_cls_txt_ascii_line1,
			i_dat_ascii_line2      => s_cls_txt_ascii_line2
		);

	-- Custom driver for the PMOD SF3 enabling erase of a subsector,
	-- programming the data of a page, and reading the data of a page.
	-- Note that each subsector contains 16 successive pages.
	u_pmod_sf3_custom_driver : entity work.pmod_sf3_custom_driver
		generic map (
			parm_fast_simulation   => parm_fast_simulation,
			parm_FCLK              => c_FCLK,
			parm_ext_spi_clk_ratio => (c_sf3_tester_ce_div_ratio * 4),
			parm_tx_len_bits       => c_quad_spi_tx_fifo_count_bits,
			parm_wait_cyc_bits     => c_quad_spi_wait_count_bits,
			parm_rx_len_bits       => c_quad_spi_rx_fifo_count_bits
		)
		port map (
			i_clk_mhz             => s_clk_40mhz,
			i_rst_mhz             => s_rst_40mhz,
			i_ce_mhz_div          => s_sf3_ce_div,
			eio_sck_o             => sio_sf3_sck_o,
			eio_sck_t             => sio_sf3_sck_t,
			eio_ssn_o             => sio_sf3_ssn_o,
			eio_ssn_t             => sio_sf3_ssn_t,
			eio_mosi_dq0_o        => sio_sf3_mosi_dq0_o,
			eio_mosi_dq0_i        => sio_sf3_mosi_dq0_i,
			eio_mosi_dq0_t        => sio_sf3_mosi_dq0_t,
			eio_miso_dq1_o        => sio_sf3_miso_dq1_o,
			eio_miso_dq1_i        => sio_sf3_miso_dq1_i,
			eio_miso_dq1_t        => sio_sf3_miso_dq1_t,
			eio_wrpn_dq2_o        => sio_sf3_wrpn_dq2_o,
			eio_wrpn_dq2_i        => sio_sf3_wrpn_dq2_i,
			eio_wrpn_dq2_t        => sio_sf3_wrpn_dq2_t,
			eio_hldn_dq3_o        => sio_sf3_hldn_dq3_o,
			eio_hldn_dq3_i        => sio_sf3_hldn_dq3_i,
			eio_hldn_dq3_t        => sio_sf3_hldn_dq3_t,
			o_command_ready       => s_sf3_command_ready,
			i_address_of_cmd      => s_sf3_address_of_cmd,
			i_cmd_erase_subsector => s_sf3_cmd_erase_subsector,
			i_cmd_page_program    => s_sf3_cmd_page_program,
			i_cmd_random_read     => s_sf3_cmd_random_read,
			i_len_random_read     => s_sf3_len_random_read,
			i_wr_data_stream      => s_sf3_wr_data_stream,
			i_wr_data_valid       => s_sf3_wr_data_valid,
			o_wr_data_ready       => s_sf3_wr_data_ready,
			o_rd_data_stream      => s_sf3_rd_data_stream,
			o_rd_data_valid       => s_sf3_rd_data_valid,
			o_reg_status          => s_sf3_reg_status,
			o_reg_flag            => s_sf3_reg_flag
		);

	-- PMOD SF3 Quad SPI tri-state inout connections for QSPI bus

	eo_pmod_sf3_sck <= sio_sf3_sck_o when sio_sf3_sck_t = '0' else 'Z';

	eo_pmod_sf3_ssn <= sio_sf3_ssn_o when sio_sf3_ssn_t = '0' else 'Z';

	eio_pmod_sf3_mosi_dq0 <= sio_sf3_mosi_dq0_o when sio_sf3_mosi_dq0_t = '0' else 'Z';
	sio_sf3_mosi_dq0_i    <= eio_pmod_sf3_mosi_dq0;

	eio_pmod_sf3_miso_dq1 <= sio_sf3_miso_dq1_o when sio_sf3_miso_dq1_t = '0' else 'Z';
	sio_sf3_miso_dq1_i    <= eio_pmod_sf3_miso_dq1;

	eio_pmod_sf3_wrpn_dq2 <= sio_sf3_wrpn_dq2_o when sio_sf3_wrpn_dq2_t = '0' else 'Z';
	sio_sf3_wrpn_dq2_i    <= eio_pmod_sf3_wrpn_dq2;

	eio_pmod_sf3_hldn_dq3 <= sio_sf3_hldn_dq3_o when sio_sf3_hldn_dq3_t = '0' else 'Z';
	sio_sf3_hldn_dq3_i    <= eio_pmod_sf3_hldn_dq3;

	-- timer strategy #1 for the PMOD experiment FSM
	p_tester_timer : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			if (s_rst_40mhz = '1') then
				s_t <= 0;
			elsif (s_sf3_ce_div = '1') then
				if (s_tester_pr_state /= s_tester_nx_state) then
					s_t <= 0;
				elsif (s_t < c_t_max) then
					s_t <= s_t + 1;
				end if;
			end if;
		end if;
	end process p_tester_timer;

	-- state and auxiliary registers for the PMOD experiment FSM
	p_tester_fsm_state : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			if (s_rst_40mhz = '1') then
				s_tester_pr_state <= ST_WAIT_BUTTON_DEP;

				s_sf3_dat_wr_cntidx_aux <= 0;
				s_sf3_dat_rd_cntidx_aux <= 0;
				s_sf3_test_pass_aux     <= '0';
				s_sf3_test_done_aux     <= '0';
				s_sf3_err_count_aux     <= 0;
				s_sf3_pattern_start_aux <= std_logic_vector(c_tester_pattern_startval_a);
				s_sf3_pattern_incr_aux  <= std_logic_vector(c_tester_patterh_incrval_a);
				s_sf3_pattern_track_aux <= x"00";
				s_sf3_addr_start_aux    <= x"00000000";
				s_sf3_start_at_zero_aux <= '1';
				s_sf3_i_aux             <= 0;

			elsif (s_sf3_ce_div = '1') then
				s_tester_pr_state <= s_tester_nx_state;

				s_sf3_dat_wr_cntidx_aux <= s_sf3_dat_wr_cntidx_val;
				s_sf3_dat_rd_cntidx_aux <= s_sf3_dat_rd_cntidx_val;
				s_sf3_test_pass_aux     <= s_sf3_test_pass_val;
				s_sf3_test_done_aux     <= s_sf3_test_done_val;
				s_sf3_err_count_aux     <= s_sf3_err_count_val;
				s_sf3_pattern_start_aux <= s_sf3_pattern_start_val;
				s_sf3_pattern_incr_aux  <= s_sf3_pattern_incr_val;
				s_sf3_pattern_track_aux <= s_sf3_pattern_track_val;
				s_sf3_addr_start_aux    <= s_sf3_addr_start_val;
				s_sf3_start_at_zero_aux <= s_sf3_start_at_zero_val;
				s_sf3_i_aux             <= s_sf3_i_val;
			end if;
		end if;
	end process p_tester_fsm_state;

	-- Basic LED outputs to indicate test passed or failed
	s_basic_led_lumin_value(0) <= x"FF" when s_sf3_test_pass_aux = '1' else x"00";
	s_basic_led_lumin_value(1) <= x"FF" when s_sf3_test_done_aux = '1' else x"00";
	s_basic_led_lumin_value(2) <= x"00";
	s_basic_led_lumin_value(3) <= x"00";

	-- Color LED stage output indication for the PMOD experieent FSM progress
	-- and current state group.
	p_tester_fsm_progress : process(s_tester_pr_state)
	begin
		s_color_led_red_value   <= (x"00", x"00", x"00", x"00");
		s_color_led_green_value <= (x"00", x"00", x"00", x"00");
		s_color_led_blue_value  <= (x"00", x"00", x"00", x"00");

		case (s_tester_pr_state) is
			when ST_WAIT_BUTTON0_REL | ST_SET_PATTERN_A |
				ST_SET_START_ADDR_A | ST_SET_START_WAIT_A =>
				s_color_led_green_value(0) <= x"FF";

			when ST_WAIT_BUTTON1_REL | ST_SET_PATTERN_B |
				ST_SET_START_ADDR_B | ST_SET_START_WAIT_B =>
				s_color_led_green_value(1) <= x"FF";

			when ST_WAIT_BUTTON2_REL | ST_SET_PATTERN_C |
				ST_SET_START_ADDR_C | ST_SET_START_WAIT_C =>
				s_color_led_green_value(2) <= x"FF";

			when ST_WAIT_BUTTON3_REL | ST_SET_PATTERN_D |
				ST_SET_START_ADDR_D | ST_SET_START_WAIT_D =>
				s_color_led_green_value(3) <= x"FF";

			when ST_CMD_ERASE_START | ST_CMD_ERASE_WAIT |
				ST_CMD_ERASE_NEXT | ST_CMD_ERASE_DONE =>
				s_color_led_red_value(0)   <= x"80";
				s_color_led_green_value(0) <= x"80";
				s_color_led_blue_value(0)  <= x"80";

			when ST_CMD_PAGE_START | ST_CMD_PAGE_BYTE | ST_CMD_PAGE_WAIT |
				ST_CMD_PAGE_NEXT | ST_CMD_PAGE_DONE =>
				s_color_led_red_value(1)   <= x"80";
				s_color_led_green_value(1) <= x"80";
				s_color_led_blue_value(1)  <= x"80";

			when ST_CMD_READ_START | ST_CMD_READ_BYTE | ST_CMD_READ_WAIT |
				ST_CMD_READ_NEXT | ST_CMD_READ_DONE =>
				s_color_led_red_value(2)   <= x"80";
				s_color_led_green_value(2) <= x"80";
				s_color_led_blue_value(2)  <= x"80";

			when ST_DISPLAY_FINAL =>
				s_color_led_red_value(3)   <= x"80";
				s_color_led_green_value(3) <= x"80";
				s_color_led_blue_value(3)  <= x"80";

			when others => -- ST_WAIT_BUTTON_DEP =>
				s_color_led_red_value <= (x"FF", x"FF", x"FF", x"FF");
		end case;
	end process p_tester_fsm_progress;

	-- combinatorial logic for the PMOD experieent FSM
	p_tester_fsm_comb : process(
			s_tester_pr_state,
			s_btns_deb, s_sw_deb,
			s_sf3_wr_data_ready,
			s_sf3_command_ready,
			s_sf3_rd_data_valid,
			s_sf3_rd_data_stream,
			s_sf3_dat_wr_cntidx_aux,
			s_sf3_dat_rd_cntidx_aux,
			s_sf3_test_pass_aux,
			s_sf3_test_done_aux,
			s_sf3_err_count_aux,
			s_sf3_pattern_start_aux,
			s_sf3_pattern_incr_aux,
			s_sf3_pattern_track_aux,
			s_sf3_addr_start_aux,
			s_sf3_start_at_zero_aux,
			s_sf3_i_aux,
			s_t)
	begin
		s_sf3_dat_wr_cntidx_val <= s_sf3_dat_wr_cntidx_aux;
		s_sf3_dat_rd_cntidx_val <= s_sf3_dat_rd_cntidx_aux;
		s_sf3_test_pass_val     <= s_sf3_test_pass_aux;
		s_sf3_test_done_val     <= s_sf3_test_done_aux;
		s_sf3_err_count_val     <= s_sf3_err_count_aux;
		s_sf3_pattern_start_val <= s_sf3_pattern_start_aux;
		s_sf3_pattern_incr_val  <= s_sf3_pattern_incr_aux;
		s_sf3_pattern_track_val <= s_sf3_pattern_track_aux;
		s_sf3_addr_start_val    <= s_sf3_addr_start_aux;
		s_sf3_start_at_zero_val <= s_sf3_start_at_zero_aux;
		s_sf3_i_val             <= s_sf3_i_aux;

		s_sf3_wr_data_stream <= x"00";
		s_sf3_wr_data_valid  <= '0';

		case (s_tester_pr_state) is
			when ST_WAIT_BUTTON_DEP =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (to_integer(unsigned(s_sf3_addr_start_aux)) < c_last_starting_byte_addr) then
					s_sf3_test_done_val <= '0';

					if ((s_btns_deb(0) = '1') or (s_sw_deb(0) = '1')) then
						s_tester_nx_state <= ST_WAIT_BUTTON0_REL;
					elsif ((s_btns_deb(1) = '1') or (s_sw_deb(1) = '1'))then
						s_tester_nx_state <= ST_WAIT_BUTTON1_REL;
					elsif ((s_btns_deb(2) = '1') or (s_sw_deb(2) = '1')) then
						s_tester_nx_state <= ST_WAIT_BUTTON2_REL;
					elsif ((s_btns_deb(3) = '1') or (s_sw_deb(3) = '1')) then
						s_tester_nx_state <= ST_WAIT_BUTTON3_REL;
					else
						s_tester_nx_state <= ST_WAIT_BUTTON_DEP;
					end if;
				else
					s_sf3_test_done_val <= '1';
					s_tester_nx_state   <= ST_WAIT_BUTTON_DEP;
				end if;

			when ST_WAIT_BUTTON0_REL =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_btns_deb(0) = '0') then
					s_tester_nx_state <= ST_SET_PATTERN_A;
				else
					s_tester_nx_state <= ST_WAIT_BUTTON0_REL;
				end if;

			when ST_WAIT_BUTTON1_REL =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_btns_deb(1) = '0') then
					s_tester_nx_state <= ST_SET_PATTERN_B;
				else
					s_tester_nx_state <= ST_WAIT_BUTTON1_REL;
				end if;

			when ST_WAIT_BUTTON2_REL =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_btns_deb(2) = '0') then
					s_tester_nx_state <= ST_SET_PATTERN_C;
				else
					s_tester_nx_state <= ST_WAIT_BUTTON2_REL;
				end if;

			when ST_WAIT_BUTTON3_REL =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_btns_deb(0) = '0') then
					s_tester_nx_state <= ST_SET_PATTERN_D;
				else
					s_tester_nx_state <= ST_WAIT_BUTTON3_REL;
				end if;

			when ST_SET_PATTERN_A =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				s_sf3_pattern_start_val <= std_logic_vector(c_tester_pattern_startval_a);
				s_sf3_pattern_incr_val  <= std_logic_vector(c_tester_patterh_incrval_a);

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_SET_START_ADDR_A;
				else
					s_tester_nx_state <= ST_SET_PATTERN_A;
				end if;

			when ST_SET_PATTERN_B =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				s_sf3_pattern_start_val <= std_logic_vector(c_tester_pattern_startval_b);
				s_sf3_pattern_incr_val  <= std_logic_vector(c_tester_patterh_incrval_b);

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_SET_START_ADDR_B;
				else
					s_tester_nx_state <= ST_SET_PATTERN_B;
				end if;


			when ST_SET_PATTERN_C =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				s_sf3_pattern_start_val <= std_logic_vector(c_tester_pattern_startval_c);
				s_sf3_pattern_incr_val  <= std_logic_vector(c_tester_patterh_incrval_c);

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_SET_START_ADDR_C;
				else
					s_tester_nx_state <= ST_SET_PATTERN_C;
				end if;

			when ST_SET_PATTERN_D =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				s_sf3_pattern_start_val <= std_logic_vector(c_tester_pattern_startval_d);
				s_sf3_pattern_incr_val  <= std_logic_vector(c_tester_patterh_incrval_d);

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_SET_START_ADDR_D;
				else
					s_tester_nx_state <= ST_SET_PATTERN_D;
				end if;

			when ST_SET_START_ADDR_A =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');
				s_sf3_start_at_zero_val   <= '0';
				s_sf3_i_val               <= 0;

				-- Increment the address for the next iteration
				if (s_sf3_start_at_zero_aux = '1') then
					s_sf3_addr_start_val <= x"00000000";
					s_sf3_test_done_val  <= '0';
					s_tester_nx_state    <= ST_SET_START_WAIT_A;
				elsif (to_integer(unsigned(s_sf3_addr_start_aux)) < c_last_starting_byte_addr) then
					s_sf3_addr_start_val <= std_logic_vector(
							unsigned(s_sf3_addr_start_aux) + c_per_iteration_byte_count);
					s_sf3_test_done_val <= '0';
					s_tester_nx_state   <= ST_SET_START_WAIT_A;
				else
					s_sf3_test_done_val <= '1';
					s_tester_nx_state   <= ST_WAIT_BUTTON_DEP;
				end if;

			when ST_SET_START_ADDR_B =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');
				s_sf3_start_at_zero_val   <= '0';
				s_sf3_i_val               <= 0;

				-- Increment the address for the next iteration
				if (s_sf3_start_at_zero_aux = '1') then
					s_sf3_addr_start_val <= x"00000000";
					s_sf3_test_done_val  <= '0';
					s_tester_nx_state    <= ST_SET_START_WAIT_B;
				elsif (to_integer(unsigned(s_sf3_addr_start_aux)) < c_last_starting_byte_addr) then
					s_sf3_addr_start_val <= std_logic_vector(
							unsigned(s_sf3_addr_start_aux) + c_per_iteration_byte_count);
					s_sf3_test_done_val <= '0';
					s_tester_nx_state   <= ST_SET_START_WAIT_B;
				else
					s_sf3_test_done_val <= '1';
					s_tester_nx_state   <= ST_WAIT_BUTTON_DEP;
				end if;

			when ST_SET_START_ADDR_C =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');
				s_sf3_start_at_zero_val   <= '0';
				s_sf3_i_val               <= 0;

				-- Increment the address for the next iteration
				if (s_sf3_start_at_zero_aux = '1') then
					s_sf3_addr_start_val <= x"00000000";
					s_sf3_test_done_val  <= '0';
					s_tester_nx_state    <= ST_SET_START_WAIT_C;
				elsif (to_integer(unsigned(s_sf3_addr_start_aux)) < c_last_starting_byte_addr) then
					s_sf3_addr_start_val <= std_logic_vector(
							unsigned(s_sf3_addr_start_aux) + c_per_iteration_byte_count);
					s_sf3_test_done_val <= '0';
					s_tester_nx_state   <= ST_SET_START_WAIT_C;
				else
					s_sf3_test_done_val <= '1';
					s_tester_nx_state   <= ST_WAIT_BUTTON_DEP;
				end if;

			when ST_SET_START_ADDR_D =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');
				s_sf3_start_at_zero_val   <= '0';
				s_sf3_i_val               <= 0;

				-- Increment the address for the next iteration
				if (s_sf3_start_at_zero_aux = '1') then
					s_sf3_addr_start_val <= x"00000000";
					s_sf3_test_done_val  <= '0';
					s_tester_nx_state    <= ST_SET_START_WAIT_D;
				elsif (to_integer(unsigned(s_sf3_addr_start_aux)) < c_last_starting_byte_addr) then
					s_sf3_addr_start_val <= std_logic_vector(
							unsigned(s_sf3_addr_start_aux) + c_per_iteration_byte_count);
					s_sf3_test_done_val <= '0';
					s_tester_nx_state   <= ST_SET_START_WAIT_D;
				else
					s_sf3_test_done_val <= '1';
					s_tester_nx_state   <= ST_WAIT_BUTTON_DEP;
				end if;

			when ST_SET_START_WAIT_A =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_t = c_t_max / 2) then
					s_tester_nx_state <= ST_CMD_ERASE_START;
				else
					s_tester_nx_state <= ST_SET_START_WAIT_A;
				end if;

			when ST_SET_START_WAIT_B =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_t = c_t_max / 2) then
					s_tester_nx_state <= ST_CMD_ERASE_START;
				else
					s_tester_nx_state <= ST_SET_START_WAIT_B;
				end if;

			when ST_SET_START_WAIT_C =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_t = c_t_max / 2) then
					s_tester_nx_state <= ST_CMD_ERASE_START;
				else
					s_tester_nx_state <= ST_SET_START_WAIT_C;
				end if;

			when ST_SET_START_WAIT_D =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= (others => '0');

				if (s_t = c_t_max / 2) then
					s_tester_nx_state <= ST_CMD_ERASE_START;
				else
					s_tester_nx_state <= ST_SET_START_WAIT_D;
				end if;

			when ST_CMD_ERASE_START =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '1';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_subsector_addr_incr));

				if (s_sf3_command_ready = '0') then
					s_tester_nx_state <= ST_CMD_ERASE_WAIT;
				else
					s_tester_nx_state <= ST_CMD_ERASE_START;
				end if;

			when ST_CMD_ERASE_WAIT =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_subsector_addr_incr));

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_CMD_ERASE_NEXT;
				else
					s_tester_nx_state <= ST_CMD_ERASE_WAIT;
				end if;

			when ST_CMD_ERASE_NEXT =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= s_sf3_i_aux + 1;

				if (s_sf3_i_aux < (c_tester_subsector_cnt_per_iter - 1)) then
					s_tester_nx_state <= ST_CMD_ERASE_START;
				else
					s_tester_nx_state <= ST_CMD_ERASE_DONE;
				end if;

			when ST_CMD_ERASE_DONE =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= 0;
				s_sf3_pattern_track_val   <= s_sf3_pattern_start_aux;

				s_tester_nx_state <= ST_CMD_PAGE_START;

			when ST_CMD_PAGE_START =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '1';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));
				s_sf3_dat_wr_cntidx_val <= 0;

				if (s_sf3_command_ready = '0') then
					s_tester_nx_state <= ST_CMD_PAGE_BYTE;
				else
					s_tester_nx_state <= ST_CMD_PAGE_START;
				end if;

			when ST_CMD_PAGE_BYTE =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));

				if (s_sf3_wr_data_ready = '1') then
					-- Assign this iterations byte value
					s_sf3_wr_data_stream <= s_sf3_pattern_track_aux;
					s_sf3_wr_data_valid  <= '1';

					-- Calculate the next iterations byte value
					s_sf3_pattern_track_val <= std_logic_vector(
							unsigned(s_sf3_pattern_track_aux) +
							unsigned(s_sf3_pattern_incr_aux));

					-- Increment counter for next byte
					if (s_sf3_dat_wr_cntidx_aux < 255) then
						s_sf3_dat_wr_cntidx_val <= s_sf3_dat_wr_cntidx_aux + 1;
					end if;

					-- Check current bytes counter for next FSM state
					if (s_sf3_dat_wr_cntidx_aux = 255) then
						-- Wrote bytes 0 through 255, totaling at a page lenth
						-- of 256 bytes. Now advance to the WAIT state.
						s_tester_nx_state <= ST_CMD_PAGE_WAIT;
					else
						s_tester_nx_state <= ST_CMD_PAGE_BYTE;
					end if;
				else
					s_sf3_wr_data_stream <= x"00";
					s_sf3_wr_data_valid  <= '0';
					s_tester_nx_state    <= ST_CMD_PAGE_BYTE;
				end if;

			when ST_CMD_PAGE_WAIT =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_CMD_PAGE_NEXT;
				else
					s_tester_nx_state <= ST_CMD_PAGE_WAIT;
				end if;

			when ST_CMD_PAGE_NEXT =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= s_sf3_i_aux + 1;

				if (s_sf3_i_aux < (c_tester_page_cnt_per_iter - 1)) then
					s_tester_nx_state <= ST_CMD_PAGE_START;
				else
					s_tester_nx_state <= ST_CMD_PAGE_DONE;
				end if;

			when ST_CMD_PAGE_DONE =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= 0;
				s_sf3_pattern_track_val   <= s_sf3_pattern_start_aux;

				s_tester_nx_state <= ST_CMD_READ_START;

			when ST_CMD_READ_START =>
				s_sf3_len_random_read <= std_logic_vector(
						to_unsigned(c_sf3_page_addr_incr, s_sf3_len_random_read'length));
				s_sf3_cmd_random_read     <= '1';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));
				s_sf3_dat_rd_cntidx_val <= 0;

				if (s_sf3_command_ready = '0') then
					s_tester_nx_state <= ST_CMD_READ_BYTE;
				else
					s_tester_nx_state <= ST_CMD_READ_START;
				end if;

			when ST_CMD_READ_BYTE =>
				s_sf3_len_random_read <= std_logic_vector(
						to_unsigned(c_sf3_page_addr_incr, s_sf3_len_random_read'length));
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));

				if (s_sf3_rd_data_valid = '1') then
					-- Compare this iterations byte value
					if (s_sf3_rd_data_stream /= s_sf3_pattern_track_aux) then
						s_sf3_err_count_val <= s_sf3_err_count_aux + 1;
					else
						-- FIXME: this is to show errors that did not occur to test the error reporting on the LCD and USB=UART
						s_sf3_err_count_val <= s_sf3_err_count_aux + 0;
					end if;

					-- Calculate the next iterations byte value
					s_sf3_pattern_track_val <= std_logic_vector(
							unsigned(s_sf3_pattern_track_aux) +
							unsigned(s_sf3_pattern_incr_aux));

					-- Increment counter for next byte
					if (s_sf3_dat_rd_cntidx_aux < 255) then
						s_sf3_dat_rd_cntidx_val <= s_sf3_dat_rd_cntidx_aux + 1;
					end if;

					-- Check current bytes counter for next FSM state
					if (s_sf3_dat_rd_cntidx_aux = 255) then
						-- Wrote bytes 0 through 255, totaling at a page lenth
						-- of 256 bytes. Now advance to the WAIT state.
						s_tester_nx_state <= ST_CMD_READ_WAIT;
					else
						s_tester_nx_state <= ST_CMD_READ_BYTE;
					end if;
				else
					s_tester_nx_state <= ST_CMD_READ_BYTE;
				end if;

			when ST_CMD_READ_WAIT =>
				s_sf3_len_random_read <= std_logic_vector(
						to_unsigned(c_sf3_page_addr_incr, s_sf3_len_random_read'length));
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= std_logic_vector(
						unsigned(s_sf3_addr_start_aux) +
						(s_sf3_i_aux * c_sf3_page_addr_incr));

				if (s_sf3_command_ready = '1') then
					s_tester_nx_state <= ST_CMD_READ_NEXT;
				else
					s_tester_nx_state <= ST_CMD_READ_WAIT;
				end if;

			when ST_CMD_READ_NEXT =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= s_sf3_i_aux + 1;

				if (s_sf3_i_aux < (c_tester_page_cnt_per_iter - 1)) then
					s_tester_nx_state <= ST_CMD_READ_START;
				else
					s_tester_nx_state <= ST_CMD_READ_DONE;
				end if;

			when ST_CMD_READ_DONE =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";
				s_sf3_i_val               <= 0;
				s_sf3_pattern_track_val   <= s_sf3_pattern_start_aux;

				s_tester_nx_state <= ST_DISPLAY_FINAL;

			when others => -- ST_DISPLAY_FINAL =>
				s_sf3_len_random_read     <= (others => '0');
				s_sf3_cmd_random_read     <= '0';
				s_sf3_cmd_page_program    <= '0';
				s_sf3_cmd_erase_subsector <= '0';
				s_sf3_address_of_cmd      <= x"00000000";

				if (s_sf3_err_count_aux = 0) then
					s_sf3_test_pass_val <= '1';
				else
					s_sf3_test_pass_val <= '0';
				end if;

				if (s_t = c_t_max) then
					s_tester_nx_state <= ST_WAIT_BUTTON_DEP;
				else
					s_tester_nx_state <= ST_DISPLAY_FINAL;
				end if;
		end case;
	end process p_tester_fsm_comb;

	-- Assembly of LCD 16x2 text lines
	s_cls_txt_ascii_pattern_1char <=
		x"41" when ((unsigned(s_sf3_pattern_start_aux) = c_tester_pattern_startval_a) and (unsigned(s_sf3_pattern_incr_aux) = c_tester_patterh_incrval_a)) else
		x"42" when ((unsigned(s_sf3_pattern_start_aux) = c_tester_pattern_startval_b) and (unsigned(s_sf3_pattern_incr_aux) = c_tester_patterh_incrval_b)) else
		x"43" when ((unsigned(s_sf3_pattern_start_aux) = c_tester_pattern_startval_c) and (unsigned(s_sf3_pattern_incr_aux) = c_tester_patterh_incrval_c)) else
		x"44" when ((unsigned(s_sf3_pattern_start_aux) = c_tester_pattern_startval_d) and (unsigned(s_sf3_pattern_incr_aux) = c_tester_patterh_incrval_d)) else
		x"2A";

	s_cls_txt_ascii_address_8char <=
		ascii_of_hdigit(s_sf3_addr_start_aux(31 downto 28)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(27 downto 24)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(23 downto 20)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(19 downto 16)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(15 downto 12)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(11 downto 8)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(7 downto 4)) &
		ascii_of_hdigit(s_sf3_addr_start_aux(3 downto 0));

	s_cls_txt_ascii_line1 <= (x"53" & x"46" & x"33" & x"20" &
			x"50" & s_cls_txt_ascii_pattern_1char & x"20" & x"68" &
			s_cls_txt_ascii_address_8char);

	p_sf3mode_3char : process (s_tester_pr_state)
	begin
		case(s_tester_pr_state) is
			when ST_WAIT_BUTTON0_REL | ST_SET_PATTERN_A
				| ST_WAIT_BUTTON1_REL | ST_SET_PATTERN_B
				| ST_WAIT_BUTTON2_REL | ST_SET_PATTERN_C
				| ST_WAIT_BUTTON3_REL | ST_SET_PATTERN_D
				| ST_SET_START_ADDR_A | ST_SET_START_WAIT_A
				| ST_SET_START_ADDR_B | ST_SET_START_WAIT_B
				| ST_SET_START_ADDR_C | ST_SET_START_WAIT_C
				| ST_SET_START_ADDR_D | ST_SET_START_WAIT_D =>
				-- text: "GO "
				s_cls_txt_ascii_sf3mode_3char <= (x"47" & x"4F" & x"20");
			when ST_CMD_ERASE_START | ST_CMD_ERASE_WAIT |
				ST_CMD_ERASE_NEXT | ST_CMD_ERASE_DONE =>
				-- text: "ERS"
				s_cls_txt_ascii_sf3mode_3char <= (x"45" & x"52" & x"53");
			when ST_CMD_PAGE_START | ST_CMD_PAGE_BYTE | ST_CMD_PAGE_WAIT |
				ST_CMD_PAGE_NEXT | ST_CMD_PAGE_DONE =>
				-- text: "PRO"
				s_cls_txt_ascii_sf3mode_3char <= (x"50" & x"52" & x"4F");
			when ST_CMD_READ_START | ST_CMD_READ_BYTE | ST_CMD_READ_WAIT |
				ST_CMD_READ_NEXT | ST_CMD_READ_DONE =>
				-- text: "TST"
				s_cls_txt_ascii_sf3mode_3char <= (x"54" & x"53" & x"54");
			when ST_DISPLAY_FINAL =>
				-- text: "END"
				s_cls_txt_ascii_sf3mode_3char <= (x"45" & x"4E" & x"44");
			when others => -- ST_WAIT_BUTTON_DEP =>
				           -- text: "GO ""
				s_cls_txt_ascii_sf3mode_3char <= (x"47" & x"4F" & x"20");
		end case;
	end process p_sf3mode_3char;

	s_cls_txt_ascii_errcntdec_8char <=
		s_cls_txt_ascii_errcntdec_char7 &
		s_cls_txt_ascii_errcntdec_char6 &
		s_cls_txt_ascii_errcntdec_char5 &
		s_cls_txt_ascii_errcntdec_char4 &
		s_cls_txt_ascii_errcntdec_char3 &
		s_cls_txt_ascii_errcntdec_char2 &
		s_cls_txt_ascii_errcntdec_char1 &
		s_cls_txt_ascii_errcntdec_char0;

	-- Registering the error count digits to close timing delays if clock is
	-- selected as 80 MHz instead of 20 MHz;
	p_reg_errcnt_digits : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			s_sf3_err_count_divide7 <= s_sf3_err_count_aux / 10000000 mod 10;
			s_sf3_err_count_digit7  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide7, 4));

			s_sf3_err_count_divide6 <= s_sf3_err_count_aux / 1000000 mod 10;
			s_sf3_err_count_digit6  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide6, 4));

			s_sf3_err_count_divide5 <= s_sf3_err_count_aux / 100000 mod 10;
			s_sf3_err_count_digit5  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide5, 4));

			s_sf3_err_count_divide4 <= s_sf3_err_count_aux / 10000 mod 10;
			s_sf3_err_count_digit4  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide4, 4));

			s_sf3_err_count_divide3 <= s_sf3_err_count_aux / 1000 mod 10;
			s_sf3_err_count_digit3  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide3, 4));

			s_sf3_err_count_divide2 <= s_sf3_err_count_aux / 100 mod 10;
			s_sf3_err_count_digit2  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide2, 4));

			s_sf3_err_count_divide1 <= s_sf3_err_count_aux / 10 mod 10;
			s_sf3_err_count_digit1  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide1, 4));

			s_sf3_err_count_divide0 <= s_sf3_err_count_aux mod 10;
			s_sf3_err_count_digit0  <= std_logic_vector(to_unsigned(s_sf3_err_count_divide0, 4));

			s_cls_txt_ascii_errcntdec_char7 <= ascii_of_hdigit(s_sf3_err_count_digit7);
			s_cls_txt_ascii_errcntdec_char6 <= ascii_of_hdigit(s_sf3_err_count_digit6);
			s_cls_txt_ascii_errcntdec_char5 <= ascii_of_hdigit(s_sf3_err_count_digit5);
			s_cls_txt_ascii_errcntdec_char4 <= ascii_of_hdigit(s_sf3_err_count_digit4);
			s_cls_txt_ascii_errcntdec_char3 <= ascii_of_hdigit(s_sf3_err_count_digit3);
			s_cls_txt_ascii_errcntdec_char2 <= ascii_of_hdigit(s_sf3_err_count_digit2);
			s_cls_txt_ascii_errcntdec_char1 <= ascii_of_hdigit(s_sf3_err_count_digit1);
			s_cls_txt_ascii_errcntdec_char0 <= ascii_of_hdigit(s_sf3_err_count_digit0);
		end if;
	end process p_reg_errcnt_digits;

	s_cls_txt_ascii_line2 <= (s_cls_txt_ascii_sf3mode_3char & x"20" &
			x"45" & x"52" & x"52" & x"20" & s_cls_txt_ascii_errcntdec_8char);

	-- Assembly of UART text line.
	s_uart_dat_ascii_line <= (s_cls_txt_ascii_line1 & x"20" & s_cls_txt_ascii_line2 & x"0D" & x"0A");

	-- Timer (strategy #1) for timing the PMOD CLS display update
	p_fsm_timer_run_display_update : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			if (s_rst_40mhz = '1') then
				s_cls_i <= 0;
			elsif (s_ce_2_5mhz = '1') then
				if (s_cls_upd_pr_state /= s_cls_upd_nx_state) then
					s_cls_i <= 0;
				elsif (s_cls_i /= c_cls_i_max) then
					s_cls_i <= s_cls_i + 1;
				end if;
			end if;
		end if;
	end process p_fsm_timer_run_display_update;

	-- FSM state transition for timing the PMOD CLS display udpate
	p_fsm_state_run_display_update : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			if (s_rst_40mhz = '1') then
				s_cls_upd_pr_state <= ST_CLS_IDLE;
			elsif (s_ce_2_5mhz = '1') then
				s_cls_upd_pr_state <= s_cls_upd_nx_state;
			end if;
		end if;
	end process p_fsm_state_run_display_update;

	-- FSM combinatorial logic for timing the PMOD CLS display udpate
	p_fsm_comb_run_display_update : process(s_cls_upd_pr_state,
			s_cls_command_ready, s_cls_i)
	begin
		case (s_cls_upd_pr_state) is
			when ST_CLS_CLEAR => -- Step CLEAR: clear the display
				                 -- and then pause until display ready and
				                 -- minimum of \ref c_cls_i_one_ms time delay.
				if (s_cls_i <= c_cls_i_step) then
					s_cls_wr_clear_display <= '1';
				else
					s_cls_wr_clear_display <= '0';
				end if;

				s_cls_wr_text_line1 <= '0';
				s_cls_wr_text_line2 <= '0';

				if ((s_cls_i >= c_cls_i_one_ms) and (s_cls_command_ready = '1')) then
					s_cls_upd_nx_state <= ST_CLS_LINE1;
				else
					s_cls_upd_nx_state <= ST_CLS_CLEAR;
				end if;

			when ST_CLS_LINE1 => -- Step LINE1: write the top line of the LCD
				                 -- and then pause until display ready and
				                 -- minimum of \ref c_cls_i_one_ms time delay.
				s_cls_wr_clear_display <= '0';

				if (s_cls_i <= c_cls_i_step) then
					s_cls_wr_text_line1 <= '1';
				else
					s_cls_wr_text_line1 <= '0';
				end if;

				s_cls_wr_text_line2 <= '0';

				if ((s_cls_i >= c_cls_i_one_ms) and (s_cls_command_ready = '1')) then
					s_cls_upd_nx_state <= ST_CLS_LINE2;
				else
					s_cls_upd_nx_state <= ST_CLS_LINE1;
				end if;

			when ST_CLS_LINE2 => -- Step LINE2: write the bottom line of the LCD
				                 -- and then pause until display ready and
				                 -- minimum of \ref c_cls_i_one_ms time delay.
				s_cls_wr_clear_display <= '0';
				s_cls_wr_text_line1    <= '0';

				if (s_cls_i <= c_cls_i_step) then
					s_cls_wr_text_line2 <= '1';
				else
					s_cls_wr_text_line2 <= '0';
				end if;

				if ((s_cls_i >= c_cls_i_one_ms) and (s_cls_command_ready = '1')) then
					s_cls_upd_nx_state <= ST_CLS_IDLE;
				else
					s_cls_upd_nx_state <= ST_CLS_LINE2;
				end if;

			when others => -- ST_CLS_IDLE
				           -- Step IDLE, wait until display ready to write again
				           -- and minimum of \ref c_cls_i_subsecond time has elapsed.
				s_cls_wr_clear_display <= '0';
				s_cls_wr_text_line1    <= '0';
				s_cls_wr_text_line2    <= '0';

				if (parm_fast_simulation = 0) then
					if ((s_cls_i >= c_cls_i_subsecond) and (s_cls_command_ready = '1')) then
						s_cls_upd_nx_state <= ST_CLS_CLEAR;
					else
						s_cls_upd_nx_state <= ST_CLS_IDLE;
					end if;
				else
					if ((s_cls_i >= c_cls_i_subsecond_fast) and (s_cls_command_ready = '1')) then
						s_cls_upd_nx_state <= ST_CLS_CLEAR;
					else
						s_cls_upd_nx_state <= ST_CLS_IDLE;
					end if;
				end if;
		end case;
	end process p_fsm_comb_run_display_update;

	-- TX ONLY UART function to print the two lines of the PMOD CLS output as a
	-- single line on the dumb terminal, at the same rate as the PMOD CLS updates.
	s_uart_tx_go <= s_cls_wr_clear_display;

	u_uart_tx_only : entity work.uart_tx_only(moore_fsm_recursive)
		generic map (
			parm_BAUD           => 115200,
			parm_tx_len_bits    => 8,
			parm_tx_avail_ready => (128 - 34)
		)
		port map (
			i_clk_mhz     => s_clk_40mhz,
			i_rst_mhz     => s_rst_40mhz,
			i_clk_7_37mhz => s_clk_7_37mhz,
			i_rst_7_37mhz => s_rst_7_37mhz,
			eo_uart_tx    => eo_uart_tx,
			i_tx_data     => s_uart_txdata,
			i_tx_valid    => s_uart_txvalid,
			o_tx_ready    => s_uart_txready
		);

	-- UART TX machine, the 34 bytes of \ref s_uart_dat_ascii_line
	-- are feed into the UART TX ONLY FIFO upon every pulse of the
	-- \ref s_uart_tx_go signal. The UART TX ONLY FIFO machine will
	-- automatically dequeue any bytes present in the queue and quickly
	-- transmit them, one-at-a-time at the \ref parm_BAUD baudrate.

	-- UART TX machine, synchronous state and auxiliary counting register.
	p_uartfeed_fsm_state_aux : process(s_clk_40mhz)
	begin
		if rising_edge(s_clk_40mhz) then
			if (s_rst_40mhz = '1') then
				s_uartfeed_pr_state <= ST_UARTFEED_IDLE;
				s_uart_k_aux        <= 0;
			else
				s_uartfeed_pr_state <= s_uartfeed_nx_state;
				s_uart_k_aux        <= s_uart_k_val;
			end if;
		end if;
	end process p_uartfeed_fsm_state_aux;

	-- UART TX machine, combinatorial next state and auxiliary counting register.
	p_uartfeed_fsm_nx_out : process(s_uartfeed_pr_state, s_uart_k_aux,
			s_uart_tx_go, s_uart_dat_ascii_line, s_uart_txready)
	begin
		case (s_uartfeed_pr_state) is
			when ST_UARTFEED_DATA =>
				-- Enqueue the \ref c_uart_k_preset count of bytes from signal
				-- \ref s_uart_dat_ascii_line. Then transition to the WAIT state.
				s_uart_txdata  <= s_uart_dat_ascii_line(((8 * s_uart_k_aux) - 1) downto (8 * (s_uart_k_aux - 1)));
				s_uart_txvalid <= '1';
				s_uart_k_val   <= s_uart_k_aux - 1;

				if (s_uart_k_aux <= 1) then
					s_uartfeed_nx_state <= ST_UARTFEED_WAIT;
				else
					s_uartfeed_nx_state <= ST_UARTFEED_DATA;
				end if;

			when ST_UARTFEED_WAIT =>
				-- Wait for the \ref s_uart_tx_go pulse to be idle, and then
				-- transition to the IDLE state.
				s_uart_txdata  <= x"00";
				s_uart_txvalid <= '0';
				s_uart_k_val   <= s_uart_k_aux;

				if (s_uart_tx_go = '0') then
					s_uartfeed_nx_state <= ST_UARTFEED_IDLE;
				else
					s_uartfeed_nx_state <= ST_UARTFEED_WAIT;
				end if;

			when others => -- ST_UARTFEED_IDLE
				           -- IDLE the FSM while waiting for a pulse on s_uart_tx_go.
				           -- The value of \ref s_uart_txready is also checked as to
				           -- not overflow the UART TX buffer. If both signals are a
				           -- TRUE value, then transition to enqueueing data.
				s_uart_txdata  <= x"00";
				s_uart_txvalid <= '0';
				s_uart_k_val   <= c_uart_k_preset;

				if ((s_uart_tx_go = '1') and (s_uart_txready = '1')) then
					s_uartfeed_nx_state <= ST_UARTFEED_DATA;
				else
					s_uartfeed_nx_state <= ST_UARTFEED_IDLE;
				end if;
		end case;
	end process p_uartfeed_fsm_nx_out;

end architecture rtl;
--------------------------------------------------------------------------------
