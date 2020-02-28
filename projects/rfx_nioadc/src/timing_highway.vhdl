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
    highway_clk  : in  std_logic;
    in_event_code : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    mode_cfg : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    in_trig : in std_logic;
         
    out_clk : out std_logic;
    out_trig : out std_logic;   
    out_event_code: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0)
    
    );

end highway;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of highway is

    constant STATE_COUNT_ON_0_PERIOD: integer := 0;
    constant STATE_COUNT1_ON_0_PERIOD: integer := 1;
    constant STATE_COUNT2_ON_0_PERIOD: integer := 2;
    constant STATE_WAIT_EVENT: integer := 3;
    constant STATE_CLOCK_GEN_HI: integer := 3;
    constant STATE_CLOCK_GEN_LO: integer := 4;
    constant STATE_DECODE_EVENT: integer := 4;

 
    signal highway_clk_arr: std_logic_vector (0 downto 0);
    signal sync_highway_clk_arr: std_logic_vector (0 downto 0);
    signal synch_highway_clk: std_logic;
    signal trig_arr: std_logic_vector (0 downto 0);
    signal sync_trig : std_logic;
    signal sync_trig_arr: std_logic_vector (0 downto 0);
    signal synch_trig: std_logic;
    signal out_highway_clk: std_logic;
    signal out_highway_trig: std_logic;
    signal use_highway: std_logic;

 
begin



 highway_sync : xpm_cdc_array_single
 generic map (
   -- Common module generics
   DEST_SYNC_FF => 4, -- integer; range: 2-10
   SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
   SRC_INPUT_REG => 0, -- integer; 0=do not register input, 1=register input
   WIDTH => 1 -- integer; range: 1-1024
 )
   
 port map (
   src_clk => '0',
   src_in => highway_clk_arr,
   dest_clk => aclk,
   dest_out => sync_highway_clk_arr
 );
    highway_clk_arr(0) <= highway_clk;
    synch_highway_clk <= sync_highway_clk_arr(0);


 trig_sync : xpm_cdc_array_single
 generic map (
   -- Common module generics
   DEST_SYNC_FF => 4, -- integer; range: 2-10
   SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
   SRC_INPUT_REG => 0, -- integer; 0=do not register input, 1=register input
   WIDTH => 1 -- integer; range: 1-1024
 )
   
 port map (
   src_clk => '0',
   src_in => trig_arr,
   dest_clk => aclk,
   dest_out => sync_trig_arr
 );
    trig_arr(0) <= in_trig;
    sync_trig <= sync_trig_arr(0);
    
    
    use_highway <= mode_cfg(7);
    out_clk <= out_highway_clk when (use_highway = '1') else synch_highway_clk;
    out_trig <= out_highway_trig when (use_highway = '1') else sync_trig;
                      
    handle_trigger: process(aclk)
        variable state : integer range 0 to 4 := STATE_COUNT_ON_0_PERIOD;
        variable count : integer range 0 to 4096 := 0;
        variable prev_count : integer range 0 to 4096 := 0;
        variable prev_clk : std_logic;
        variable parity : std_logic;
        variable bit_count : integer range 0 to 8 := 0;
        variable event_code : integer range 0 to 256 := 0;
        begin
            if falling_edge(aclk)  then
                case state is
                    when STATE_COUNT_ON_0_PERIOD => 
                       out_highway_trig <= '0';
                       if prev_clk = '1' and synch_highway_clk = '0' then
--                            period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                            prev_count := count;
                            count := 0;
                            state := STATE_COUNT1_ON_0_PERIOD;
                         else
                            count := count + 1;
                        end if;
                   when STATE_COUNT1_ON_0_PERIOD => 
                        if prev_clk = '1' and synch_highway_clk = '0' then
--                              period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                            if count > prev_count - 5 or count < prev_count + 5 then
                               state := STATE_COUNT2_ON_0_PERIOD;
                               prev_count := count;
                            else
                                state := STATE_COUNT_ON_0_PERIOD;
                            end if;
                            count := 0;
                        else
                            count := count + 1;
                        end if;
                   when STATE_COUNT2_ON_0_PERIOD => 
                        if prev_clk = '1' and synch_highway_clk = '0' then
--                             period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                             if count > prev_count - 5 or count < prev_count + 5 then
--                                period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                                state := STATE_WAIT_EVENT;
                             else
                                state := STATE_COUNT_ON_0_PERIOD;
                             end if;
                             count := 0;
                         else
                             count := count + 1;
                        end if;
                    when STATE_WAIT_EVENT =>
                        out_highway_trig <= '0';
