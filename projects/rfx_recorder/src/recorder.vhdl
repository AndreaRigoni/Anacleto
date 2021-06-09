library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity recorder is
  generic(

    -- Master AXI Stream Data Width
    C_M_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Slave AXI Stream Data Width
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Number of channels
    C_NUM_CHANNELS: integer range 0 to 16 := 12
  );
  port (

    -- Global Ports
    aclk    : in std_logic;

    -- Master Stream Ports
--  data port Transient Recorder
    s_axis_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;
    
    m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;
    m_axis_tlast   : out std_logic;

 
    ext_trigger        : in std_logic;
    
    mode_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    pts_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cmd_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    chunk_size_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    status_reg: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    count_reg: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
    );

end recorder;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of recorder is

    signal sw_trigger: std_logic;
    signal arm_cmd: std_logic;
    signal stop_cmd: std_logic;
    signal out_count_reg: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    signal use_ext_trigger : std_logic;
    signal data_present : std_logic := '0';
    signal last_data : std_logic := '0';
    constant STATE_IDLE: integer := 0;
    constant STATE_ARMED: integer := 1;
    constant STATE_TRIGGERED: integer := 2;
    constant STATE_FLUSHING_CHUNK: integer := 3;
    
    constant STATE_OUTPUT: integer := 1; --not an error....
    
    constant STATUS_ARMED_BIT: integer:= 0;
    constant STATUS_TRIGGERED_BIT: integer:= 1;  
 
    type t_chans32 is array(0 to C_NUM_CHANNELS - 1) of signed(31 downto 0);
    signal in_data: t_chans32;
 
begin
-- Command register bits:
-- 0: Transient recorder SW trigger
-- 1: Arm transient recorder
-- 2: stop transient recorder
-- 3: Start streaming
-- 4: Stop Streaming
-- 5: StartAutozero
    sw_trigger <= cmd_reg(0);
    arm_cmd <= cmd_reg(1);
    stop_cmd <= cmd_reg(2);
    
-- Mode register bits: 
-- 0: Use Ext Transient recorder trigger (1)
-- 1: Use Ext Autozero trigger
    use_ext_trigger <= mode_reg(0);
    
    s_axis_tready <= '1';

    count_reg <= out_count_reg; 
           
                     
    handle_transient: process(aclk)
        variable state : integer range 0 to 3 := STATE_IDLE;
        variable pts_count : integer;
        variable out_count : integer;
        variable flush_clock_count : integer := 0;
        variable idx: integer range 0 to 16;
        begin
            if falling_edge(aclk)  then
                case state is
                    when STATE_IDLE => 
--                       out_tvalid <= '0';
                        status_reg <= (others => '0');
                        if arm_cmd = '1' then
                            state := STATE_ARMED;
                        end if;
                        
                     when STATE_ARMED => 
--                        out_tvalid <= '0';
                        status_reg <= (STATUS_ARMED_BIT => '1', others => '0');
                        if stop_cmd = '1' then
                            state := STATE_IDLE;
                        else
                            if sw_trigger = '1' or (use_ext_trigger = '1' and ext_trigger = '1') then
                                out_count_reg <= std_logic_vector(to_unsigned(out_count, C_S_AXIS_DATA_WIDTH));
                                state := STATE_TRIGGERED;
                            end if;
                        end if;
                       
                     when  STATE_TRIGGERED =>
--                        out_tvalid <= s_axis_tvalid;
--                        out_tdata <= s_axis_tdata;
                        status_reg <= (STATUS_TRIGGERED_BIT => '1', others => '0');
                        if stop_cmd = '1' and pts_count > 0 then
                            state := STATE_FLUSHING_CHUNK;
                        else
                            if pts_count = 0 then
                                state := STATE_IDLE;
                             end if;
                        end if;
                     when  STATE_FLUSHING_CHUNK =>
                        if pts_count = 0  then
                            state := STATE_IDLE;
                        end if;                       
                 end case;
            end if;
            
            if rising_edge(aclk)  then
                if state = STATE_FLUSHING_CHUNK then
                    flush_clock_count := flush_clock_count + 1; --avoid oveflowing DMA FIFO when flushing at full speed
                    if flush_clock_count > 10000 then
                        idx := 0;
                        while(idx < C_NUM_CHANNELS) loop
                            in_data(idx) <= (others => '0');
                            idx := idx + 1;
                        end loop;
                        data_present <= '1';
                        flush_clock_count := 0;
                        pts_count := pts_count - 1;
                        if pts_count = 0 then
                            last_data <= '1';
                        else
                            last_data <= '0';
                        end if;
                    else
                        data_present <= '0';
                    end if;
                 else
                    if s_axis_tvalid = '1' then
                        if state = STATE_IDLE then
                         out_count := 0;
                         pts_count := to_integer(signed(pts_reg(C_S_AXIS_DATA_WIDTH-1 downto 0)));
                        end if;
                        if state = STATE_ARMED then
                            out_count := out_count + 1;
                        end if;
                        if state = STATE_TRIGGERED then
                            in_data(0) <= signed(s_axis_tdata(15 downto 0));
                            in_data(1) <= signed(s_axis_tdata(31 downto 16));
                            in_data(2) <= signed(s_axis_tdata(15 downto 0))+1;
                            in_data(3) <= signed(s_axis_tdata(31 downto 16))+1;
                            in_data(4) <= signed(s_axis_tdata(15 downto 0))+2;
                            in_data(5) <= signed(s_axis_tdata(31 downto 16))+2;
                            in_data(6) <= signed(s_axis_tdata(15 downto 0))+3;
                            in_data(7) <= signed(s_axis_tdata(31 downto 16))+3;
                            in_data(8) <= signed(s_axis_tdata(15 downto 0))+4;
                            in_data(9) <= signed(s_axis_tdata(31 downto 16))+4;
                            in_data(10) <= signed(s_axis_tdata(15 downto 0))+5;
                            in_data(11) <= signed(s_axis_tdata(31 downto 16))+5;
                            data_present <= '1';
                            pts_count := pts_count - 1;
                            if pts_count = 0 then
                                last_data <= '1';
                            else
                                last_data <= '0';
                            end if;
                        else
                            data_present <= '0';
                        end if;
                    else
                        data_present <= '0';
                    end if;
                 end if;
            end if;
            
        end process;   
        
    handle_output: process(aclk)
         variable state1 : integer range 0 to 1 := STATE_IDLE;
         variable idx1 : integer range 0 to 16;
         variable is_last : std_logic := '0';
         begin
            if falling_edge(aclk)  then
                case state1 is
                    when STATE_IDLE =>
                        m_axis_tvalid <= '0';
                        m_axis_tlast <= '0';
                        if data_present = '1' then
                            is_last := last_data;
                            idx1 := 0;
                            state1 := STATE_OUTPUT;
                        end if;
                    when STATE_OUTPUT =>
                        m_axis_tdata <= std_logic_vector(in_data(idx1));
                        m_axis_tvalid <= '1';
  --                       m_axis_tvalid <= '0';
                        idx1 := idx1 + 1;
                        if idx1 = C_NUM_CHANNELS then
                            state1 := STATE_IDLE;
                            m_axis_tlast <= is_last;
                           -- m_axis_tlast <= '0';
                        else
                            m_axis_tlast <= '0';
                        end if;
                        
                end case;
            end if;    
         end process;     
           
        
   end implementation;
    
  
 