// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Fri Nov 27 13:41:29 2020
// Host        : l2study running 64-bit Ubuntu 18.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/timothystotts/Workareas/GitHub/timothystotts/fpga-serial-mem-tester-1/SF-Tester-Design-AXI/IPI-BDs/system/ip/system_PmodSF3_0_13/system_PmodSF3_0_13_stub.v
// Design      : system_PmodSF3_0_13
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100ticsg324-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "PmodSF3,Vivado 2020.2" *)
module system_PmodSF3_0_13(AXI_LITE_araddr, AXI_LITE_arready, 
  AXI_LITE_arvalid, AXI_LITE_awaddr, AXI_LITE_awready, AXI_LITE_awvalid, AXI_LITE_bready, 
  AXI_LITE_bresp, AXI_LITE_bvalid, AXI_LITE_rdata, AXI_LITE_rready, AXI_LITE_rresp, 
  AXI_LITE_rvalid, AXI_LITE_wdata, AXI_LITE_wready, AXI_LITE_wstrb, AXI_LITE_wvalid, 
  Pmod_out_pin10_i, Pmod_out_pin10_o, Pmod_out_pin10_t, Pmod_out_pin1_i, Pmod_out_pin1_o, 
  Pmod_out_pin1_t, Pmod_out_pin2_i, Pmod_out_pin2_o, Pmod_out_pin2_t, Pmod_out_pin3_i, 
  Pmod_out_pin3_o, Pmod_out_pin3_t, Pmod_out_pin4_i, Pmod_out_pin4_o, Pmod_out_pin4_t, 
  Pmod_out_pin7_i, Pmod_out_pin7_o, Pmod_out_pin7_t, Pmod_out_pin8_i, Pmod_out_pin8_o, 
  Pmod_out_pin8_t, Pmod_out_pin9_i, Pmod_out_pin9_o, Pmod_out_pin9_t, QSPI_INTERRUPT, 
  ext_spi_clk, s_axi_aclk, s_axi_aresetn)
/* synthesis syn_black_box black_box_pad_pin="AXI_LITE_araddr[6:0],AXI_LITE_arready,AXI_LITE_arvalid,AXI_LITE_awaddr[6:0],AXI_LITE_awready,AXI_LITE_awvalid,AXI_LITE_bready,AXI_LITE_bresp[1:0],AXI_LITE_bvalid,AXI_LITE_rdata[31:0],AXI_LITE_rready,AXI_LITE_rresp[1:0],AXI_LITE_rvalid,AXI_LITE_wdata[31:0],AXI_LITE_wready,AXI_LITE_wstrb[3:0],AXI_LITE_wvalid,Pmod_out_pin10_i,Pmod_out_pin10_o,Pmod_out_pin10_t,Pmod_out_pin1_i,Pmod_out_pin1_o,Pmod_out_pin1_t,Pmod_out_pin2_i,Pmod_out_pin2_o,Pmod_out_pin2_t,Pmod_out_pin3_i,Pmod_out_pin3_o,Pmod_out_pin3_t,Pmod_out_pin4_i,Pmod_out_pin4_o,Pmod_out_pin4_t,Pmod_out_pin7_i,Pmod_out_pin7_o,Pmod_out_pin7_t,Pmod_out_pin8_i,Pmod_out_pin8_o,Pmod_out_pin8_t,Pmod_out_pin9_i,Pmod_out_pin9_o,Pmod_out_pin9_t,QSPI_INTERRUPT,ext_spi_clk,s_axi_aclk,s_axi_aresetn" */;
  input [6:0]AXI_LITE_araddr;
  output AXI_LITE_arready;
  input AXI_LITE_arvalid;
  input [6:0]AXI_LITE_awaddr;
  output AXI_LITE_awready;
  input AXI_LITE_awvalid;
  input AXI_LITE_bready;
  output [1:0]AXI_LITE_bresp;
  output AXI_LITE_bvalid;
  output [31:0]AXI_LITE_rdata;
  input AXI_LITE_rready;
  output [1:0]AXI_LITE_rresp;
  output AXI_LITE_rvalid;
  input [31:0]AXI_LITE_wdata;
  output AXI_LITE_wready;
  input [3:0]AXI_LITE_wstrb;
  input AXI_LITE_wvalid;
  input Pmod_out_pin10_i;
  output Pmod_out_pin10_o;
  output Pmod_out_pin10_t;
  input Pmod_out_pin1_i;
  output Pmod_out_pin1_o;
  output Pmod_out_pin1_t;
  input Pmod_out_pin2_i;
  output Pmod_out_pin2_o;
  output Pmod_out_pin2_t;
  input Pmod_out_pin3_i;
  output Pmod_out_pin3_o;
  output Pmod_out_pin3_t;
  input Pmod_out_pin4_i;
  output Pmod_out_pin4_o;
  output Pmod_out_pin4_t;
  input Pmod_out_pin7_i;
  output Pmod_out_pin7_o;
  output Pmod_out_pin7_t;
  input Pmod_out_pin8_i;
  output Pmod_out_pin8_o;
  output Pmod_out_pin8_t;
  input Pmod_out_pin9_i;
  output Pmod_out_pin9_o;
  output Pmod_out_pin9_t;
  output QSPI_INTERRUPT;
  input ext_spi_clk;
  input s_axi_aclk;
  input s_axi_aresetn;
endmodule
