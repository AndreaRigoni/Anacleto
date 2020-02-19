library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity resampler is
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
    
    m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;

    ext_clk        : in std_logic;
    sync_ext_clk   : out std_logic;
    
    mode_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
    );

end resampler;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of resampler is
    signal int_sync_ext_clk: std_logic;
    signal use_ext_clk: std_logic;
    signal ext_clk_arr: std_logic_vector (0 downto 0);
    signal sync_ext_clk_arr: std_logic_vector (0 downto 0);
    signal curr_input: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0'); 
    signal resampled_tvalid: std_logic := '0';
    signal resampled_tdata: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0'); 
    signal prev_ext_clk : std_logic := '0';

    constant STATE_IDLE: integer := 0;
    constant STATE_RESAMPLED: integer := 1;

 
begin

    xpm_cdc_array_single_inst : xpm_cdc_array_single
    generic map (
      -- Common module generics
      DEST_SYNC_FF => 4, -- integer; range: 2-10
      SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 0, -- integer; 0=do not register input, 1=register input
      WIDTH => 1 -- integer; range: 1-1024
    )
      
    port map (
      src_clk => '0',
      src_in => ext_clk_arr,
      dest_clk => aclk,
      dest_out => sync_ext_clk_arr
    );
      
    sync_ext_clk <= int_sync_ext_clk;  
    ext_clk_arr(0) <= ext_clk;
    int_sync_ext_clk <= sync_ext_clk_arr(0);

    use_ext_clk <= mode_cfg(6);
    s_axis_tready <= '1';

    m_axis_tvalid <= resampled_tvalid when (use_ext_clk = '1') else s_axis_tvalid;
    m_axis_tdata <= resampled_tdata when (use_ext_clk = '1') else s_axis_tdata;  
     
    handle_data_in: process(aclk)
        begin
            if(rising_edge(aclk)) then
                if s_axis_tvalid = '1' then
                    curr_input <= s_axis_tdata;
                end if;
            end if;
        end process;
        
                     
    handle_reasmpling: process(aclk)
        variable state : integer range 0 to 1 := STATE_IDLE;
        begin
            if falling_edge(aclk)  then
                case state is
                    when STATE_IDLE => 
                        if int_sync_ext_clk = '1' and prev_ext_clk = '0' then
                            resampled_tdata <= curr_input;
                            resampled_tvalid <= '1';
                            state := STATE_RESAMPLED;
                        end if;
                    when STATE_RESAMPLED =>
                        resampled_tvalid <= '0';
                        state := STATE_IDLE;
                end case;
                prev_ext_clk <= int_sync_ext_clk;
            end if;
        end process;   
    
   end implementation;
    
  