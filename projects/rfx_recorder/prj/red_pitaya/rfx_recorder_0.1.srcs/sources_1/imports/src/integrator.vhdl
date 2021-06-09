library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library xpm;
use xpm.vcomponents.all;
--library unisim;
--use unisim.vcomponents.all;

-------------------------------------------------------------------------------
entity integrator is
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
--  data port -- all input signals (16 bits each)
    s_axis_tdata   : in  std_logic_vector(C_NUM_CHANNELS * C_S_AXIS_DATA_WIDTH/2-1 downto 0);
    s_axis_tvalid  : in  std_logic;
    s_axis_tready  : out std_logic;
--All output channels (each 32 bit word formed by channel and integral)
-- At the specified input chans division data are output
-- first C_NUM_CHANNELS 16 bit values are output (C_NUM_CHANNELS/2 32 bit outputs)
-- then C_NUM_CHANNELS 32 bit integrals are output (C_NUM_CHANNELS/2 32 bit outputs)
    m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
    m_axis_tvalid  : out std_logic;
    m_axis_tready  : in  std_logic;
-- frequency division register: specified the reduction factor for outputting streamed data
    freq_div_reg : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
-- Autozero HW trigger
    autozero_trig : in std_logic;
    -- autozero samples is the register that specifies the number of samples to be considered in autozero computation 
    -- starting from either autozero_trig or bit 5 of command register
    autozero_samples_reg : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    -- autozero mul: multiplication factor for autozero computed sum. The result shall be shifted right by 32 
    autozero_mul_reg : in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);
    command_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0);  
-- Command register bits:
    -- 0: Transient recorder SW trigger
    -- 1: Arm transient recorder
    -- 2: stop transient recorder
    -- 3: Start streaming
    -- 4: Stop Streaming
    -- 5: StartAutozero
    mode_reg: in std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0); 
-- Mode register bits: 
    -- 0: Use Ext Transient recorder trigger (1)
    -- 1: Use Ext Autozero trigger
    autozero_reg: out std_logic_vector(C_S_AXIS_DATA_WIDTH-1 downto 0) -- computed autozero value for channel 0 (signed, 32 bits) 
    
    );

end integrator;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------



architecture implementation of integrator is

    constant STATE_OUT_IDLE: integer := 0;
    constant STATE_OUT_WAIT: integer := 1;
    constant STATE_OUT_CHANS: integer := 2;
    constant STATE_OUT_INTEGRALS: integer := 3;
    constant STATE_PREPARE_OUT: integer := 4;
    constant STATE_NOT_CONFIGURED: integer := 0;
    constant STATE_CONFIGURED: integer := 1;
    constant STATE_AUTOZERO: integer := 2;
    constant STATE_IDLE: integer := 3;
    signal use_autozero_trigger: std_logic;
    signal soft_autozero_trig: std_logic;
    signal start_stream: std_logic;
    signal stop_stream: std_logic;
    signal curr_in_chans : std_logic_vector(C_NUM_CHANNELS * C_S_AXIS_DATA_WIDTH/2-1 downto 0);
    signal saved_in_chans : std_logic_vector(C_NUM_CHANNELS * C_S_AXIS_DATA_WIDTH/2-1 downto 0);
    type t_chans32 is array(0 to C_NUM_CHANNELS - 1) of signed(31 downto 0);
    type t_chans48 is array(0 to C_NUM_CHANNELS - 1) of signed(47 downto 0);
    type t_chans16 is array(0 to C_NUM_CHANNELS - 1) of signed(15 downto 0);
    type t_chans60 is array(0 to C_NUM_CHANNELS - 1) of signed(59 downto 0);
 
