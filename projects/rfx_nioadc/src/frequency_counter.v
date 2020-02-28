`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Anton Potocnik
// 
// Create Date: 07.01.2017 22:50:51
// Design Name: 
// Module Name: frequency_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  Reciprotial method 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.1 - Reciprotial method implemented
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module frequency_counter #
(
    parameter ADC_WIDTH = 14,
    parameter AXIS_TDATA_WIDTH = 32,
    parameter COUNT_WIDTH = 32
    //The subsequent params MUST be choosen considering the calibration ADC offset:
//    parameter HIGH_THRESHOLD_CH1 = -122,//-100, //calibration result is -123
//    parameter LOW_THRESHOLD_CH1 = -124,//-140,
//    parameter HIGH_THRESHOLD_CH2 = -22,//0, //calibration result is -23
//    parameter LOW_THRESHOLD_CH2 = -24,//-40,
    //parameter LOW_SAT = 104,
    //parameter HIGH_SAT = 157
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input  [AXIS_TDATA_WIDTH-1:0]   S_AXIS_IN_tdata,
    input                          S_AXIS_IN_tvalid,
    output                         S_AXIS_IN_tready,
    input                          clk,
    input                          rst,
    input [COUNT_WIDTH-1:0]        Ncycles,
    input signed [COUNT_WIDTH-1:0]        HIGH_THRESHOLD_CH1,
    input signed [COUNT_WIDTH-1:0]        LOW_THRESHOLD_CH1,
    input signed [COUNT_WIDTH-1:0]        HIGH_THRESHOLD_CH2,
    input signed [COUNT_WIDTH-1:0]        LOW_THRESHOLD_CH2,
	output reg [COUNT_WIDTH-1:0]       counter_output,
	output reg [COUNT_WIDTH-1:0]       count_ph_out,
	output reg [COUNT_WIDTH-1:0]       counter_outputI,
    output  [AXIS_TDATA_WIDTH-1:0]     S_AXIS_OUT_tdata,
    output                             S_AXIS_OUT_tvalid,
    input                              S_AXIS_OUT_tready
	
);

reg inputValid; //Records that the input was valid the previoud posedge clk
// Voltage management signlas
reg signed [ADC_WIDTH-1:0]    data=0, data_nxt=0, data_reg=0, data_reg_c=0;
reg                            state, state_next;
reg [COUNT_WIDTH-1:0]          counter=0, counter_next=0;
reg [COUNT_WIDTH-1:0]          counter_output_next=0;
reg [COUNT_WIDTH-1:0]          cycle=0, cycle_next=0;
reg [COUNT_WIDTH-1:0]          cycle_buf=0, cycle_buf_nxt=0;

// Current management signals
reg signed [ADC_WIDTH-1:0]    dataI=0, dataI_nxt=0, dataI_reg=0, dataI_reg_c=0;
reg                            stateI, state_nextI;
reg [COUNT_WIDTH-1:0]          counterI=0, counter_nextI=0;
reg [COUNT_WIDTH-1:0]          counter_output_nextI=0;
reg [COUNT_WIDTH-1:0]          cycleI=0, cycle_nextI=0, data_buf=0, data_buf_nxt=0;
reg [COUNT_WIDTH-1:0]   count_ph=0, count_ph_next=0;
reg [COUNT_WIDTH-1:0]   count_ph_out_next=0;
//filter register
reg [COUNT_WIDTH-1:0]   count_filt_out_CH1=0, count_filt_out_CH1_nxt=0;
reg [COUNT_WIDTH-1:0]   count_filt_out_CH2=0, count_filt_out_CH2_nxt=0;
//reg [COUNT_WIDTH-1:0]   low_sat_cycle = LOW_SAT, low_sat_cycle_nxt = LOW_SAT;
//reg [COUNT_WIDTH-1:0]   high_sat_cycle = HIGH_SAT, high_sat_cycle_nxt = HIGH_SAT;

assign S_AXIS_IN_tready = 1;
assign S_AXIS_OUT_tdata[AXIS_TDATA_WIDTH-1:0] = S_AXIS_IN_tdata[AXIS_TDATA_WIDTH-1:0];
assign S_AXIS_OUT_tvalid = S_AXIS_IN_tvalid;
// Wire AXIS IN to AXIS OUT
//assign  M_AXIS_OUT_tdata[ADC_WIDTH-1:0] = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
//assign  M_AXIS_OUT_tdata[AXIS_TDATA_WIDTH-1:0] = S_AXIS_IN_tdata[AXIS_TDATA_WIDTH-1:0];
//assign  M_AXIS_OUT_tvalid = S_AXIS_IN_tvalid;
//assign  M_AXIS_OUT1_tdata[AXIS_TDATA_WIDTH-1:0] = S_AXIS_IN1_tdata[AXIS_TDATA_WIDTH-1:0];
//assign  M_AXIS_OUT1_tvalid = S_AXIS_IN1_tvalid;

// Extract only the 14-bits of ADC data 
//assign  data[ADC_WIDTH-1:0] = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
//assign  dataI[ADC_WIDTH-1:0] = S_AXIS_IN1_tdata[ADC_WIDTH-1:0];
//assign low_sat_cycle = Ncycles * LOW_SAT;
//assign high_sat_cycle = Ncycles * HIGH_SAT;
    //Original code:
    
//    wire signed [ADC_WIDTH-1:0]    data;
//    reg                            state, state_next;
//    reg [COUNT_WIDTH-1:0]          counter=0, counter_next=0;
//    reg [COUNT_WIDTH-1:0]          counter_output=0, counter_output_next=0;
//    reg [COUNT_WIDTH-1:0]          cycle=0, cycle_next=0;
    
    
//    // Wire AXIS IN to AXIS OUT
//    assign  M_AXIS_OUT_tdata[ADC_WIDTH-1:0] = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
//    assign  M_AXIS_OUT_tvalid = S_AXIS_IN_tvalid;
    
//    // Extract only the 14-bits of ADC data 
//    assign  data = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
always @(posedge clk) 
begin
data_reg_c <= data_reg;
dataI_reg_c <= dataI_reg;
if (S_AXIS_IN_tvalid) begin
    data_reg <= S_AXIS_IN_tdata[ADC_WIDTH-1:0];
    dataI_reg <= S_AXIS_IN_tdata[AXIS_TDATA_WIDTH/2+ADC_WIDTH - 1:AXIS_TDATA_WIDTH/2];
end

//dataI_reg <= S_AXIS_IN1_tdata[ADC_WIDTH-1:0];
data <= data_nxt;
dataI <= dataI_nxt;

inputValid <= S_AXIS_IN_tvalid;
end    

    


always @*
begin
data_nxt = (data_reg - data_reg_c + data) >>> 1;//(S_AXIS_IN_tdata[ADC_WIDTH-1:0] - data);
dataI_nxt = (dataI_reg - dataI_reg_c + dataI) >>> 1;//(S_AXIS_IN1_tdata[ADC_WIDTH-1:0] - dataI);
end

    // Handling of the state buffer for finding signal transition at the threshold
    always @(posedge clk) 
    begin
        if (~rst) 
        begin
            state <= 1'b0;
            //low_sat_cycle <= LOW_SAT;
            //high_sat_cycle <= HIGH_SAT;
        end
        else
        begin
            state <= state_next;
            //low_sat_cycle <= low_sat_cycle_nxt;
            //high_sat_cycle <= high_sat_cycle_nxt;
            //data_buf <= data_buf_nxt;
        end
    end
    
    
    always @*            // logic for state buffer
    begin
        if (data > HIGH_THRESHOLD_CH1)
            state_next = 1;
        else if (data < LOW_THRESHOLD_CH1)
            state_next = 0;
        else
            state_next = state;
        //low_sat_cycle_nxt = Ncycles * LOW_SAT;
        //high_sat_cycle_nxt = Ncycles * HIGH_SAT;
        //data_buf_nxt = data;
    end
    



    // Handling of counter, counter_output and cycle buffer
    always @(posedge clk) 
    begin
        if (~rst) 
        begin
            counter <= 0;
            counter_output <= 0;
            cycle <= 0;
        end
        else
        begin
            counter <= counter_next;
            //cycle_buf <= cycle_buf_nxt;
            cycle <= cycle_next;
            counter_output <= counter_output_next;
//            if (counter_output_next >= low_sat_cycle && counter_output_next <= high_sat_cycle)
//            begin
//             counter_output <= counter_output_next;
//            end
//            else
//            begin
//            if (counter_output_next < low_sat_cycle)
//            begin
//             counter_output <= low_sat_cycle;
//            end
//            if (counter_output_next > high_sat_cycle)
//            begin
//             counter_output <= high_sat_cycle;
//            end
//            end            
        end
    end


    always @* // logic for counter, counter_output, and cycle buffer
    begin
        counter_next = counter + 1; // increment on each clock cycle
        counter_output_next = counter_output;
        cycle_next = cycle; 
        //cycle_buf_nxt=cycle;       
        if (state < state_next) // high to low signal transition
        begin
            //cycle_buf_nxt=cycle;
            cycle_next = cycle + 1; // increment on each signal transition
            if (cycle >= Ncycles-1) 
            begin
                cycle_next = 0;
                counter_output_next = (counter_output + counter) >>> 1; //2 sample running mean  
                counter_next = 0;                              
                //cycle_buf_nxt = 0;
            end
           //else
//            begin
             //cycle_next = cycle + 1; // increment on each signal transition
//             //cycle_buf_nxt = cycle;
//             counter_next = counter + 1; 
//             counter_output_next = counter_output;
//            end
        end
        //else
         //cycle_next = cycle;
//        begin
//         counter_next = counter + 1; // increment on each clock cycle
//         counter_output_next = counter_output;
//         cycle_next = cycle;
//        end
   end

//Modified code: TO DO;
// 1- Implement V and I frequency counter;
// 2- Implement a phase counter, for V-I phase;
// 3- Porperly interface new signals with other modules.

//Managing of current signal and phase

// Handling of the state buffer for finding signal transition at the threshold
always @(posedge clk) 
begin
    if (~rst) 
        stateI <= 1'b0;
    else
        stateI <= state_nextI;
end 


always @*            // logic for state buffer
begin
    if (dataI > HIGH_THRESHOLD_CH2) //replicated logic for current meas
        state_nextI = 1;
    else if (dataI < LOW_THRESHOLD_CH2)
        state_nextI = 0;
    else
        state_nextI = stateI;
end




// Handling of counter, counter_output and cycle buffer
always @(posedge clk) 
begin
    if (~rst) 
    begin
        counterI <= 0;
        counter_outputI <= 0;
        cycleI <= 0;
        count_ph <=0;
        count_ph_out <=0;
    end
    else
    begin
        counterI <= counter_nextI;
        counter_outputI <= counter_output_nextI;
//        if (counter_output_nextI >= low_sat_cycle && counter_output_nextI <= high_sat_cycle)
//        begin
//         counter_outputI <= counter_output_nextI;
//        end
//        else
//        begin
//        if (counter_output_nextI < low_sat_cycle)
//        begin
//         counter_outputI <= low_sat_cycle;
//        end
//        if (counter_output_nextI > high_sat_cycle)
//        begin
//         counter_outputI <= high_sat_cycle;
//        end
//        end
        cycleI <= cycle_nextI;
        count_ph <= count_ph_next;
        count_ph_out <= count_ph_out_next;
    end
end


always @* // logic for counter, counter_output, and cycle buffer
begin
    //logic replication
    counter_nextI = counterI + 1; // increment on each clock cycle
        counter_output_nextI = counter_outputI;
        cycle_nextI = cycleI;
        //phase shift calculation:
        //count_ph_next = counter;//-counterI;
        count_ph_out_next=count_ph_out;
        if (stateI < state_nextI) // high to low signal transition
        begin
            cycle_nextI = cycleI + 1; // increment on each signal transition
            if (cycleI >= Ncycles-1) 
            begin
                counter_nextI = 0;
                counter_output_nextI = (counter_outputI + counterI) >>> 1; //2 sample running mean
                cycle_nextI = 0;
                count_ph_out_next = counter;//count_ph_next; //phase update: if negative, current anticipate voltage 
            end
            //else
             //cycle_nextI = cycleI + 1; // increment on each signal transition
        end
        
end

//4 sample running mean filter
//always @(posedge clk)
//begin
//if (counter_output_next != counter_output)
//begin
// count_filt_out_CH1 <= count_filt_out_CH1_nxt >>> 2; //division by 4
//end
//else
//begin
// count_filt_out_CH1 <= count_filt_out_CH1_nxt;
//end
//end

//always @*
//begin
//if (counter_output_next != counter_output)
// count_filt_out_CH1_nxt = count_filt_out_CH1 + counter_output;
//else
// count_filt_out_CH1_nxt = count_filt_out_CH1;
//end

endmodule
