set SRC_DIR ".."
set ACOM_OPTS "-2008 -dbg"
set ALOG_OPTS "-v2k5 -dbg"
set MTI_ALOG_OPTS "-v2k5 -dbg -incdir ${SRC_DIR}/N25Q256A13E_VG12"

amap unisim "C:\\Aldec\\Xilinx_lib_2020.2\\unisim"
amap unimacro "C:\\Aldec\\Xilinx_lib_2020.2\\unimacro"

adel -lib work -all
alib work

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/clock_divider.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/clock_enable_divider.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/arty_reset_synchronizer.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/lcd_text_functions_pkg.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/multi_input_debounce.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pulse_stretcher_synch.vhdl

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/sf_tester_fsm.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/sf_testing_to_ascii.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/lcd_text_feed.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/led_pwm_driver.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/led_palette_updater.vhdl

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_generic_spi_solo.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_generic_qspi_solo.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_sf3_quad_spi_solo.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_cls_stand_spi_solo.vhdl

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_sf3_custom_driver.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/pmod_cls_custom_driver.vhdl

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/uart_tx_feed.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/uart_tx_only.vhdl

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/RTL/fpga_serial_mem_tester.vhdl

eval alog ${MTI_ALOG_OPTS} -work work ${SRC_DIR}/N25Q256A13E_VG12/code/N25Qxxx.v

eval alog ${MTI_ALOG_OPTS} -work work ${SRC_DIR}/Testbench/N25Qxxx_wrapper.v

eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/sf3_testbench_pkg.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/clock_gen.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/board_ui.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/pmod_sf3.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/board_uart.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/pmod_cls.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/fpga_serial_mem_tester_testbench.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/fpga_serial_mem_tester_testharness.vhdl
eval acom ${ACOM_OPTS} -work work ${SRC_DIR}/Testbench/test_default_fpga_regression.vhdl
