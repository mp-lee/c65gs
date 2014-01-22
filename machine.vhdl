----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:30:37 12/10/2013 
-- Design Name: 
-- Module Name:    container - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use Std.TextIO.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity machine is
  Port ( pixelclock : STD_LOGIC;
         btnCpuReset : in  STD_LOGIC;
         irq : in  STD_LOGIC;
         nmi : in  STD_LOGIC;

         ----------------------------------------------------------------------
         -- VGA output
         ----------------------------------------------------------------------
         vsync : out  STD_LOGIC;
         hsync : out  STD_LOGIC;
         vgared : out  UNSIGNED (3 downto 0);
         vgagreen : out  UNSIGNED (3 downto 0);
         vgablue : out  UNSIGNED (3 downto 0);

         ----------------------------------------------------------------------
         -- PS/2 adapted USB keyboard & joystick connector.
         -- For now we will use a keyrah adapter to connect to the keyboard.
         ----------------------------------------------------------------------
         ps2data : in std_logic;
         ps2clock : in std_logic;
         
         ----------------------------------------------------------------------
         -- Debug interfaces on Nexys4 board
         ----------------------------------------------------------------------
         led0 : out std_logic;
         led1 : out std_logic;
         led2 : out std_logic;
         led3 : out std_logic;
         sw : in std_logic_vector(15 downto 0);
         btn : in std_logic_vector(4 downto 0);

         UART_TXD : out std_logic;
         RsRx : in std_logic;
         
         sseg_ca : out std_logic_vector(7 downto 0);
         sseg_an : out std_logic_vector(7 downto 0)
         );
end machine;