begin
-- Mode register bits: 
-- 0: Use Ext Transient recorder trigger (1)
-- 1: Use Ext Autozero trigger
    use_autozero_trigger <= mode_reg(1);
    soft_autozero_trig <= command_reg(5);
    stop_stream <= command_reg(4);
    start_stream <= command_reg(3);
    
    handle_integration: process(aclk)
        variable state : integer range 0 to 3 := STATE_IDLE;
        variable state1 : integer range 0 to 4 := STATE_OUT_IDLE;
        variable idx: integer range 0 to 16;
        variable idx1: integer range 0 to 16;
        variable autozero_sums: t_chans48;
        variable integrals: t_chans60;
        variable in_data: t_chans16;
        variable prev_data: t_chans32;
        variable prev_sampled: t_chans32;
        variable offsets: t_chans48;
        variable curr_out_integral: std_logic_vector(59 downto 0);
        variable curr_multiplied: signed(79 downto 0);
        variable curr_out_data: signed(31 downto 0);
        variable autozero_count: signed(C_S_AXIS_DATA_WIDTH -1 downto 0);
        variable data_present: std_logic := '0';
        variable freq_count: signed(C_S_AXIS_DATA_WIDTH -1 downto 0) := (others => '0');
        begin
            if rising_edge(aclk)  then
                 if s_axis_tvalid = '1' then  --new bunch of C_NUM_CHANNELS data 
                     if not(state = STATE_IDLE)  then
                         curr_in_chans <= s_axis_tdata;
 --copy inputs into in_data
                         in_data(0) := signed(curr_in_chans(15 downto 0));
                         in_data(1) := signed(curr_in_chans(31 downto 16));
                         in_data(2) := signed(curr_in_chans(15 downto 0))+1;
                         in_data(3) := signed(curr_in_chans(31 downto 16))+1;
                         in_data(4) := signed(curr_in_chans(15 downto 0))+2;
                         in_data(5) := signed(curr_in_chans(31 downto 16))+2;
                         in_data(6) := signed(curr_in_chans(15 downto 0))+3;
                         in_data(7) := signed(curr_in_chans(31 downto 16))+3;
                         in_data(8) := signed(curr_in_chans(15 downto 0))+4;
                         in_data(9) := signed(curr_in_chans(31 downto 16))+4;
                         in_data(10) := signed(curr_in_chans(15 downto 0))+5;
                         in_data(11) := signed(curr_in_chans(31 downto 16))+5;
                         idx := 0;
                         while(idx < C_NUM_CHANNELS) loop
                             if state = STATE_NOT_CONFIGURED or state = STATE_AUTOZERO then
                                 integrals(idx) := integrals(idx) + (resize(in_data(idx), 60) sll 8);
                              else
                                 integrals(idx) := integrals(idx) + (resize(in_data(idx), 60) sll 8) - resize(offsets(idx), 60);
                             end if;
                             idx := idx + 1;
                         end loop;
                         data_present := '1';
                     end if;
                     case state is
                        when STATE_IDLE =>
                            if start_stream = '1' then
                                idx := 0;
                                while(idx < C_NUM_CHANNELS) loop
                                    integrals(idx) := (others => '0');
                                    offsets(idx) := (others => '0');
                                    autozero_sums(idx) := (others => '0');
                                    idx := idx + 1;
                                end loop;
                                state := STATE_NOT_CONFIGURED;
                            end if;
                        when STATE_NOT_CONFIGURED => 
                            if (use_autozero_trigger = '1' and autozero_trig = '1') or soft_autozero_trig = '1' then
                                idx := 0;
                                while(idx < C_NUM_CHANNELS) loop
                                    autozero_sums(idx) := (others => '0');
                                    idx := idx + 1;
                                end loop;
                                autozero_count := signed(autozero_samples_reg);
                                state := STATE_AUTOZERO;
                            end if;
                            if stop_stream = '1' then
                                state := STATE_IDLE;
                            end if;
                        when STATE_AUTOZERO =>
                            idx := 0;
                            while(idx < C_NUM_CHANNELS) loop
                                autozero_sums(idx) := autozero_sums(idx) + resize(in_data(idx), 48);
                                idx := idx + 1;
                            end loop;
                            autozero_count := autozero_count - 1;
                            if(autozero_count = 0) then
                                idx := 0;
                                while(idx < C_NUM_CHANNELS) loop
                                    curr_multiplied := autozero_sums(idx) * signed(autozero_mul_reg);
                                    --autozero_sums(idx) := resize(autozero_sums(idx)  * signed(autozero_mul_reg), 128);
                                    --offsets(idx) := autozero_sums(idx)(91 downto 32);
                                    offsets(idx) := curr_multiplied(79 downto 32);
                                    integrals(idx) := (others=> '0');
                                    idx := idx + 1;
                                end loop;
                                autozero_reg <= std_logic_vector(resize(autozero_sums(0) srl 40, 32));
                                state := STATE_CONFIGURED;
                            end if;
                            if stop_stream = '1' then
                                state := STATE_IDLE;
                            end if;
                               
                        when STATE_CONFIGURED =>
                            if stop_stream = '1' then
                                 state := STATE_IDLE;
                            end if;
                    end case;
                else
                    data_present := '0';
                end if;
            end if;
            
            if falling_edge(aclk)  then
                case state1 is
                    when STATE_OUT_IDLE =>
                        m_axis_tvalid <= '0';
                        if start_stream = '1' then
                            idx1 := 0;
                            while(idx1 < C_NUM_CHANNELS) loop
                                prev_data(idx1) := (others => '0');
                                prev_sampled(idx1) := (others => '0');
                                idx1 := idx1 + 1;
                            end loop;
                            freq_count := (others => '0');
                            state1 := STATE_OUT_WAIT;
                        end if;
                        idx1 := 0;
                    when STATE_OUT_WAIT =>
                        m_axis_tvalid <= '0';
                        if data_present = '1' then
                            idx1 := 0;
                            while(idx1 < C_NUM_CHANNELS) loop
                                prev_data(idx1) := prev_data(idx1) + resize(in_data(idx1),32);
                                idx1 := idx1 + 1;
                            end loop;
                            freq_count := freq_count + 1;
                            if freq_count = signed(freq_div_reg) then
                                idx1 := 0;
                                state1 := STATE_PREPARE_OUT;
                                freq_count := (others => '0');
                            end if;
                        end if;
                    when STATE_PREPARE_OUT =>
                        m_axis_tvalid <= '0';
                        idx1 := 0;
                        state1 := STATE_OUT_CHANS;
                    when STATE_OUT_INTEGRALS =>
                        curr_out_integral := std_logic_vector(integrals(idx1));
                      --  m_axis_tdata <= curr_out_integral(39 downto 8);
                        ----prova
                        if m_axis_tready = '1' then
                            --m_axis_tdata <= std_logic_vector(to_signed(idx1, 32));
                            m_axis_tdata <= curr_out_integral(58 downto 27);
                            m_axis_tvalid <= '1';
                            idx1 := idx1 + 1;
                            if idx1 = C_NUM_CHANNELS then
                                 if stop_stream = '1' then
                                    state1 := STATE_OUT_IDLE;
                                else
                                    state1:= STATE_OUT_WAIT;
                                end if;
                            end if;
                        else
                            m_axis_tvalid <= '0';
                        end if;
                    when STATE_OUT_CHANS =>
                        curr_out_data := prev_data(idx1) - prev_sampled(idx1);
                        prev_sampled(idx1) := prev_data(idx1);
                        if m_axis_tready = '1' then 
                            idx1 := idx1 + 1;
                            m_axis_tdata <= std_logic_vector(curr_out_data);
                            --m_axis_tdata <= std_logic_vector(to_signed(idx1, 32));
                            m_axis_tvalid <= '1';
                            if idx1 = C_NUM_CHANNELS then
                                state1 := STATE_OUT_INTEGRALS;
                                idx1 := 0;
                            end if;
                        else
                            m_axis_tvalid <= '0';
                        end if;
                end case;
            end if;
         end process;   
    
   end implementation;
    
  