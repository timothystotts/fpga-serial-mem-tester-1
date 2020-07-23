# fpga-serial-mem-tester-1

FPGA Serial Mem Tester Version 1
by Timothy Stotts


## Description
A small FPGA project of different implementations for testing a N25Q Serial Flash.
The design targets the Digilent Inc. Arty-A7-100T FPGA development board containing a Xilinx Artix-7 FPGA.
Two peripherals are used: Digilent Inc. Pmod SF3, Digilent Inc. Pmod CLS.

The design is broken into two groupings.

The folder SF-Tester-Design-AXI contains a Xilinx Vivado IP Integrator plus
Xilinx Vitis design. A microblaze soft CPU is instantiated to talk with board components,
a SPI Flash peripheral, and
a 16x2 character LCD peripheral.
Sources to be incorporated into a Xilinx Vitis project contain
a very small FreeRTOS program in C; drivers
for the peripherals, a real-time task to operate the flash chip,
two real-time tasks to display data, and a real-time task to color-mix RGB LEDs.

The folder SF-Tester-Design-VHDL contains a Xilinx Vivado project with sources
containing only VHDL-2002 and VHDL-2008 modules. Plain HDL without a soft CPU or C code is authored to
talk with board components, a N25Q SPI Flash 256Mbit, and a 16x2 character LCD peripheral.

These two groupings of design provide equivalent functionality, excepting that the HDL design provides
a much faster execution.

### Naming conventions notice
The Pmod peripherals used in this project connect via a standard bus technology design called SPI.
The use of MOSI/MISO terminology is considered obsolete. COPI/CIPO is now used. The MOSI signal on a
controller can be replaced with the title 'COPI'. Master and Slave terms are now Controller and Peripheral.
Additional information can be found [here](https://www.oshwa.org/a-resolution-to-redefine-spi-signal-names).
The choice to use COPI and CIPO instead of SDO and SDI for single-direction bus signals is simple.
On a single peripheral bus with two data lines of fixed direction, the usage of the signal name
"SDO" is dependent on whether the Controller or the Peripheral is the chip being discussed;
whereas COPI gives the exact direction regardless of which chip is being discussed. The author
of this website agrees with the open source community that the removal of offensive language from
standard terminology in engineering is a priority.

### Project information document:

./Serial Flash Sector Tester.pdf

[Serial Flash Sector Tester info](https://github.com/timothystotts/fpga-serial-mem-tester-1/blob/master/Serial%20Flash%20Sector%20Tester.pdf)

### Diagrams design document:

./SF-Tester-Design-Documents/SF-Tester-Design-Diagrams.pdf

[Serial Flash Sector Tester Design Diagrams info](https://github.com/timothystotts/fpga-serial-mem-tester-1/blob/master/SF-Tester-Design-Documents/SF-Tester-Design-Diagrams.pdf)

#### Target device assembly: Arty-A7-100T with Pmod SF3, Pmod CLS on extension cable
![Target device assembly](https://github.com/timothystotts/fpga-serial-mem-tester-1/blob/master/SF-Tester-Design-Documents/img_serial-flash-tester-assembled-20200722.jpg)
