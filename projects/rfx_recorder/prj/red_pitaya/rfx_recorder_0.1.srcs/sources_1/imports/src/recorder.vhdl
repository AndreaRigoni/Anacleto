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
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32
    
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

--  data port Streaming
    s_axis_stream_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    s_axis_stream_tvalid  : in  std_logic;
    s_axis_stream_tready  : out std_logic;
    
    m_axis_stream_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_stream_tvalid  : out std_logic;
    m_axis_stream_tready  : in  std_logic;
    m_axis_stream_tlast   : out std_logic;

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
    signal start_stream: std_logic;
    signal stop_stream: std_logic;
    signal out_tdata: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0'); 
    signal out_count_reg: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    signal out_tvalid : std_logic;
    signal out_tlast : std_logic;
    signal use_ext_trigger : std_logic;
    constant STATE_IDLE: integer := 0;
    constant STATE_ARMED: integer := 1;
    constant STATE_TRIGGERED: integer := 2;
    constant STATE_FLUSHING_CHUNK: integer := 3;
    
    constant STATE_STREAM_IDLE: integer := 0;
    constant STATE_STREAM_ACTIVE: integer := 1;
    
    
    constant STATUS_ARMED_BIT: integer:= 0;
    constant STATUS_TRIGGERED_BIT: integer:= 1;  
 
begin
-- Command register bits:
-- 0: Transient recorder SW trigger
-- 1: Arm transient recorder
-- 2: stop transient recorder
-- 3: Start streaming
-- 4: Stop Streaming
    sw_trigger <= cmd_reg(0);
    arm_cmd <= cmd_reg(1);
    stop_cmd <= cmd_reg(2);
    start_stream <= cmd_reg(3);
    stop_stream <= cmd_reg(4);
    
-- Mode register bits: 
-- 0: Use Ext Transient recorder trigger (1)
    use_ext_trigger <= mode_reg(0);
    
    s_axis_stream_tready <= '1';
    s_axis_tready <= '1';

    m_axis_tvalid <= out_tvalid;
    m_axis_tdata <= out_tdata; 
    m_axis_tlast <= out_tlast;
    count_reg <= out_count_reg; 
           
                     
    handle_transient: process(aclk)
        variable state : integer range 0 to 3 := STATE_IDLE;
        variable pts_count : integer;
        variable out_count : integer;
        variable chunk_count : integer;
        variable flush_clock_count : integer := 0;
        begin
            if falling_edge(aclk)  then
                case state is
                    when STATE_IDLE => 
                       out_tvalid <= '0';
                       out_tlast <= '0';
                       status_reg <= (others => '0');
                        if arm_cmd = '1' then
                            state := STATE_ARMED;
                        end if;
                        
                     when STATE_ARMED => 
                        out_tvalid <= '0';
                        out_tlast <= '0';
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
                        out_tvalid <= s_axis_tvalid;
                        out_tdata <= s_axis_tdata;
                        status_reg <= (STATUS_TRIGGERED_BIT => '1', others => '0');
                        if stop_cmd = '1' and pts_count > 0 then
                            state := STATE_FLUSHING_CHUNK;
                        else
                            if pts_count = 0 then
                                state := STATE_IDLE;
                             end if;
                        end if;
--                        if chunk_count = 1 then
                        if pts_count = 0 then
                            out_tlast <= '1';
                        else
                            out_tlast <= '0';
                        end if;

                     when  STATE_FLUSHING_CHUNK =>
                        status_reg <= (others => '1');
                        if pts_count = 0  then
                            state := STATE_IDLE;
                        end if;
                        if pts_count = 0 then
                             out_tlast <= '1';
                         else
                             out_tlast <= '0';
                         end if;
                       
                 end case;
            end if;
            
            if rising_edge(aclk)  then
                if state = STATE_FLUSHING_CHUNK then
                    flush_clock_count := flush_clock_count + 1; --avoid oveflowing DMA FIFO when flushing at full speed
                    if flush_clock_count > 10000 then
                        out_tvalid <= '1';
                        flush_clock_count := 0;
                        pts_count := pts_count - 1;
                    else
                        out_tvalid <= '0';
                    end if;
                    out_tdata <= (others => '0');
                else
--                    if state = STATE_TRIGGERED then
--                        out_tvalid <= s_axis_tvalid;
--                        out_tdata <= s_axis_tdata;
--                    else
--                        out_tvalid <= '0';
--                        out_tlast <= '0';
--                    end if;
                    if s_axis_tvalid = '1' then
                        if state = STATE_ARMED then
                            out_count := out_count + 1;
                        end if;
                        if state = STATE_TRIGGERED then
                            pts_count := pts_count - 1;
                            chunk_count := chunk_count - 1;
                            if chunk_count = 0 then
                                chunk_count := to_integer(signed(chunk_size_reg(C_S_AXIS_DATA_WIDTH-1 downto 0)));
                            end if;

                        end if;
                    end if;
                    if state = STATE_IDLE then
                        out_count := 0;
                        pts_count := to_integer(signed(pts_reg(C_S_AXIS_DATA_WIDTH-1 downto 0)));
                        chunk_count := to_integer(signed(chunk_size_reg(C_S_AXIS_DATA_WIDTH-1 downto 0)));
                    end if;
                 end if;
            end if;
            
        end process;   
        
        
        
        
    handle_streaming: process(aclk)
         variable state : integer range 0 to 1 := STATE_STREAM_IDLE;
         begin
             if falling_edge(aclk)  then
                 case state is
                     when STATE_STREAM_IDLE => 
                        m_axis_stream_tdata <=  (others => '0');
                        m_axis_stream_tvalid <=  '0';
                        if start_stream = '1' then
                            state := STATE_STREAM_ACTIVE;
                        end if;
                     when STATE_STREAM_ACTIVE => 
                        m_axis_stream_tdata <=  s_axis_stream_tdata;
                        m_axis_stream_tvalid <=  s_axis_stream_tvalid;
                        if stop_stream = '1' then
                             state := STATE_STREAM_IDLE;
                        end if;
               end case;
            end if;
        end process;
          
                

    

        
        
    
   end implementation;
    
  
 