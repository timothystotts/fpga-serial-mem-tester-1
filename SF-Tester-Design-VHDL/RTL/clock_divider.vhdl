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
-- \module clock_divider
--
-- \brief A clock divider to divide a MMCM clock by a large divisor, plus
-- synchronized reset in divide clock domain.
--
-- \description When utilizing this module within a Xilinx Vivado RTL design,
-- Vivado requires the usage of create_generated_clock TCL XDC constraint.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--------------------------------------------------------------------------------
entity clock_divider is -- CLKDIV8
	generic(
		par_clk_divisor : natural := 1000
	);
	port(
		i_clk_mhz : in  std_logic; -- the MMCM clock input (MHz)
		i_rst_mhz : in  std_logic; -- the MMCM clock synchronous reset input
		o_clk_div : out std_logic; -- the divided clock signal
		o_rst_div : out std_logic  -- reset signal synchronous to the divided
	                               -- clock
	);
end entity clock_divider;
--------------------------------------------------------------------------------
architecture rtl of clock_divider is
	constant c_clk_max   : natural := (par_clk_divisor / 2) - 1;
	signal s_clk_div_cnt : natural range 0 to c_clk_max;
	signal s_clk_div_ce  : std_logic;
	signal s_clk_out     : std_logic;
	signal s_rst_out     : std_logic;
begin
	-- Divided clock enable generator for half period of divided clock
	p_clk_div_cnt : process(i_clk_mhz, i_rst_mhz)
	begin
		if rising_edge(i_clk_mhz) then
			if (i_rst_mhz = '1') then
				s_clk_div_cnt <= 0;
				s_clk_div_ce  <= '1';
			else
				if (s_clk_div_cnt = c_clk_max) then
					s_clk_div_cnt <= 0;
					s_clk_div_ce  <= '1';
				else
					s_clk_div_cnt <= s_clk_div_cnt + 1;
					s_clk_div_ce  <= '0';
				end if;
			end if;
		end if;
	end process p_clk_div_cnt;

	-- Divided clock signal and synchronous reset signal generator
	p_clk_div_out : process(i_clk_mhz, i_rst_mhz)
	begin
		if rising_edge(i_clk_mhz) then
			if (i_rst_mhz = '1') then
				s_rst_out <= '1';
				s_clk_out <= '0';
			else
				if (s_clk_div_ce = '1') then
					s_rst_out <= s_rst_out and (not s_clk_out);
					s_clk_out <= not s_clk_out;
				end if;
			end if;
		end if;
	end process p_clk_div_out;

	-- Direct outputs
	o_clk_div <= s_clk_out;
	o_rst_div <= s_rst_out;
end architecture rtl;
--------------------------------------------------------------------------------
