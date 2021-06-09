library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
--use IEEE.STD_LOGIC_ARITH.ALL;

--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity resampler_tb is
  generic(

    -- Master AXI Stream Data Width
    C_M_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;

    -- Slave AXI Stream Data Width
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32

    );
  port (

    -- Global Ports
    aclk    : out std_logic;
    ext_clk : out std_logic;


    -- Master Stream Ports--  m_axis_aresetn : out std_logic;
    out_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    out_axis_tvalid  : out std_logic
    );

end resampler_tb;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------


architecture implementation of resampler_tb is
    constant c_CLK_PERIOD : time := 10 ns;
    component resampler is
       port (

            aclk    : in std_logic;
        
            -- Master Stream Ports
        --  data port
            s_axis_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
            s_axis_tvalid  : in  std_logic;
            s_axis_tready  : out  std_logic;
            m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
            m_axis_tvalid  : out std_logic;
            m_axis_tready  : in std_logic;
            ext_clk        : in std_logic;
            sync_ext_clk : out std_logic;
            
            mode_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
        );

    end component resampler;

  
  
     signal int_aclk    : std_logic := '0';
 
     signal axis_tdata   : std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
     signal axis_tvalid  : std_logic := '0';
     signal axis_tready  : std_logic := '0';
     
     signal res_axis_tdata   : std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
     signal res_axis_tvalid  : std_logic := '0';
     signal res_axis_tready  : std_logic := '0';
 
     signal int_ext_clk        : std_logic := '0';
     signal int_sync_ext_clk : std_logic := '0';
     
     signal int_mode_cfg: std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0) := (6 => '1', others => '0');

  

begin

    resampler_inst : resampler
       port map (
            aclk  => int_aclk,
            s_axis_tdata  =>  axis_tdata,
            s_axis_tvalid  => axis_tvalid,
        
            m_axis_tdata  =>  res_axis_tdata,
            m_axis_tvalid  => res_axis_tvalid,
            m_axis_tready  => res_axis_tready,
    
            ext_clk   =>  int_ext_clk,
            sync_ext_clk  => int_sync_ext_clk,
        
            mode_cfg  => int_mode_cfg
        );
 
 
 
          aclk   <= int_aclk;
          res_axis_tready <= '1';
          
          out_axis_tdata  <= res_axis_tdata;
          out_axis_tvalid <= res_axis_tvalid;
          
          ext_clk   <= int_sync_ext_clk;
          int_aclk <= not int_aclk after c_CLK_PERIOD/2;

    stimulus: process (int_aclk)
         variable v_count : natural range 0 to 100 := 0;
         begin
            if falling_edge(int_aclk) then
                v_count := v_count + 1;           -- Variable
                if v_count = 100 then
                    v_Count := 0;
                end if;
                if(v_count mod 10 = 0) then
                    int_ext_clk <= not int_ext_clk;
                end if;
                
                if (v_count mod 1 = 0) then 
                    axis_tvalid <= '1';
                    axis_tdata <= std_logic_vector(to_unsigned(v_count,C_S_AXIS_DATA_WIDTH));
                else
                    axis_tvalid <= '0';
                end if;
            end if;
     end process stimulus;

end implementation;
