-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
-- Date        : Mon Jul 27 12:43:08 2020
-- Host        : J1STUDY running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               w:/wa/fpga-serial-mem-tester-1/SF-Tester-Design-AXI/IPI-BDs/system/ip/system_PmodSF3_0_10/system_PmodSF3_0_10_stub.vhdl
-- Design      : system_PmodSF3_0_10
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100ticsg324-1L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity system_PmodSF3_0_10 is
  Port ( 
    AXI_LITE_araddr : in STD_LOGIC_VECTOR ( 6 downto 0 );
    AXI_LITE_arready : out STD_LOGIC;
    AXI_LITE_arvalid : in STD_LOGIC;
    AXI_LITE_awaddr : in STD_LOGIC_VECTOR ( 6 downto 0 );
    AXI_LITE_awready : out STD_LOGIC;
    AXI_LITE_awvalid : in STD_LOGIC;
    AXI_LITE_bready : in STD_LOGIC;
    AXI_LITE_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI_LITE_bvalid : out STD_LOGIC;
    AXI_LITE_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_LITE_rready : in STD_LOGIC;
    AXI_LITE_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI_LITE_rvalid : out STD_LOGIC;
    AXI_LITE_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_LITE_wready : out STD_LOGIC;
    AXI_LITE_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI_LITE_wvalid : in STD_LOGIC;
    Pmod_out_pin10_i : in STD_LOGIC;
    Pmod_out_pin10_o : out STD_LOGIC;
    Pmod_out_pin10_t : out STD_LOGIC;
    Pmod_out_pin1_i : in STD_LOGIC;
    Pmod_out_pin1_o : out STD_LOGIC;
    Pmod_out_pin1_t : out STD_LOGIC;
    Pmod_out_pin2_i : in STD_LOGIC;
    Pmod_out_pin2_o : out STD_LOGIC;
    Pmod_out_pin2_t : out STD_LOGIC;
    Pmod_out_pin3_i : in STD_LOGIC;
    Pmod_out_pin3_o : out STD_LOGIC;
    Pmod_out_pin3_t : out STD_LOGIC;
    Pmod_out_pin4_i : in STD_LOGIC;
    Pmod_out_pin4_o : out STD_LOGIC;
    Pmod_out_pin4_t : out STD_LOGIC;
    Pmod_out_pin7_i : in STD_LOGIC;
    Pmod_out_pin7_o : out STD_LOGIC;
    Pmod_out_pin7_t : out STD_LOGIC;
    Pmod_out_pin8_i : in STD_LOGIC;
    Pmod_out_pin8_o : out STD_LOGIC;
    Pmod_out_pin8_t : out STD_LOGIC;
    Pmod_out_pin9_i : in STD_LOGIC;
    Pmod_out_pin9_o : out STD_LOGIC;
    Pmod_out_pin9_t : out STD_LOGIC;
    QSPI_INTERRUPT : out STD_LOGIC;
    ext_spi_clk : in STD_LOGIC;
    s_axi_aclk : in STD_LOGIC;
    s_axi_aresetn : in STD_LOGIC
  );

end system_PmodSF3_0_10;

architecture stub of system_PmodSF3_0_10 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "AXI_LITE_araddr[6:0],AXI_LITE_arready,AXI_LITE_arvalid,AXI_LITE_awaddr[6:0],AXI_LITE_awready,AXI_LITE_awvalid,AXI_LITE_bready,AXI_LITE_bresp[1:0],AXI_LITE_bvalid,AXI_LITE_rdata[31:0],AXI_LITE_rready,AXI_LITE_rresp[1:0],AXI_LITE_rvalid,AXI_LITE_wdata[31:0],AXI_LITE_wready,AXI_LITE_wstrb[3:0],AXI_LITE_wvalid,Pmod_out_pin10_i,Pmod_out_pin10_o,Pmod_out_pin10_t,Pmod_out_pin1_i,Pmod_out_pin1_o,Pmod_out_pin1_t,Pmod_out_pin2_i,Pmod_out_pin2_o,Pmod_out_pin2_t,Pmod_out_pin3_i,Pmod_out_pin3_o,Pmod_out_pin3_t,Pmod_out_pin4_i,Pmod_out_pin4_o,Pmod_out_pin4_t,Pmod_out_pin7_i,Pmod_out_pin7_o,Pmod_out_pin7_t,Pmod_out_pin8_i,Pmod_out_pin8_o,Pmod_out_pin8_t,Pmod_out_pin9_i,Pmod_out_pin9_o,Pmod_out_pin9_t,QSPI_INTERRUPT,ext_spi_clk,s_axi_aclk,s_axi_aresetn";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "PmodSF3,Vivado 2020.1";
begin
end;
