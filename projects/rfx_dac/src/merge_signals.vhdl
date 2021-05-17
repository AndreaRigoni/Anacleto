library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity merge_signals is
  generic(

    -- Master AXI Stream Data Width
    C_M_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Slave AXI Stream Data Width
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    FULL_WIDTH : integer range 0 to 64 := 32;
    HALF_WIDTH : integer range 0 to 64 := 16
    
    );
  port (

    -- Global Ports
    aclk    : in std_logic;

    -- Master Stream Ports
--  data port
    s_axis_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;
    
    m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;

    counter_1: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    counter_2: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    rms_1: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    rms_2: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
    );

end merge_signals;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of merge_signals is
signal prevValid : std_logic;
begin

    s_axis_tready <= '1';
    m_axis_tvalid <= s_axis_tvalid;
--    m_axis_tdata <= s_axis_tdata;
    m_axis_tdata <= counter_1;
--    m_axis_tdata(HALF_WIDTH - 1 downto 0) <= counter_1(HALF_WIDTH - 1 downto 0);  
--    m_axis_tdata(HALF_WIDTH - 1 downto 0) <= rms_1(FULL_WIDTH - 1 downto HALF_WIDTH);  
--    m_axis_tdata(FULL_WIDTH - 1 downto HALF_WIDTH) <= counter_2(HALF_WIDTH - 1 downto 0);  
--   handle_data_in: process(aclk)
--     variable intCount1 : integer := 0;  
--     variable intCount2 : integer := 0;  
--     begin
--         if(rising_edge(aclk)) then
----            if (prevValid = '1' and  s_axis_tvalid = '0') then
--                intCount1 := intCount1 + 1;
--                if (intCount1 > 1000 )then
--                    intCount1 := 0;
--                end if;
--                intCount2 := intCount2 - 1;
--                if (intCount2 < -1000) then
--                    intCount2 := 0;
--                end if;
----            end if;
--            prevValid <= s_axis_tvalid;   
--            m_axis_tdata(FULL_WIDTH - 1 downto HALF_WIDTH) <= std_logic_vector(to_unsigned(intCount1, HALF_WIDTH));  
--            m_axis_tdata(HALF_WIDTH - 1 downto 0) <= std_logic_vector(to_signed(intCount2, HALF_WIDTH)); 
----            m_axis_tdata(FULL_WIDTH - 1 downto HALF_WIDTH) <= counter_2(HALF_WIDTH - 1 downto 0);  
----            m_axis_tdata(HALF_WIDTH - 1 downto 0) <= counter_1(HALF_WIDTH - 1 downto 0);  
--         end if;
--     end process;
     
end implementation;
    
  