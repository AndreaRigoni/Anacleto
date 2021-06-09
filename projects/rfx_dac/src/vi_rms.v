`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2017 14:22:35
// Design Name: 
// Module Name: vi_rms
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vi_rms #
(
    parameter ADC_WIDTH = 14,
    parameter AXIS_TDATA_WIDTH = 32,
    parameter COUNT_WIDTH = 32,
    parameter DEC_COUNT = 10
    //parameter INTEG
    //parameter HIGH_THRESHOLD = -100,
    //parameter LOW_THRESHOLD = -150
)
(
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    input [AXIS_TDATA_WIDTH-1:0]   S_AXIS_IN_tdata,
    input                          S_AXIS_IN_tvalid,
    input                          S_AXIS_IN_tready,
    input                          clk,
    input                          rst,
    //input [COUNT_WIDTH-1:0]        Ncycles, //not needed
    input [COUNT_WIDTH-1:0]        counter_in,
    input signed [COUNT_WIDTH-1:0]        calib_CH1,
    input signed [COUNT_WIDTH-1:0]        calib_CH2,
    //input [COUNT_WIDTH-1:0]        count_ph_in, //not needed 
 	output reg [COUNT_WIDTH-1:0]        V_rms_out,
	output reg [COUNT_WIDTH-1:0]        I_rms_out,
    output [AXIS_TDATA_WIDTH-1:0]       S_AXIS_OUT_tdata,
    output                              S_AXIS_OUT_tvalid,
    input                               S_AXIS_OUT_tready
);

wire signed [COUNT_WIDTH-1:0]        dataV1;//, dataV2;
reg  signed [COUNT_WIDTH-1:0]        V_rms_nxt=0;
reg  signed [COUNT_WIDTH-1:0]        integV=0, integV_nxt=0, count_reg_in=0;
reg  [COUNT_WIDTH-1:0]             master_count=0, master_count_nxt=0;
reg  signed [COUNT_WIDTH-1:0]        dtV1=0, dt_CH1=0, dt_nxt_CH1=0; 

wire signed [COUNT_WIDTH-1:0]        dataI1;//, dataI2;
reg  signed [COUNT_WIDTH-1:0]        I_rms_nxt=0;
reg  signed [COUNT_WIDTH-1:0]        integI=0, integI_nxt=0;
reg  signed [COUNT_WIDTH-1:0]        dtI1=0, dt_CH2=0, dt_nxt_CH2=0;
reg  [31:0]                           dec_counter=0, dec_counter_nxt=0;


// Extract only the 14-bits of ADC data 
assign  dataV1[COUNT_WIDTH-1:0] = S_AXIS_IN_tdata[ADC_WIDTH-1:0]; //Voltage
//assign  dataV1[COUNT_WIDTH-1:0] = {{COUNT_WIDTH-ADC_WIDTH+1 {S_AXIS_IN_tdata[ADC_WIDTH-1]}}, S_AXIS_IN_tdata[ADC_WIDTH-2:0]}; //Voltage
assign  dataI1[COUNT_WIDTH-1:0] = S_AXIS_IN_tdata[AXIS_TDATA_WIDTH/2+ADC_WIDTH-2:AXIS_TDATA_WIDTH/2];
//assign  dataI1[COUNT_WIDTH-1:0] = {{COUNT_WIDTH-ADC_WIDTH+1 {S_AXIS_IN1_tdata[ADC_WIDTH-1]}}, S_AXIS_IN1_tdata[ADC_WIDTH-2:0]};

//assign  dataI1[ADC_WIDTH-2:0] = S_AXIS_IN1_tdata[ADC_WIDTH-2:0]; //Current
//assign  dataV1[COUNT_WIDTH-1] = S_AXIS_IN_tdata[ADC_WIDTH-1]; //sign assignement
//assign  dataI1[COUNT_WIDTH-1] = S_AXIS_IN1_tdata[ADC_WIDTH-1]; //sign assignement
//assign  dataV2 = S_AXIS_IN_tdata[ADC_WIDTH-1:0];
//assign  dataI2= S_AXIS_IN_tdata[2*ADC_WIDTH+1:ADC_WIDTH+2];
assign S_AXIS_IN_tready = 1;
assign S_AXIS_OUT_tdata[AXIS_TDATA_WIDTH-1:0] = S_AXIS_IN_tdata[AXIS_TDATA_WIDTH-1:0];
assign S_AXIS_OUT_tvalid = S_AXIS_IN_tvalid;


always @(posedge clk)
begin
//Voltage reset
if (~rst)
begin 
    integV <= 0;
    master_count <= 0;
    V_rms_out <= 0;
    //Input values reset:
    dtV1 <= 0; 
    dt_CH1 <= 0;
    //dtV2 <= 0;
    integI <= 0;
    I_rms_out <= 0;
    dtI1 <= 0;
    dt_CH2 <= 0;
    //dec_counter_nxt <= 0;
    dec_counter <= 0;
end
//Voltage update:
else
begin
    count_reg_in <= counter_in;
    integV <= integV_nxt;
    master_count <= master_count_nxt;
    V_rms_out <= V_rms_nxt;
    //Fetching of new V data from ADC:
    dtV1 <= dataV1+calib_CH1; //+123
    dt_CH1 <= dt_nxt_CH1;
    //dtV2 <= dataV2;
    integI <= integI_nxt;
    I_rms_out <= I_rms_nxt;
    //Fetching of new I data from ADC:
    dtI1 <= dataI1+calib_CH2;// + 23;
    dt_CH2 <= dt_nxt_CH2;
    dec_counter <= dec_counter_nxt;
end
end

always @*
begin
//dec_counter_nxt = dec_counter + 1;
//Voltage integrator
dt_nxt_CH1=dtV1*dtV1;
dt_nxt_CH2=dtI1*dtI1;
integV_nxt=integV;
integI_nxt=integI;
dec_counter_nxt = dec_counter + 1;
if (dec_counter >= DEC_COUNT-1)
begin
 integV_nxt=integV+dt_CH1;
 integI_nxt=integI+dt_CH2;
 dec_counter_nxt = 0;
end
//else
//begin
// integV_nxt=integV;
// integI_nxt=integI;
// dec_counter_nxt = dec_counter + 1;
//end
//Wave period counter 
master_count_nxt = master_count+1;
//RMS value update at each clk cycle
V_rms_nxt=V_rms_out;
//Current integrator
//dt_nxt_CH2=dtI1*dtI1;
//if (dec_counter == DEC_COUNT)
// integI_nxt=integI+dt_CH2;
//else
// integI_nxt=integI;
//RMS value update at each clk cycle
I_rms_nxt=I_rms_out;
//RMS value update at the end of the period
if (master_count_nxt >= count_reg_in)
begin
    //New Vrms value
    V_rms_nxt = integV_nxt;
    //integrator reset
    //integV = 0;
    integV_nxt = 0;
    //New Irms value
    I_rms_nxt = integI_nxt;
    //Integrator reset
    //integI = 0;
    integI_nxt = 0;
    //Counter reset
    //master_count = 0;
    master_count_nxt = 0;
end
end

endmodule
