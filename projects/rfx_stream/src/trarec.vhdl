
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity trarec is
  generic(

    -- Master AXI Stream Data Width
    C_M_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Slave AXI Stream Data Width
    C_S_AXIS_DATA_WIDTH : integer range 32 to 256 := 32;
    
    -- Circular buffer size
    C_CBUF_SIZE: integer := 8192;
    
    --pre-post max value
    C_PRE_POST_MAX: integer := 65536
    
    );
  port (

    -- Global Ports
    aclk    : in std_logic;


    -- Master Stream Ports
--  data port
    m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
--  m_axis_tstrb   : out std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;
--  m_axis_tlast   : out std_logic;

--  data port
    t_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    t_axis_tvalid  : out std_logic;
    t_axis_tready  : in  std_logic;

    -- Slave Stream Ports
--  s_axis_aresetn : in  std_logic;
    s_axis_tdata   : in  std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
--  s_axis_tstrb   : in  std_logic_vector((C_S_AXIS_DATA_WIDTH/8)-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;
--  s_axis_tlast   : in  std_logic

   
--   circular buffer (block memory) Port A
    cbuf_addra: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_clka : out std_logic;
    cbuf_dina: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_douta: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_ena : out std_logic;  
    cbuf_rsta : out std_logic;  
    cbuf_wea : out std_logic_vector(3 downto 0);

--   circular buffer (block memory) Port B
    cbuf_addrb: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_clkb : out std_logic;
    cbuf_dinb: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_doutb: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    cbuf_enb : out std_logic;  
    cbuf_rstb : out std_logic;  
    cbuf_web : out std_logic_vector(3 downto 0);

-- Configuration registers
-- Enable level sensitivity for event stream
   lev_trig_count: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);

-- pre_post_cfg: upper 16 bits: pre trigger samples, lower 16 bits: post trigger samples
    pre_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    post_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    
--    
    mode_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    command_cfg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);


-- trigger
    async_trigger_in: in std_logic;
-- external clock
    ext_clock : in std_logic;
 -- debug purpose
    out_state: out std_logic_vector(3 downto 0);   
    dbg_cbuf_in_addr: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0); 
    dbg_cbuf_curr_in_addr: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0); 
    dbg_cbuf_start_out_addr: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0); 
    out_count: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1  downto 0);
        
--  Test LED    
    led_o : out std_logic;
    led1_o : out std_logic
    );

end trarec;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of trarec is

    constant STATE_IDLE: integer := 1;
    constant STATE_ARMED: integer := 2;
    constant STATE_RUNNING: integer := 3;
    constant STATE_TRIGGER_CHECK: integer := 4;
    constant STATE_TRIGGERED_WAIT_POST: integer := 5;

--Block memory states
   constant MEM_IDLE: integer := 1;
   constant MEM_START: integer := 2;
   constant MEM_PIPE: integer := 3;
   constant MEM_NO_PIPE: integer := 4;

