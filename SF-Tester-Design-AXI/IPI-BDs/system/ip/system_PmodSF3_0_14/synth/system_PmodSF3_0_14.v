// (c) Copyright 1995-2020 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: digilentinc.com:IP:PmodSF3:1.0
// IP Revision: 29

(* X_CORE_INFO = "PmodSF3,Vivado 2020.2" *)
(* CHECK_LICENSE_TYPE = "system_PmodSF3_0_14,PmodSF3,{}" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module system_PmodSF3_0_14 (
  AXI_LITE_araddr,
  AXI_LITE_arready,
  AXI_LITE_arvalid,
  AXI_LITE_awaddr,
  AXI_LITE_awready,
  AXI_LITE_awvalid,
  AXI_LITE_bready,
  AXI_LITE_bresp,
  AXI_LITE_bvalid,
  AXI_LITE_rdata,
  AXI_LITE_rready,
  AXI_LITE_rresp,
  AXI_LITE_rvalid,
  AXI_LITE_wdata,
  AXI_LITE_wready,
  AXI_LITE_wstrb,
  AXI_LITE_wvalid,
  Pmod_out_pin10_i,
  Pmod_out_pin10_o,
  Pmod_out_pin10_t,
  Pmod_out_pin1_i,
  Pmod_out_pin1_o,
  Pmod_out_pin1_t,
  Pmod_out_pin2_i,
  Pmod_out_pin2_o,
  Pmod_out_pin2_t,
  Pmod_out_pin3_i,
  Pmod_out_pin3_o,
  Pmod_out_pin3_t,
  Pmod_out_pin4_i,
  Pmod_out_pin4_o,
  Pmod_out_pin4_t,
  Pmod_out_pin7_i,
  Pmod_out_pin7_o,
  Pmod_out_pin7_t,
  Pmod_out_pin8_i,
  Pmod_out_pin8_o,
  Pmod_out_pin8_t,
  Pmod_out_pin9_i,
  Pmod_out_pin9_o,
  Pmod_out_pin9_t,
  QSPI_INTERRUPT,
  ext_spi_clk,
  s_axi_aclk,
  s_axi_aresetn
);

(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE ARADDR" *)
input wire [6 : 0] AXI_LITE_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE ARREADY" *)
output wire AXI_LITE_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE ARVALID" *)
input wire AXI_LITE_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE AWADDR" *)
input wire [6 : 0] AXI_LITE_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE AWREADY" *)
output wire AXI_LITE_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE AWVALID" *)
input wire AXI_LITE_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE BREADY" *)
input wire AXI_LITE_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE BRESP" *)
output wire [1 : 0] AXI_LITE_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE BVALID" *)
output wire AXI_LITE_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE RDATA" *)
output wire [31 : 0] AXI_LITE_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE RREADY" *)
input wire AXI_LITE_rready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE RRESP" *)
output wire [1 : 0] AXI_LITE_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE RVALID" *)
output wire AXI_LITE_rvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE WDATA" *)
input wire [31 : 0] AXI_LITE_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE WREADY" *)
output wire AXI_LITE_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE WSTRB" *)
input wire [3 : 0] AXI_LITE_wstrb;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME AXI_LITE, DATA_WIDTH 32, PROTOCOL AXI4LITE, ID_WIDTH 0, ADDR_WIDTH 16, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, FREQ_HZ 83333333, PHASE 0, CLK_DOMAIN system_mig_7series_0_0_ui_clk, NUM_READ_THREADS 1, NUM_WRITE\
_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 AXI_LITE WVALID" *)
input wire AXI_LITE_wvalid;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN10_I" *)
input wire Pmod_out_pin10_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN10_O" *)
output wire Pmod_out_pin10_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN10_T" *)
output wire Pmod_out_pin10_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN1_I" *)
input wire Pmod_out_pin1_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN1_O" *)
output wire Pmod_out_pin1_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN1_T" *)
output wire Pmod_out_pin1_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN2_I" *)
input wire Pmod_out_pin2_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN2_O" *)
output wire Pmod_out_pin2_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN2_T" *)
output wire Pmod_out_pin2_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN3_I" *)
input wire Pmod_out_pin3_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN3_O" *)
output wire Pmod_out_pin3_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN3_T" *)
output wire Pmod_out_pin3_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN4_I" *)
input wire Pmod_out_pin4_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN4_O" *)
output wire Pmod_out_pin4_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN4_T" *)
output wire Pmod_out_pin4_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN7_I" *)
input wire Pmod_out_pin7_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN7_O" *)
output wire Pmod_out_pin7_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN7_T" *)
output wire Pmod_out_pin7_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN8_I" *)
input wire Pmod_out_pin8_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN8_O" *)
output wire Pmod_out_pin8_o;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN8_T" *)
output wire Pmod_out_pin8_t;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN9_I" *)
input wire Pmod_out_pin9_i;
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN9_O" *)
output wire Pmod_out_pin9_o;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME Pmod_out, BUSIF.BOARD_INTERFACE Custom, BOARD.ASSOCIATED_PARAM PMOD" *)
(* X_INTERFACE_INFO = "digilentinc.com:interface:pmod:1.0 Pmod_out PIN9_T" *)
output wire Pmod_out_pin9_t;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME INTR.QSPI_INTERRUPT, SENSITIVITY LEVEL_HIGH, PortWidth 1, XIL_INTERFACENAME QSPI_INTERRUPT, SENSITIVITY LEVEL_HIGH, PortWidth 1" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 INTR.QSPI_INTERRUPT INTERRUPT, xilinx.com:signal:interrupt:1.0 QSPI_INTERRUPT INTERRUPT" *)
output wire QSPI_INTERRUPT;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.EXT_SPI_CLK, ASSOCIATED_BUSIF Pmod_out, FREQ_HZ 50000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN /clk_wiz_0_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.EXT_SPI_CLK CLK" *)
input wire ext_spi_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.S_AXI_ACLK, ASSOCIATED_BUSIF AXI_LITE, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 83333333, FREQ_TOLERANCE_HZ 0, PHASE 0, CLK_DOMAIN system_mig_7series_0_0_ui_clk, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.S_AXI_ACLK CLK" *)
input wire s_axi_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.S_AXI_ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.S_AXI_ARESETN RST" *)
input wire s_axi_aresetn;

  PmodSF3 inst (
    .AXI_LITE_araddr(AXI_LITE_araddr),
    .AXI_LITE_arready(AXI_LITE_arready),
    .AXI_LITE_arvalid(AXI_LITE_arvalid),
    .AXI_LITE_awaddr(AXI_LITE_awaddr),
    .AXI_LITE_awready(AXI_LITE_awready),
    .AXI_LITE_awvalid(AXI_LITE_awvalid),
    .AXI_LITE_bready(AXI_LITE_bready),
    .AXI_LITE_bresp(AXI_LITE_bresp),
    .AXI_LITE_bvalid(AXI_LITE_bvalid),
    .AXI_LITE_rdata(AXI_LITE_rdata),
    .AXI_LITE_rready(AXI_LITE_rready),
    .AXI_LITE_rresp(AXI_LITE_rresp),
    .AXI_LITE_rvalid(AXI_LITE_rvalid),
    .AXI_LITE_wdata(AXI_LITE_wdata),
    .AXI_LITE_wready(AXI_LITE_wready),
    .AXI_LITE_wstrb(AXI_LITE_wstrb),
    .AXI_LITE_wvalid(AXI_LITE_wvalid),
    .Pmod_out_pin10_i(Pmod_out_pin10_i),
    .Pmod_out_pin10_o(Pmod_out_pin10_o),
    .Pmod_out_pin10_t(Pmod_out_pin10_t),
    .Pmod_out_pin1_i(Pmod_out_pin1_i),
    .Pmod_out_pin1_o(Pmod_out_pin1_o),
    .Pmod_out_pin1_t(Pmod_out_pin1_t),
    .Pmod_out_pin2_i(Pmod_out_pin2_i),
    .Pmod_out_pin2_o(Pmod_out_pin2_o),
    .Pmod_out_pin2_t(Pmod_out_pin2_t),
    .Pmod_out_pin3_i(Pmod_out_pin3_i),
    .Pmod_out_pin3_o(Pmod_out_pin3_o),
    .Pmod_out_pin3_t(Pmod_out_pin3_t),
    .Pmod_out_pin4_i(Pmod_out_pin4_i),
    .Pmod_out_pin4_o(Pmod_out_pin4_o),
    .Pmod_out_pin4_t(Pmod_out_pin4_t),
    .Pmod_out_pin7_i(Pmod_out_pin7_i),
    .Pmod_out_pin7_o(Pmod_out_pin7_o),
    .Pmod_out_pin7_t(Pmod_out_pin7_t),
    .Pmod_out_pin8_i(Pmod_out_pin8_i),
    .Pmod_out_pin8_o(Pmod_out_pin8_o),
    .Pmod_out_pin8_t(Pmod_out_pin8_t),
    .Pmod_out_pin9_i(Pmod_out_pin9_i),
    .Pmod_out_pin9_o(Pmod_out_pin9_o),
    .Pmod_out_pin9_t(Pmod_out_pin9_t),
    .QSPI_INTERRUPT(QSPI_INTERRUPT),
    .ext_spi_clk(ext_spi_clk),
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn)
  );
endmodule