--                        period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                        if count > prev_count + 10000 then 
                            state := STATE_COUNT_ON_0_PERIOD;   --clock lost
                            count := 0;
                        else
                            if prev_clk /= synch_highway_clk and count > prev_count - 10 then -- True transition bringing info
                                if prev_clk = '0' then
                                    state := STATE_DECODE_EVENT;
                                    bit_count := 0;
                                    event_code := 0;
                                    parity := '0';
                                end if;
                                count := 0;
                            else
                                count := count + 1;
                            end if;
                        end if;      
                    when STATE_DECODE_EVENT =>
                        if prev_clk /= synch_highway_clk and count > prev_count - 10 then -- True transition bringingh info
                            if bit_count < 8 then
                                if bit_count = 7 then --parity check
                                    if prev_clk = parity then
                                        out_event_code <= std_logic_vector(to_unsigned(event_code, C_S_AXIS_DATA_WIDTH)); 
                                        if event_code = to_integer(unsigned(in_event_code)) then
                                            out_highway_trig <= '1';
                                        end if;
                                        state := STATE_WAIT_EVENT;
                                    else
                                        state := STATE_COUNT_ON_0_PERIOD;  --Parity error: start from scratch
                                    end if;
                                else
                                    event_code := event_code/2;
                                    if prev_clk = '1' then
                                        event_code := 64 + event_code;
                                        parity := not parity;
--                                    event_code := event_code * 2 + 1;
                                    end if;
                                end if;
                                bit_count := bit_count + 1;
                                count := 0;
                            end if;                            
                        else
                            count := count + 1;
                        end if;
                end case;
                prev_clk := synch_highway_clk;
            end if;
        end process handle_trigger;   
   
   
       handle_clock: process(aclk)
            variable state : integer range 0 to 4 := STATE_COUNT_ON_0_PERIOD;
            variable count : integer range 0 to 4096 := 0;
            variable prev_count : integer range 0 to 4096 := 0;
            variable prev_clk : std_logic;
            begin
                if falling_edge(aclk)  then
                    case state is
                        when STATE_COUNT_ON_0_PERIOD => 
                            out_highway_clk <= '0';
                            if prev_clk = '1' and synch_highway_clk = '0' then
    --                            period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                                prev_count := count;
                                count := 0;
                                state := STATE_COUNT1_ON_0_PERIOD;
                             else
                                count := count + 1;
                            end if;
                       when STATE_COUNT1_ON_0_PERIOD => 
                            if count > prev_count + 1000 then  --lost clock
                                state := STATE_COUNT_ON_0_PERIOD;
                                count := 0;
                            else
                                if prev_clk = '1' and synch_highway_clk = '0' then
    --                              period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                                    if count > prev_count - 5 or count < prev_count + 5 then
                                        state := STATE_COUNT2_ON_0_PERIOD;
                                        prev_count := count;
                                    else
                                        state := STATE_COUNT_ON_0_PERIOD;
                                    end if;
                                    count := 0;
                                else
                                    count := count + 1;
                                end if;
                            end if;
                       when STATE_COUNT2_ON_0_PERIOD => 
                            if count > prev_count + 1000 then  -- lost clock
                                state := STATE_COUNT_ON_0_PERIOD;
                                count := 0;
                            else
                                if prev_clk = '1' and synch_highway_clk = '0' then
    --                             period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                                    if count > prev_count - 5 or count < prev_count + 5 then
    --                                period_count <= std_logic_vector(to_unsigned(state, C_S_AXIS_DATA_WIDTH)); 
                                        state := STATE_CLOCK_GEN_HI;
                                        out_highway_clk <= '1';
                                    else
                                        state := STATE_COUNT_ON_0_PERIOD;
                                    end if;
                                    count := 0;
                                else
                                    count := count + 1;
                                end if;
                            end if;
                        when STATE_CLOCK_GEN_HI =>
                            if count = prev_count / 2 then
                                out_highway_clk <= '0';
                                state := STATE_CLOCK_GEN_LO;
                            end if;
                            count := count + 1;
                        when STATE_CLOCK_GEN_LO =>
                            if prev_clk /= synch_highway_clk and count > prev_count - 10 then -- True transition bringingh info
                                out_highway_clk <= '1';
                                state :=  STATE_CLOCK_GEN_HI; 
                                count := 0;
                            else
                                count := count + 1;  
                            end if;
                    end case;
                    prev_clk := synch_highway_clk;
                end if;
            end process handle_clock;   

   end implementation;
    
  