library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity highway is
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
    synch_ext_clk  : in  std_logic;
        
    period_count: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
    );

end highway;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of highway is
    signal resampled_tdata: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0'); 
    signal prev_ext_clk : std_logic := '0';

    constant STATE_COUNT_ON_0_PERIOD: integer := 0;
    constant STATE_RESAMPLED: integer := 1;

 
begin

                      
    handle_trigger: process(aclk)
        variable state : integer range 0 to 1 := STATE_COUNT_ON_0_PERIOD;
        variable count : integer range 0 to 4096 := 0;
        variable prev_clk : std_logic;
        begin
            if falling_edge(aclk)  then
                case state is
                    when STATE_COUNT_ON_0_PERIOD => 
                        if prev_clk = '1' and synch_ext_clk = '0' then
                            period_count <= std_logic_vector(to_unsigned(count, C_S_AXIS_DATA_WIDTH)); 
                            count := 0;
                        else
                            count := count + 1;
                        end if;
                end case;
                prev_clk := synch_ext_clk;
            end if;
        end process handle_trigger;   
    
   end implementation;
    
  