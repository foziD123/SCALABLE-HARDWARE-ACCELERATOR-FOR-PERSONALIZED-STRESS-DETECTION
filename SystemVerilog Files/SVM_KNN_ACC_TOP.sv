/*------------------------------------------------------------------------------
 * File          : SVN_KNN_ACC_TOP.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : May 21, 2023
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module SVM_KNN_ACC_TOP  (
	input CLK,RESETn,
	input Enable,	
	input write_TOP,					
	input [31:0]Address,
	input [31:0] write_data,
	//changed 17/1 --> check
	//output [31:0] read_data,
	//output ready,
	output valid,
	output Stress_Out
);

// ----------------------------------------------------------------------
//              Wires and Regs
// ----------------------------------------------------------------------
reg [31:0] read_data;
reg ready;

wire [1:0] start;
wire KNN_stress_out;
wire KNN_done;
wire SVM_stress_out;
wire SVM_done;
wire reg_operation;		//0 --> OR | 1--> AND
reg KNN_res;
reg SVM_res;
reg KNN_valid;
reg SVM_valid;
// ----------------------------------------------------------------------
//              Instantiations
// ----------------------------------------------------------------------

SVM_KNN_ACC_REGFILE RegFile(.PCLK(CLK),
							.PRESETn(RESETn),
							.PENABLE(Enable),
							.PWRITE_regFile(write_TOP),
							.PADDR(Address),
							.PWDATA(write_data),
							.PRDATA(read_data),
							.PREADY(ready),
							.logic_op(reg_operation),
							.reg_start(start));

KNN_ACC_CORE knn(.CLK(CLK),.RESETn(RESETn), .control(read_data),.reg_start(start[0]), .KNN_done(KNN_done),.KNN_classification(KNN_stress_out));
SVM_ACC_CORE svm(.CLK(CLK),.RESETn(RESETn), .control(read_data),.reg_start(start[1]), .SVM_done(SVM_done),.SVM_classification(SVM_stress_out));


//=================ADDED 12/12===========================
always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) KNN_res <= #1 1'b0;
	else if (start[0] == 1'b0) KNN_res <= #1 1'b0;
	else if (KNN_stress_out) KNN_res <= #1 1'b1;
end

always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) SVM_res <= #1 1'b0;
	else if (start[1] == 1'b0) SVM_res <= #1 1'b0;
	else if (SVM_stress_out) SVM_res <= #1 1'b1;
end

always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) KNN_valid <= #1 1'b0;
	else if (start[0] == 1'b0) KNN_valid <= #1 1'b0;
	else if (KNN_done) KNN_valid <= #1 1'b1;
end

always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) SVM_valid <= #1 1'b0;
	else if (start[1] == 1'b0) SVM_valid <= #1 1'b0;
	else if (SVM_done) SVM_valid <= #1 1'b1;
end


//=======================================================


//we need to handle the APB_choise of and/or
//assign Stress_Out = KNN_res && SVM_res;
assign Stress_Out = (start[0] == 1'b0 || start[1] == 1'b0 || !reg_operation) ? (KNN_res || SVM_res) : (KNN_res && SVM_res);

assign valid = (start[0] == 1'b0 || start[1] == 1'b0 || !reg_operation) ? (KNN_valid || SVM_valid) : (KNN_valid && SVM_valid);


endmodule