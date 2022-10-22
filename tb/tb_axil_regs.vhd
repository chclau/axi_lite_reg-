----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 21.10.2022 
-- Module Name: tb_axil_regs.vhd
-- Description: testbench for AXI Lite registers
--
-- Dependencies: axil_regs.vhd
-- 
-- Revision: 1
-- Revision  1 - Initial version
-- 
----------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_axil_regs is
end entity;

architecture test of tb_axil_regs is

  constant PERIOD : time := 20 ns;
  constant C_ADDR_W : natural := 8;
  constant C_DATA_W : natural := 32;

  signal clk : std_logic := '0';
  signal rstn : std_logic := '0';
  signal data : std_logic_vector(C_DATA_W-1 downto 0);    
  signal endSim : boolean := false;
  
  signal addr	  : std_logic_vector(C_ADDR_W-1 downto 0);
  signal awaddr	  : std_logic_vector(C_ADDR_W-1 downto 0);
	signal awvalid	: std_logic;
	signal awready	: std_logic;
	signal wdata	  : std_logic_vector(C_DATA_W-1 downto 0);
	signal wvalid	  : std_logic;
	signal wready	  : std_logic;
	signal bresp	  : std_logic_vector(1 downto 0);
	signal bvalid	  : std_logic;
	signal bready	  : std_logic;
	signal araddr	  : std_logic_vector(C_ADDR_W-1 downto 0);
	signal arvalid	: std_logic;
	signal arready	: std_logic;
	signal rdata	  : std_logic_vector(C_DATA_W-1 downto 0);
	signal rresp	  : std_logic_vector(1 downto 0);
	signal rvalid	  : std_logic;
	signal rready	  : std_logic;
  
  
  component axil_regs is
    generic (
      C_DATA_W	: integer	:= 32;
      C_ADDR_W	: integer	:= 8
    );
    port (
      s_axi_aclk	: in std_logic;
      s_axi_aresetn	: in std_logic;
      s_axi_awaddr	: in std_logic_vector(C_ADDR_W-1 downto 0);
      s_axi_awvalid	: in std_logic;
      s_axi_awready	: out std_logic;
      s_axi_wdata	  : in std_logic_vector(C_DATA_W-1 downto 0);
      s_axi_wvalid	: in std_logic;
      s_axi_wready	: out std_logic;
      s_axi_bresp	  : out std_logic_vector(1 downto 0);
      s_axi_bvalid	: out std_logic;
      s_axi_bready	: in std_logic;
      s_axi_araddr	: in std_logic_vector(C_ADDR_W-1 downto 0);
      s_axi_arvalid	: in std_logic;
      s_axi_arready	: out std_logic;
      s_axi_rdata	  : out std_logic_vector(C_DATA_W-1 downto 0);
      s_axi_rresp	  : out std_logic_vector(1 downto 0);
      s_axi_rvalid	: out std_logic;
      s_axi_rready	: in std_logic
    );
  end component;

  
  procedure readAxil (
    signal clk    : in  std_logic;
    constant addr : in  std_logic_vector(C_ADDR_W-1 downto 0);
    constant len  : in  integer;
    signal data   : out std_logic_vector(C_DATA_W-1 downto 0);
    signal araddr : out std_logic_vector(C_ADDR_W-1 downto 0);
    signal arvalid : out std_logic;
    signal arready : in  std_logic;
    
    signal rdata  : in std_logic_vector(C_DATA_W-1 downto 0);
    signal rready : out std_logic;
    signal rvalid : in  std_logic
    
  ) is

  begin
    arvalid <= '0';
    rready  <= '0';
    wait until (rising_edge(clk));
    arvalid <= '1';
    araddr  <= addr;
    wait until (rising_edge(clk));
    while (arready = '0') loop
      wait until (rising_edge(clk));
    end loop;
    arvalid <= '0';
    wait until (rising_edge(clk));
    while (rvalid = '0') loop
      wait until (rising_edge(clk));
    end loop;
    for i in 0 to len loop
      wait until (rising_edge(clk));
    end loop;
    if (rvalid = '1') then
      rready <= '1';
      wait until (rising_edge(clk));
    end if;
    rready <= '0';
  end procedure;
    
  procedure writeAxil (
    signal clk    : in  std_logic;
    constant addr : in  std_logic_vector(C_ADDR_W-1 downto 0);
    constant data : in  std_logic_vector(C_DATA_W-1 downto 0);
    constant len1 : in  integer;
    constant len2 : in  integer;
    signal awaddr  : out std_logic_vector(C_ADDR_W-1 downto 0);
    signal awvalid : out std_logic;
    signal awready : in  std_logic;
    
    signal wdata  : out std_logic_vector(C_DATA_W-1 downto 0);
    signal wready : in std_logic;
    signal wvalid : out std_logic;
    
    signal bvalid : in  std_logic;
    signal bready : out std_logic
    
  ) is

  begin
    awvalid <= '0';
    wvalid  <= '0';
    bready  <= '0';
    wait until (rising_edge(clk));
    awvalid <= '1';
    awaddr  <= addr;
    wdata   <= data;
    
    if (len1 = 0) then
      wvalid <= '1';
    end if;
    wait until (rising_edge(clk));
    
    if (len1 = 0) then
      while (arready = '0' and wready = '0') loop
        wait until (rising_edge(clk));
      end loop;
      awvalid <= '0';
      wvalid <= '0';
    else
      while (arready = '0') loop
        wait until (rising_edge(clk));
      end loop;
      awvalid <= '0';

      for i in 0 to len1 loop
        wait until (rising_edge(clk));
      end loop;
      wvalid <= '1';
      wait until (rising_edge(clk));
      while (wready = '0') loop
        wait until (rising_edge(clk));
      end loop;
      wvalid <= '0';
    end if;
    
    for i in 0 to len2 loop
      wait until (rising_edge(clk));
    end loop;
    if (bvalid = '1') then
      bready <= '1';
      wait until (rising_edge(clk));
    end if;
    bready <= '0';
  end procedure;
  
