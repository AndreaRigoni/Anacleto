library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity splitter is
  generic(

    -- Master AXI Stream Data Width
    C_M_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Slave AXI Stream Data Width
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32
    
    );
  port (

    -- Global Ports
    aclk    : in std_logic;

    -- Master Stream Ports
--  data port
    s_axis_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;
    
    m_axis_tdata_1   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid_1  : out std_logic;
    m_axis_tready_1  : in  std_logic;
    m_axis_tdata_2   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid_2  : out std_logic;
    m_axis_tready_2  : in  std_logic

     );

end splitter;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of splitter is

  
begin

    
    s_axis_tready <= '1';

    m_axis_tvalid_1 <= s_axis_tvalid;
    m_axis_tdata_1 <= s_axis_tdata; 
    m_axis_tvalid_2 <= s_axis_tvalid;
    m_axis_tdata_2 <= s_axis_tdata; 
           
 end implementation;
 