architecture Behavioral of machine is

  component uart_monitor
    port (
      reset : in std_logic;
      clock : in std_logic;
      tx : out std_logic;
      rx : in  std_logic;
      activity : out std_logic;

      monitor_pc : in std_logic_vector(15 downto 0);
      monitor_opcode : in std_logic_vector(7 downto 0);
      monitor_a : in std_logic_vector(7 downto 0);
      monitor_x : in std_logic_vector(7 downto 0);
      monitor_y : in std_logic_vector(7 downto 0);
      monitor_sp : in std_logic_vector(7 downto 0);
      monitor_p : in std_logic_vector(7 downto 0);

      monitor_mem_address : out std_logic_vector(27 downto 0);
      monitor_mem_rdata : in unsigned(7 downto 0);
      monitor_mem_wdata : out unsigned(7 downto 0);
      monitor_mem_register : in unsigned(15 downto 0);
      monitor_mem_read : out std_logic := '0';
      monitor_mem_write : out std_logic := '0';
      monitor_mem_setpc : out std_logic := '0';
      monitor_mem_trace_mode : out std_logic;
      monitor_mem_stage_trace_mode : out std_logic;
      monitor_mem_trace_toggle : out std_logic;
      monitor_mem_attention_request : out std_logic;
      monitor_mem_attention_granted : in std_logic
      );
  end component;

  component simple6502
    port (
      Clock : in std_logic;
      reset : in std_logic;
      irq : in std_logic;
      nmi : in std_logic;
      monitor_pc : out std_logic_vector(15 downto 0);
      monitor_opcode : out std_logic_vector(7 downto 0);
      monitor_a : out std_logic_vector(7 downto 0);
      monitor_x : out std_logic_vector(7 downto 0);
      monitor_y : out std_logic_vector(7 downto 0);
      monitor_sp : out std_logic_vector(7 downto 0);
      monitor_p : out std_logic_vector(7 downto 0);
      monitor_state : out std_logic_vector(7 downto 0);

      ---------------------------------------------------------------------------
      -- Memory access interface used by monitor
      ---------------------------------------------------------------------------
      monitor_mem_address : in std_logic_vector(27 downto 0);
      monitor_mem_rdata : out unsigned(7 downto 0);
      monitor_mem_wdata : in unsigned(7 downto 0);
      monitor_mem_register : out unsigned(15 downto 0);
      monitor_mem_read : in std_logic;
      monitor_mem_write : in std_logic;
      monitor_mem_setpc : in std_logic;
      monitor_mem_attention_request : in std_logic;
      monitor_mem_attention_granted : out std_logic;
      monitor_mem_trace_mode : in std_logic;
      monitor_mem_stage_trace_mode : in std_logic;
      monitor_mem_trace_toggle : in std_logic;

      ---------------------------------------------------------------------------
      -- Interface to FastRAM in video controller (just 128KB for now)
      ---------------------------------------------------------------------------
      fastram_we : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      fastram_read : OUT STD_LOGIC;
      fastram_write : OUT STD_LOGIC;
      fastram_address : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
      fastram_datain : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      fastram_dataout : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      
      ---------------------------------------------------------------------------
      -- fast IO port (clocked at core clock). 1MB address space
      ---------------------------------------------------------------------------
      fastio_addr : inout std_logic_vector(19 downto 0);
      fastio_read : inout std_logic;
      fastio_write : out std_logic;
      fastio_wdata : out std_logic_vector(7 downto 0);
      fastio_rdata : inout std_logic_vector(7 downto 0)
      );
  end component;
  
  component vga is
    Port (
      ----------------------------------------------------------------------
      -- 100MHz Nexys4 master clock from which we drive the dotclock
      ----------------------------------------------------------------------
      pixelclock : in  STD_LOGIC;
      cpuclock : in std_logic;

      ----------------------------------------------------------------------
      -- VGA output
      ----------------------------------------------------------------------
      vsync : out  STD_LOGIC;
      hsync : out  STD_LOGIC;
      vgared : out  UNSIGNED (3 downto 0);
      vgagreen : out  UNSIGNED (3 downto 0);
      vgablue : out  UNSIGNED (3 downto 0);

      ---------------------------------------------------------------------------
      -- CPU Interface to FastRAM in video controller (just 128KB for now)
      ---------------------------------------------------------------------------
      fastram_we : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      fastram_read : IN STD_LOGIC;
      fastram_write : IN STD_LOGIC;
      fastram_address : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      fastram_datain : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      fastram_dataout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      
      -----------------------------------------------------------------------------
      -- FastIO interface for accessing video registers
      -----------------------------------------------------------------------------
      fastio_addr : in std_logic_vector(19 downto 0);
      fastio_read : in std_logic;
      fastio_write : in std_logic;
      fastio_wdata : in std_logic_vector(7 downto 0);
      fastio_rdata : out std_logic_vector(7 downto 0);

      colourram_at_dc00 : out std_logic
      );
  end component;
  
  component iomapper is
    port (Clk : in std_logic;
          reset : in std_logic;
          irq : out std_logic;
          nmi : out std_logic;
          address : in std_logic_vector(19 downto 0);
          r : in std_logic;
          w : in std_logic;
          data_i : in std_logic_vector(7 downto 0);
          data_o : out std_logic_vector(7 downto 0);
          colourram_at_dc00 : in std_logic;

          ps2data : in std_logic;
          ps2clock : in std_logic;
          last_scan_code : out unsigned(11 downto 0)
          );
  end component;

  signal last_scan_code : unsigned(11 downto 0):=x"FFF";
  
  signal io_irq : std_logic;
  signal io_nmi : std_logic;
  signal combinedirq : std_logic;
  signal combinednmi : std_logic;

  signal fastio_addr : std_logic_vector(19 downto 0);
  signal fastio_read : std_logic;
  signal fastio_write : std_logic;
  signal fastio_wdata : std_logic_vector(7 downto 0);
  signal fastio_rdata : std_logic_vector(7 downto 0);

  signal fastram_we : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal fastram_read : STD_LOGIC;
  signal fastram_write : STD_LOGIC;
  signal fastram_address : STD_LOGIC_VECTOR(13 DOWNTO 0);
  signal fastram_datain : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal fastram_dataout : STD_LOGIC_VECTOR(63 DOWNTO 0);

  signal vga_fastramaddress : std_logic_vector(13 downto 0);
  signal vga_fastramdata : std_logic_vector(63 downto 0);
  
  signal cpuclock : std_logic := '1';
  signal cpuclock_divisor : integer := 0;

  signal colourram_at_dc00 : std_logic := '0';

  signal monitor_pc : std_logic_vector(15 downto 0);
  signal monitor_state : std_logic_vector(7 downto 0);
  signal monitor_mem_address : std_logic_vector(27 downto 0);
  signal monitor_mem_rdata : unsigned(7 downto 0);
  signal monitor_mem_wdata : unsigned(7 downto 0);
  signal monitor_mem_register : unsigned(15 downto 0);
  signal monitor_mem_read : std_logic;
  signal monitor_mem_write : std_logic;
  signal monitor_mem_setpc : std_logic;
  signal monitor_mem_attention_request : std_logic;
  signal monitor_mem_attention_granted : std_logic;
  signal monitor_mem_stage_trace_mode : std_logic;
  signal monitor_mem_trace_mode : std_logic;
  signal monitor_mem_trace_toggle : std_logic;
  
  signal monitor_a : std_logic_vector(7 downto 0);
  signal monitor_x : std_logic_vector(7 downto 0);
  signal monitor_y : std_logic_vector(7 downto 0);
  signal monitor_sp : std_logic_vector(7 downto 0);
  signal monitor_p : std_logic_vector(7 downto 0);
  signal monitor_opcode : std_logic_vector(7 downto 0);
  
  signal segled_counter : unsigned(19 downto 0) := (others => '0');

