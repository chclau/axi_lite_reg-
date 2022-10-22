----------------------------------------------------------------------------------
-- Company:  FPGA'er
-- Engineer: Claudio Avi Chami - FPGA'er Website
--           http://fpgaer.tech
-- Create Date: 21.10.2022 
-- Module Name: axil_regs.vhd
-- Description: AXI Lite registers bank
--
-- Dependencies: none
-- 
-- Revision: 2
-- Revision  1 - Initial version
--           2 - Completely new version. Previous one was based on faulty code from Xilinx. 
--                This version was written from scratch
----------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_regs is
  generic (
    C_DATA_W : integer := 32;
    C_ADDR_W : integer := 32
  );
  port (
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;
    s_axi_awaddr  : in  std_logic_vector(C_ADDR_W - 1 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in  std_logic_vector(C_DATA_W - 1 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_araddr  : in  std_logic_vector(C_ADDR_W - 1 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(C_DATA_W - 1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic
  );
end axil_regs;

architecture arch_imp of axil_regs is

  -- AXI4LITE signals
  signal axi_awaddr : std_logic_vector(C_ADDR_W - 1 downto 0);
  signal axi_awready : std_logic;
  signal axi_bresp : std_logic_vector(1 downto 0);
  signal axi_bvalid : std_logic;
  signal axi_araddr : std_logic_vector(C_ADDR_W - 1 downto 0);
  signal axi_arready : std_logic;
  signal axi_rdata : std_logic_vector(C_DATA_W - 1 downto 0);
  signal axi_rvalid : std_logic;

  ---------------------------------------------
  ---- Signals for user logic register space
  ---------------------------------------------
  ---- Number of Slave Registers 16
  constant VER_ADDR : std_logic_vector(C_ADDR_W - 1 downto 0) := x"00";
  constant DATE_ADDR : std_logic_vector(C_ADDR_W - 1 downto 0) := x"04";
  constant SCRPAD_ADDR : std_logic_vector(C_ADDR_W - 1 downto 0) := x"08";
  constant PWM_FREQ_DIV_ADDR : std_logic_vector(C_ADDR_W - 1 downto 0) := x"0C";
  constant PWM_DUTY_ADDR : std_logic_vector(C_ADDR_W - 1 downto 0) := x"10";
  signal reg_version : std_logic_vector(C_DATA_W - 1 downto 0) := x"0000_0001";
  signal reg_date : std_logic_vector(C_DATA_W - 1 downto 0) := x"2110_0922";
  signal reg_scratchpad : std_logic_vector(C_DATA_W - 1 downto 0);
  signal reg_pwm_freq_div : std_logic_vector(7 downto 0);
  signal reg_pwm_duty : std_logic_vector(7 downto 0);
  signal reg_data_out : std_logic_vector(C_DATA_W - 1 downto 0);

  constant REGS_TIMEOUT : integer range 0 to 15 := 15;

  signal timeout_rd : integer range 0 to REGS_TIMEOUT;
  signal timeout_wr : integer range 0 to REGS_TIMEOUT;
  signal waddr_strb : std_logic;
  signal bresp_strb : std_logic;
  signal wr_en : std_logic;
  signal raddr_strb : std_logic;
  signal rdata_strb : std_logic;

  type rd_sm is (idle, start_rd, rd_data);
  signal rd_st : rd_sm;
  type wr_sm is (idle, wr_data, wr_resp);
  signal wr_st : wr_sm;

begin

  -- I/O Connections assignments
  s_axi_awready <= axi_awready;
  s_axi_bresp <= axi_bresp;
  s_axi_bvalid <= axi_bvalid;
  s_axi_arready <= axi_arready;
  s_axi_rdata <= axi_rdata;
  s_axi_rvalid <= axi_rvalid;

  -------------------------------------------------------------------
  --   Registers write section

  waddr_strb <= s_axi_awvalid and axi_awready;
  bresp_strb <= s_axi_bready and axi_bvalid;
  s_axi_wready <= '1';

  -- write registers state machine for control
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_awready <= '1';
        axi_bvalid <= '0';
        wr_en <= '0';
        wr_st <= idle;
      else
        case wr_st is
          when idle =>
            if (waddr_strb = '1') then
              axi_awaddr <= s_axi_araddr; -- store write address
              axi_awready <= '0'; -- address received, stop receiving additional addresses
              axi_bvalid <= '0';

              -- Check if waddr and wdata were sent on same clock
              if (s_axi_wvalid = '1') then
                axi_bvalid <= '1';
                timeout_wr <= REGS_TIMEOUT - 1; -- load timeout for bresp phase
                wr_en <= '1';
                wr_st <= wr_resp;
              else
                timeout_wr <= REGS_TIMEOUT - 1; -- load timeout for write data phase
                wr_en <= '1';
                wr_st <= wr_data;
              end if;
            end if;
          when wr_data =>
            if (s_axi_wvalid = '1') then
              axi_bvalid <= '1';
              timeout_wr <= REGS_TIMEOUT - 1; -- load timeout for bresp phase
              wr_en <= '1';
              wr_st <= wr_resp;
            elsif (timeout_wr = 0) then
              axi_awready <= '1'; -- write timeout, address bus is ready for new addr
              wr_st <= idle;
            else
              timeout_wr <= timeout_wr - 1;
            end if;
          when wr_resp =>
            wr_en <= '0';
            axi_bvalid <= '1';
            if (bresp_strb = '1' or timeout_wr = 0) then
              axi_bvalid <= '0';
              axi_awready <= '1'; -- data received (or timeout), address bus is ready for new addr
              wr_st <= idle;
            elsif (timeout_wr > 0) then
              timeout_wr <= timeout_wr - 1;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Implement memory mapped register select for write accesses 
  process (s_axi_aclk)
    variable loc_addr : std_logic_vector(C_ADDR_W - 1 downto 0);
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        reg_scratchpad <= (others => '0');
        reg_pwm_freq_div <= (others => '0');
        reg_pwm_duty <= (others => '0');
      else
        loc_addr := s_axi_awaddr;
        if (wr_en = '1') then
          case loc_addr is
            when SCRPAD_ADDR =>
              axi_bresp <= "00";
              reg_scratchpad <= s_axi_wdata;
            when PWM_FREQ_DIV_ADDR =>
              axi_bresp <= "00";
              reg_pwm_freq_div <= s_axi_wdata(7 downto 0);
            when PWM_DUTY_ADDR =>
              axi_bresp <= "00";
              reg_pwm_duty <= s_axi_wdata(7 downto 0);
            when others =>
              axi_bresp <= "10"; -- slave decoder error, register is read/only or does not exist
          end case;
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------
  --   Registers read section 

  raddr_strb <= s_axi_arvalid and axi_arready;
  rdata_strb <= s_axi_rready and axi_rvalid;

  -- Read registers state machine for control
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_arready <= '1';
        axi_rvalid <= '0';
        rd_st <= idle;
      else
        case rd_st is
          when idle =>
            if (raddr_strb = '1') then
              axi_araddr <= s_axi_araddr; -- store read address
              axi_arready <= '0'; -- address received, stop receiving additional addresses
              axi_rvalid <= '0';
              rd_st <= start_rd;
            end if;
          when start_rd =>
            axi_rvalid <= '1';
            timeout_rd <= REGS_TIMEOUT - 1;
            rd_st <= rd_data;
          when rd_data =>
            if (rdata_strb = '1' or timeout_rd = 0) then
              axi_rvalid <= '0';
              axi_arready <= '1'; -- data received (or timeout), address bus is ready for new addr
              rd_st <= idle;
            else
              timeout_rd <= timeout_rd - 1;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- Read registers data
  process (s_axi_aclk) is
    variable loc_addr : std_logic_vector(C_ADDR_W - 1 downto 0);
  begin
    if (rising_edge (s_axi_aclk)) then
      -- Address decoding for registers read
      loc_addr := axi_araddr;

      -- Default values for rdata and rresp
      axi_rdata <= (others => '0');
      s_axi_rresp <= "00";

      case loc_addr is
        when VER_ADDR =>
          axi_rdata <= reg_version;
        when DATE_ADDR =>
          axi_rdata <= reg_date;
        when SCRPAD_ADDR =>
          axi_rdata <= reg_scratchpad;
        when PWM_FREQ_DIV_ADDR =>
          axi_rdata(7 downto 0) <= reg_pwm_freq_div;
        when PWM_DUTY_ADDR =>
          axi_rdata(7 downto 0) <= reg_pwm_duty;
        when others =>
          s_axi_rresp <= "10"; -- slave decode error, read register does not exist
      end case;
    end if;
  end process;

end arch_imp;