-- Command register: bit 0: Arm; bit 1: Stop; bit 2: SW trigger
    signal arm_cmd: std_logic;
    signal stop_cmd: std_logic;
    signal trig_cmd: std_logic;
 --   signal sync_trigger_in: std_logic;
    signal is_up: std_logic;
    signal continuous: std_logic;
    signal trig_from_chana: std_logic;
    signal cbuf_in_addr : std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');         -- only updted during readout 
    signal cbuf_curr_in_addr : std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');    --always updated when new data arrive
    signal cbuf_start_out_addr : std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0)  := (others => '1');        --only updated when different from cbuf_in_addr       
    signal trig_level : std_logic_vector (15 downto 0) := (others => '0');
    signal curr_state : std_logic_vector (3 downto 0);
    signal trigger_time: std_logic_vector (63 downto 0) := (others => '0'); 
    signal trigger_time_mask: std_logic_vector (1 downto 0) := (others => '0');
    signal saved_cbuf_doutb: std_logic_vector (C_S_AXIS_DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal async_trig_in_arr: std_logic_vector (0 downto 0);
    signal trig_in_arr: std_logic_vector (0 downto 0);
    signal trigger_in: std_logic;
    signal curr_trigger : std_logic := '0';
    signal prev_trigger : std_logic := '0';
        
    signal prev_ext_clock: std_logic := '0';
    signal state_debug: std_logic_vector(15 downto 0) := (others => '0');

begin


--     xpm_cdc_array_single_inst : xpm_cdc_array_single
--      generic map (
--      -- Common module generics
--      DEST_SYNC_FF => 4, -- integer; range: 2-10
--      SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
--      SRC_INPUT_REG => 0, -- integer; 0=do not register input, 1=register input
--      WIDTH => 1 -- integer; range: 1-1024
--      )
      
--      port map (
--      src_clk => '0',
--      src_in => async_trig_in_arr,
--      dest_clk => aclk,
--      dest_out => trig_in_arr
--      );
      
--    async_trig_in_arr(0) <= async_trigger_in;
--    trigger_in <= trig_in_arr(0);
--    out_synch_trig <= trigger_in;

    trigger_in <= async_trigger_in;  --Already synchronized

-------------------------
    dbg_cbuf_in_addr <= cbuf_in_addr;
    dbg_cbuf_curr_in_addr <= cbuf_curr_in_addr;
    dbg_cbuf_start_out_addr <= cbuf_start_out_addr;
    out_state <= curr_state;


    cbuf_clka <= aclk;
    cbuf_wea <= "1111";
    cbuf_rsta <= '0';
    --cbuf_dina <= s_axis_tdata;
    cbuf_clkb <= aclk;
    cbuf_web <= "0000";
    cbuf_rstb <= '0';
    
--    Command register bits: 
--      0: Arm command
--      1: Stop command
--      2: Trigger Command  (equivalent to ext trigger input)

--    Mode register bits:
--      0: Continuous: continuous data acquisizition since trigger until Stop command issued
--      1: Trigger from chan A (1) or chan B (0) (valid only if level triger enabled)
--      2: Trigger above (1) or under (0) threshold (valid only if level trigger enabled)
--      3: Level trigger enabled. If 1: trigger signal will start time counting, actual trigger(s) are derived from the input signal level. If 0: trigger signal (or command) directly fires triggering.
--      4: Multiple triggers (1) or single trigger (0)
--      5: Ext. clock Timing. External clock cycles(1) or data samples (0) counted for timestamp generation 
--      6: Ext clock resampling. If 1: data are resampled on ext clock signal. If 0: data are decimated based from 125MHz via decimation register
--      7: Clock and trigger derived from tining highway
--      8-15: Trigger count (number of samples for validating trigger)
--      16-31: Trigger level  (valid only if level trigger enabled)   
    
     
    arm_cmd <= command_cfg(0);
    stop_cmd <= command_cfg(1);
    trig_cmd <= command_cfg(2);
    is_up <= mode_cfg(2);
    trig_from_chana <= mode_cfg(1);
    continuous <= mode_cfg(0);
    trig_level <= mode_cfg(31 downto 16);
    
    --Handle cirbular buffer insertion/removal
    handle_cbuf: process(aclk)
        variable data: std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
        variable available: std_logic := '0';     --
        variable out_addr : integer range 0 to  C_PRE_POST_MAX := 0;     -- circular buffer read address
        variable in_addr : integer range 0 to  C_PRE_POST_MAX := 0;      -- circular buffer write address frozen by process handle_event 
        variable curr_in_addr : integer range 0 to  C_PRE_POST_MAX := 0; -- circular buffer current write adderss, always incremented when a new sample is available
        variable mem_state : integer range 0 to MEM_NO_PIPE := MEM_IDLE;




        begin
            if(falling_edge(aclk)) then
                if trigger_in = '1' or trig_cmd = '1' then
                    curr_trigger <= '1';
                else
                    curr_trigger <= '0';
                end if;
          
                if continuous = '0' then
                    s_axis_tready <= '1';
            -- Check if there are  samples to be read from circular buffer and sent to FIFO
                   if mem_state = MEM_PIPE or mem_state = MEM_NO_PIPE then
                    
                    --if available = '1' then
                        m_axis_tvalid <= '1';
                        
                        m_axis_tdata <= saved_cbuf_doutb;
                        --m_axis_tdata(15 downto 0) <= saved_cbuf_doutb(15 downto 0);
                        --m_axis_tdata(31 downto 16) <= state_debug ; 
  
     ---------------------------------------
                    else
                        m_axis_tvalid <= '0';
                    end if;
                else  --continuous
                    if curr_state(0) = '1' and curr_state(1) = '1' and available = '1' then
                        m_axis_tvalid <= '1';
                        m_axis_tdata <= data;
                    else
                        m_axis_tvalid <= '0';
                    end if;
                end if;

                in_addr := to_integer(unsigned(cbuf_in_addr)); --cbuf_in_addr is the only address possibly changed outside this process
                if not (cbuf_start_out_addr = "11111111111111111111111111111111")  then --if it is has just been set
                    out_addr := to_integer(unsigned(cbuf_start_out_addr));
                end if;
                if in_addr /= out_addr then   --Data in circular buffer must be sent to FIFO
                    cbuf_addrb <= std_logic_vector(to_unsigned(out_addr*4, C_S_AXIS_DATA_WIDTH));
                    out_addr := out_addr + 1;
                    if out_addr = C_CBUF_SIZE  then
                        out_addr := 0;
                    end if;
                    cbuf_enb <= '1';
                    case mem_state is
                        when MEM_IDLE => 
                            mem_state := MEM_START;
                         when MEM_START => 
                            mem_state := MEM_PIPE;
                        when MEM_PIPE =>
                            mem_state := MEM_PIPE;
                        when MEM_NO_PIPE =>
                            mem_state := MEM_START;
                        when others =>
                    end case;
                 else    
                     case mem_state is
                         when MEM_IDLE => 
                             mem_state := MEM_IDLE;
                         when MEM_START => 
                             mem_state := MEM_NO_PIPE;
                         when MEM_PIPE =>
                             mem_state := MEM_NO_PIPE;
                         when MEM_NO_PIPE =>
                             mem_state := MEM_IDLE;
                             cbuf_enb <= '0';

                         when others =>
                    end case;
                end if;
                
                --write to circular buffer, performed every time a new sample is available in s_axis
                if available = '1' then
                     available := '0';
--                     cbuf_addra <= std_logic_vector(to_unsigned(curr_in_addr , C_S_AXIS_DATA_WIDTH)); 
                     cbuf_addra <= std_logic_vector(to_unsigned(curr_in_addr * 4 , C_S_AXIS_DATA_WIDTH)); 
                     curr_in_addr := curr_in_addr + 1;
--                     if(curr_in_addr = C_CBUF_SIZE - 1) then
                     if(curr_in_addr = C_CBUF_SIZE) then
                         curr_in_addr := 0;
                     end if;
                     cbuf_curr_in_addr <= std_logic_vector(to_unsigned(curr_in_addr, C_S_AXIS_DATA_WIDTH)); 
                     cbuf_ena <= '1';
                     cbuf_dina <= data;
                 else
                     cbuf_ena <= '0';
                 end if;
                 if trigger_time_mask(0) = '1' then
                     t_axis_tvalid <= '1';
                     t_axis_tdata <= trigger_time(31 downto 0);
                 else 
                     if trigger_time_mask(1) = '1' then
                        t_axis_tvalid <= '1';
                        t_axis_tdata <= trigger_time(63 downto 32);
                     else
                        t_axis_tvalid <= '0'; 
                     end if;
                 end if;
            end if;   
            -- check for new avilable sample from s_axis
            if (rising_edge(aclk)) then
                if s_axis_tvalid = '1' then
                    available := '1';
                    data := s_axis_tdata;
                 end if;
                saved_cbuf_doutb <= cbuf_doutb;
                
           prev_trigger <= curr_trigger;
           end if;
        end process;

        handle_state : process(aclk)
    --State Machine 
            variable state : integer range 0 to 16 := STATE_IDLE;
            variable selected_chan : integer;
            variable curr_count : integer := 0;
            variable out_address : integer := 0;
            variable prev_armed : std_logic := '0';    
            variable not_yet_triggered : integer range 0 to 1 := 1;
            variable last_lev_count: integer := 0;
            variable curr_lev_count: integer;
            begin
                if rising_edge(aclk) then
                    state_debug <= std_logic_vector(to_unsigned(state, 16));
    --                prev_trigger := curr_trigger;
                    case state is
                        when STATE_IDLE => 
                            -- last_lev_count :=  to_integer(signed(lev_trig_count));
                            if arm_cmd = '1' and prev_armed = '0' then
                                state := STATE_ARMED;
                                not_yet_triggered := 1;
                            end if;
                        when STATE_ARMED =>
                            if s_axis_tvalid = '1' and continuous = '0' and mode_cfg(5) = '0' then
                                trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                            else
                                if ext_clock = '1' and prev_ext_clock = '0' and continuous = '0' and mode_cfg(5) = '1' then
                                    trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                end if;
                            end if;
                            if stop_cmd = '1' then
                                state := STATE_IDLE;
                            else
--                                if trigger_in = '1' or trig_cmd = '1' then
                                if prev_trigger = '0' and curr_trigger = '1' then
                                    if not_yet_triggered = 1 then
                                        not_yet_triggered := 0;
                                        trigger_time <= (others => '0');
                                    end if;
                                    state := STATE_RUNNING;
                                end if;
                            end if;
                        when STATE_RUNNING => 
                            if stop_cmd = '1' then
                                state := STATE_IDLE;
                            else 
                                if s_axis_tvalid = '1' and continuous = '0' and mode_cfg(5) = '0' then
                                   trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                else
                                   if ext_clock = '1' and prev_ext_clock = '0' and continuous = '0' and mode_cfg(5) = '1' then
                                       trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                   end if;
                                end if;
                                if s_axis_tvalid = '1' and continuous = '0' then
                                    if trig_from_chana = '1' then  -- chana -> lest significant 16 bytes
                                       selected_chan := to_integer(signed(s_axis_tdata(15 downto 0)));
                                    else
                                       selected_chan := to_integer(signed(s_axis_tdata(31 downto 16)));
                                    end if;
                                    if (is_up = '1' and selected_chan > to_integer(signed(trig_level))) or 
                                        (is_up = '0' and selected_chan < to_integer(signed(trig_level))) or mode_cfg(3) = '0' then
                                        
                                        curr_lev_count :=  to_integer(signed(lev_trig_count));
                                        if( mode_cfg(3) = '0' or curr_lev_count > last_lev_count) then 
                                            state := STATE_TRIGGER_CHECK;
                                        end if;
                                        curr_count := 0;
                                    end if; 
                                end if;  
                             end if;  
                        when STATE_TRIGGER_CHECK =>
                            if stop_cmd = '1' then
                                state := STATE_IDLE;
                            else
                                if s_axis_tvalid = '1' and mode_cfg(5) = '0' then
                                    trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                else
                                    if ext_clock = '1' and prev_ext_clock = '0' and mode_cfg(5) = '1' then
                                        trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                    end if;
                                end if;
                                if s_axis_tvalid = '1' then
                                      if trig_from_chana = '1' then  -- chana -> least significant 16 bytes
                                        selected_chan := to_integer(signed(s_axis_tdata(15 downto 0)));
                                    else
                                        selected_chan := to_integer(signed(s_axis_tdata(31 downto 16)));
                                    end if;
                                    if (is_up = '1' and selected_chan > to_integer(signed(trig_level))) or 
                                         (is_up = '0' and selected_chan < to_integer(signed(trig_level))) or mode_cfg(3) = '0'  then
                                        if curr_count >= to_integer(unsigned(mode_cfg(15 downto 8))) or mode_cfg(3) = '0' then
                                            state := STATE_TRIGGERED_WAIT_POST;
                                            if mode_cfg(3) = '0' then
                                                curr_count := 2; -- 2 Samples lost after detecting trigger
                                            else
                                                curr_count := to_integer(unsigned(mode_cfg(15 downto 8)));
                                            end if;
                                            --compute c_out_addr
                                            out_address := to_integer(unsigned(cbuf_curr_in_addr));
                                            out_address := out_address - to_integer(unsigned(pre_cfg));
                                            out_address := out_address - curr_count; 
                                            --pre-trigger is referred to the first occurrence of trigger event
                                             if out_address < 0 then
                                                out_address := out_address + C_CBUF_SIZE;
                                             end if;
                                             cbuf_start_out_addr <= std_logic_vector(to_unsigned(out_address, C_S_AXIS_DATA_WIDTH));
                                             cbuf_in_addr <= cbuf_curr_in_addr;
                                             trigger_time_mask <= (others => '1');
                                        else
                                             curr_count := curr_count + 1;
                                        end if;
                                    else
                                        state := STATE_RUNNING;  --trigger condition not lasting enough
                                    end if; 
                                 end if;  
                            end if;  
                        when STATE_TRIGGERED_WAIT_POST =>
                           last_lev_count :=  curr_lev_count;
                           if trigger_time_mask(0) = '1' then
                                trigger_time_mask(0) <= '0';
                            else
                                if trigger_time_mask(1) = '1' then
                                    trigger_time_mask(1) <= '0';
                                end if;
                            end if;    
                            cbuf_start_out_addr <= (others => '1'); --all ones means invalid
                          --  if stop_cmd = '1' then
                           --     state := STATE_IDLE;
                           -- else
                               if s_axis_tvalid = '1' and mode_cfg(5) = '0' then
                                   trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                               else
                                   if ext_clock = '1' and prev_ext_clock = '0' and mode_cfg(5) = '1' then
                                       trigger_time <= std_logic_vector(unsigned(trigger_time)+1);
                                   end if;
                               end if;
                               if s_axis_tvalid = '1' then
                                    curr_count := curr_count + 1;
                                    cbuf_in_addr <= cbuf_curr_in_addr;
                                    if curr_count >= to_integer(unsigned(post_cfg)) then
                                        if mode_cfg(4) = '0' then  --Single trigger
                                            state := STATE_IDLE;
                                        else 
                                            if mode_cfg(3) = '1' then  --trigger on level
                                                state := STATE_RUNNING; 
                                            else
                                                state := STATE_ARMED; --trigger on ext-trigger
                                            end if;
                                        end if;
                                    end if;
                                end if;
                           -- end if; 
                        when others =>
                            state := STATE_IDLE;                                 
                     end case;
                     prev_ext_clock <= ext_clock;
                     curr_state <= std_logic_vector(to_unsigned(state, 4));
                     out_count <= std_logic_vector(to_unsigned(curr_count, C_S_AXIS_DATA_WIDTH));
                     prev_armed := arm_cmd;
                end if;
             end process;
            




--test upon trigger reception, produce the first three samples
--    test trigger: process(aclk)
--        variable triggered : std_logic := '0';
--        variable in_addr : integer := 0;
--        begin
--            if rising_edge(aclk) then
--                if trigger_in = '1' and triggered = '0' then
--                    triggered := '1';
--                    in_addr := to_integer(unsigned(cbuf_out_addr)) + 3;
--                    if in_addr >= C_CBUF_SIZE then
--                        in_addr := in_addr - C_CBUF_SIZE;
--                    end if;
--                    cbuf_in_addr <= std_logic_vector(to_unsigned(in_addr,  C_S_AXIS_DATA_WIDTH));
--                end if;
--                if trigger_in = '0' then
--                    triggered := '0';
--                end if;
--            end if;
--        end process;
            




  led_o <= '1';

  

end implementation;