begin

  ----------------------------------------------------------------------------
  -- IRQ & NMI: If either the hardware buttons on the FPGA board or an IO
  -- device via the IOmapper pull an interrupt line down, then trigger an
  -- interrupt.
  -----------------------------------------------------------------------------
  process(irq,nmi,io_irq,io_nmi)
  begin
    combinedirq <= irq and io_irq;
    combinednmi <= nmi and io_nmi;
  end process;
  
  process(pixelclock)
    variable digit : std_logic_vector(3 downto 0);
  begin
    if rising_edge(pixelclock) then

      -- 2 = 64MHz
      -- 3 = 48MHz
      -- 191 = 1MHz
      -- (don't forget to update uart_monitor baudrate divisor as well)
      if cpuclock_divisor<1 then
        cpuclock_divisor <= cpuclock_divisor + 1;
      else
        cpuclock_divisor <= 0;
        cpuclock <= not cpuclock;
      end if;
      
      led0 <= irq;
      led1 <= nmi;
      led2 <= combinedirq;
      led3 <= combinednmi;
      
      segled_counter <= segled_counter + 1;

      sseg_an <= (others => '1');
      sseg_an(to_integer(segled_counter(19 downto 17))) <= '0';

      if segled_counter(19 downto 17)=3 then
        digit := monitor_pc(15 downto 12);
      elsif segled_counter(19 downto 17)=2 then
        digit := monitor_pc(11 downto 8);
      elsif segled_counter(19 downto 17)=1 then
        digit := monitor_pc(7 downto 4);
      elsif segled_counter(19 downto 17)=0 then
        digit := monitor_pc(3 downto 0);
      elsif segled_counter(19 downto 17)=4 then
        digit := monitor_state(3 downto 0);
      --elsif segled_counter(19 downto 17)=5 then
      --  digit := monitor_state(7 downto 4);
      elsif segled_counter(19 downto 17)=5 then
        digit := std_logic_vector(last_scan_code(3 downto 0));
      elsif segled_counter(19 downto 17)=6 then
        digit := std_logic_vector(last_scan_code(7 downto 4));
      elsif segled_counter(19 downto 17)=7 then
        digit := std_logic_vector(last_scan_code(11 downto 8));
      else
        digit := "UUUU";
      end if;

      -- segments are:
      -- 7 - decimal point
      -- 6 - middle
      -- 5 - upper left
      -- 4 - lower left
      -- 3 - bottom
      -- 2 - lower right
      -- 1 - upper right
      -- 0 - top
      case digit is
        when x"0" => sseg_ca <= "11000000";
        when x"1" => sseg_ca <= "11111001";
        when x"2" => sseg_ca <= "10100100";
        when x"3" => sseg_ca <= "10110000";
        when x"4" => sseg_ca <= "10011001";
        when x"5" => sseg_ca <= "10010010";
        when x"6" => sseg_ca <= "10000010";
        when x"7" => sseg_ca <= "11111000";
        when x"8" => sseg_ca <= "10000000";
        when x"9" => sseg_ca <= "10010000";
        when x"A" => sseg_ca <= "10001000";
        when x"B" => sseg_ca <= "10000011";
        when x"C" => sseg_ca <= "11000110";
        when x"D" => sseg_ca <= "10100001";
        when x"E" => sseg_ca <= "10000110";
        when x"F" => sseg_ca <= "10001110";
        when others => sseg_ca <= "10100001";
      end case; 
      
    end if;
  end process;
  
  cpu0: simple6502 port map(
    clock => cpuclock,
    reset =>btnCpuReset,
    irq => combinedirq,
    nmi => combinednmi,
    monitor_pc => monitor_pc,
    monitor_opcode => monitor_opcode,
    monitor_a => monitor_a,
    monitor_x => monitor_x,
    monitor_y => monitor_y,
    monitor_sp => monitor_sp,
    monitor_p => monitor_p,
    monitor_state => monitor_state,

    monitor_mem_address => monitor_mem_address,
    monitor_mem_rdata => monitor_mem_rdata,
    monitor_mem_wdata => monitor_mem_wdata,
    monitor_mem_register => monitor_mem_register,
    monitor_mem_read => monitor_mem_read,
    monitor_mem_write => monitor_mem_write,
    monitor_mem_setpc => monitor_mem_setpc,
    monitor_mem_attention_request => monitor_mem_attention_request,
    monitor_mem_attention_granted => monitor_mem_attention_granted,
    monitor_mem_trace_mode => monitor_mem_trace_mode,
    monitor_mem_stage_trace_mode => monitor_mem_stage_trace_mode,
    monitor_mem_trace_toggle => monitor_mem_trace_toggle,

    fastram_we => fastram_we,
    fastram_read => fastram_read,
    fastram_write => fastram_write,
    fastram_address => fastram_address,
    fastram_datain => fastram_datain,
    fastram_dataout => fastram_dataout,
    
    fastio_addr => fastio_addr,
    fastio_read => fastio_read,
    fastio_write => fastio_write,
    fastio_wdata => fastio_wdata,
    fastio_rdata => fastio_rdata
  );
  
  vga0: vga
    port map (
      pixelclock      => pixelclock,
      cpuclock        => cpuclock,
      
      vsync           => vsync,
      hsync           => hsync,
      vgared          => vgared,
      vgagreen        => vgagreen,
      vgablue         => vgablue,

      fastram_we => fastram_we,
      fastram_read => fastram_read,
      fastram_write => fastram_write,
      fastram_address => fastram_address,
      fastram_datain => fastram_datain,
      fastram_dataout => fastram_dataout,    
           
      fastio_addr     => fastio_addr,
      fastio_read     => fastio_read,
      fastio_write    => fastio_write,
      fastio_wdata    => fastio_wdata,
      fastio_rdata    => fastio_rdata,

      colourram_at_dc00 => colourram_at_dc00
      );
  
  iomapper0: iomapper port map (
    clk => cpuclock,
    reset => btnCpuReset,
    irq => io_irq, -- (but we might like to AND this with the hardware IRQ button)
    nmi => io_nmi, -- (but we might like to AND this with the hardware IRQ button)
    address => fastio_addr,
    r => fastio_read, w => fastio_write,
    data_i => fastio_wdata, data_o => fastio_rdata,
    colourram_at_dc00 => colourram_at_dc00,
    ps2data => ps2data,
    ps2clock => ps2clock,
    last_scan_code => last_scan_code);

  -----------------------------------------------------------------------------
  -- UART interface for monitor debugging and loading data
  -----------------------------------------------------------------------------
  monitor0 : uart_monitor port map (
    reset => btnCpuReset,
    clock => cpuclock,
    tx       => UART_TXD,
    rx       => RsRx,

    monitor_pc => monitor_pc,
    monitor_opcode => monitor_opcode,
    monitor_a => monitor_a,
    monitor_x => monitor_x,
    monitor_y => monitor_y,
    monitor_sp => monitor_sp,
    monitor_p => monitor_p,
    
    monitor_mem_address => monitor_mem_address,
    monitor_mem_rdata => monitor_mem_rdata,
    monitor_mem_wdata => monitor_mem_wdata,
    monitor_mem_register => monitor_mem_register,
    monitor_mem_read => monitor_mem_read,
    monitor_mem_write => monitor_mem_write,
    monitor_mem_setpc => monitor_mem_setpc,
    monitor_mem_attention_request => monitor_mem_attention_request,
    monitor_mem_attention_granted => monitor_mem_attention_granted,
    monitor_mem_trace_mode => monitor_mem_trace_mode,
    monitor_mem_stage_trace_mode => monitor_mem_stage_trace_mode,
    monitor_mem_trace_toggle => monitor_mem_trace_toggle
);
  
end Behavioral;

