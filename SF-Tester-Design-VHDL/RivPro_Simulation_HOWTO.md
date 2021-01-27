# Test-bench simulation setup with Riviera-PRO, HOWTO

# Install the N25Qxxx flash memory model
Extract the N25Qxxx verilog model downloaded from micron.com into
the folder N25Q256A13E_VG12. Several modifications to the source
code are needed.

# Update the time text in the memory model
Edit code/N25Qxxx.v to have text:
	%0t ns]
as:
	%0t ps]
for the reason that the \`timescale directive has time
specification in nanoseconds and time precision in
picoseconds.

The floating-point formatter should also be updated:
	%0f ns]
as:
	%0f ps]

# Update the model choice in the UserData.h include
The include should define `N25Q256A 83E` as the model to
simulate, because the chip indicated by the Digilent Inc.
Pmod SF3 schematic is `N25Q512A 836SF40G`. After asking
on the Digilent forum, the staff engineer indicated that
the schematic is incorrect, and that the part placed on
the Pmod SF3 board is a N25Q256A. The author of this
test-bench thus decided `N25Q256A 83E` may be a fair
simulation of the part actually on the board.

```verilog
//`define N25Q256A13E
`define N25Q256A83E
```

# Update the timing choices in the TimingData.h include
The timing choices in the TimingData.h are not all correctly
matched with the N25Q datasheet; specifically the subsector
erase is much longer than indicated in the datasheet.

To speed-up the Page Program and Subsector Erase delays
by factors of 10 and 1000, the TimingData.h can be modified
as follows:
```verilog
`ifdef N25Q064A13xx4My
    parameter time tPP  = 1e6;
    parameter time tSSE = 60e6;
    parameter time t32SSE = 220e6;
    parameter time tSE  = 460e6;
    parameter time tBE  = 45e9; 
`else
 /* Modified to speed-up operations as a power of 10 divison
    of the timing detailed in N25Q datasheet. */

    parameter time tPP  = 50e3; /* speed-up of 10 */
    parameter time tSSE = 250e3; /* speed-up of 1000 */
    parameter time t32SSE = 250e3; /* speed-up of 1000 */
    parameter time tSE  = 700e3; /* speed-up of 1000 */
    parameter time tBE  = 240e6; /* speed-up of 1000 */ 
`endif   
```

# Commands to compile the Micron memory model in Riviera Pro work area

```tcl
set SRC_DIR ".."

# commands before
set MTI_ALOG_OPTS "-v2k5 -dbg -incdir ${SRC_DIR}/N25Q256A13E_VG12"
# commands after

# commands before
eval alog ${MTI_ALOG_OPTS} -work work ${SRC_DIR}/N25Q256A13E_VG12/code/N25Qxxx.v

eval alog ${MTI_ALOG_OPTS} -work work ${SRC_DIR}/Testbench/N25Qxxx_wrapper.v
# commands after
```