begin
  clk  <= not clk after PERIOD/2;
  rstn <= '1' after PERIOD * 10;
  
  -- Main simulation process
  process

  begin
    wait until (rstn = '1');
    wait until (rising_edge(clk));
    
    addr <= x"00";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 3, data, araddr, arvalid, arready, rdata, rready, rvalid);  
    wait until (rising_edge(clk));
    
    addr <= x"08";
    data <= x"12345678";
    wait until (rising_edge(clk));
    writeAxil (clk, addr, data, 1, 1, awaddr, awvalid, awready, wdata, wready, wvalid, bvalid, bready);  
    wait until (rising_edge(clk));
    
    addr <= x"10";
    data <= x"56784321";
    wait until (rising_edge(clk));
    writeAxil (clk, addr, data, 0, 1, awaddr, awvalid, awready, wdata, wready, wvalid, bvalid, bready);  
    wait until (rising_edge(clk));
    
    addr <= x"04";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 2, data, araddr, arvalid, arready, rdata, rready, rvalid); 
    
    addr <= x"08";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 4, data, araddr, arvalid, arready, rdata, rready, rvalid); 
    
    -- Check read timeout
    addr <= x"00";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 18, data, araddr, arvalid, arready, rdata, rready, rvalid); 

    addr <= x"10";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 2, data, araddr, arvalid, arready, rdata, rready, rvalid); 
    
    addr <= x"0c";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 1, data, araddr, arvalid, arready, rdata, rready, rvalid); 
    
    addr <= x"18";
    wait until (rising_edge(clk));
    readAxil (clk, addr, 4, data, araddr, arvalid, arready, rdata, rready, rvalid);  
    
    endSim <= true;
  end process;

  -- End the simulation
  process
  begin
    if (endSim) then
      assert false
      report "End of simulation."
        severity failure;
    end if;
    wait until (rising_edge(clk));
  end process;

  axil_regs_i : axil_regs
    generic map (
        C_DATA_W => C_DATA_W,
        C_ADDR_W => C_ADDR_W
    )
    port map ( 
      s_axi_aclk	  => clk	          ,
      s_axi_aresetn	=> rstn	          ,
      s_axi_awaddr	=> awaddr	        ,
      s_axi_awvalid	=> awvalid	      ,
      s_axi_awready	=> awready	      ,
      s_axi_wdata	  => wdata	        ,
      s_axi_wvalid	=> wvalid	        ,
      s_axi_wready	=> wready	        ,
      s_axi_bresp	  => bresp	        ,
      s_axi_bvalid	=> bvalid	        ,
      s_axi_bready	=> bready	        ,
      s_axi_araddr	=> araddr	        ,
      s_axi_arvalid	=> arvalid	      ,
      s_axi_arready	=> arready	      ,
      s_axi_rdata	  => rdata	        ,
      s_axi_rresp	  => rresp	        ,
      s_axi_rvalid	=> rvalid	        ,
      s_axi_rready	=> rready	        
    );              
end architecture;