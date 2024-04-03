/*------------------------------------------------------------------------------
 * File          : SVM_KNN_ACC_TB.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : May 21, 2023
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

//            
// ----------------------------------------------------------------------
module SVM_KNN_ACC_TB() ;

// ----------------------------------------------------------------------
//             Wires and Regs
// ----------------------------------------------------------------------
reg 	clk;
reg		resetn;
reg  	WRITE; 
reg 	Enable;
reg [31:0] address;
reg [31:0] write_data;
reg valid_done;
reg out;


// ----------------------------------------------------------------------
//             Instantiation
// ----------------------------------------------------------------------
SVM_KNN_ACC_TOP top(.CLK(clk),
					.RESETn(resetn),
					.Enable(Enable),
					.write_TOP(WRITE),
					.Address(address),
					.write_data(write_data),
					.valid(valid_done),
					.Stress_Out(out));

// ----------------------------------------------------------------------
//             Clock generator
// ----------------------------------------------------------------------
initial
	begin
		clk <= 0;
		forever #2.5 clk = ~clk;
	end

// ----------------------------------------------------------------------
//             Test Pattern
// ----------------------------------------------------------------------
initial begin
	
	$readmemb("sv_binary.mem",top.svm.PE1.SV_1.mem);
	$readmemb("sv_binary.mem",top.svm.PE2.SV_1.mem);
	$readmemb("sv_binary.mem",top.svm.PE3.SV_1.mem);
	$readmemb("sv_binary.mem",top.svm.PE4.SV_1.mem);
	$readmemb("temp_input_buffer_data_binary.mem",top.svm.Input_Buffer_2.mem);
	$readmemb("temp_training_data_binary.mem",top.knn.PE1.TrainingData_1.mem);
	$readmemb("temp_training_data_binary.mem",top.knn.PE2.TrainingData_1.mem);
	$readmemb("temp_training_data_binary.mem",top.knn.PE3.TrainingData_1.mem);
	$readmemb("temp_training_data_binary.mem",top.knn.PE4.TrainingData_1.mem);
	$readmemb("temp_input_buffer_data_binary.mem",top.knn.Input_Buffer_1.mem);
	
	initiate_all;
	#100
	resetn = 1'b1;		
	//-----------ADDED 7/12----------------
	//WRITE TO REG_START 0 to start
	@(posedge clk or negedge resetn);		
	write_to_reg(32'h0978, 32'h0 ,1'b1,1'b1);
	//-------------------------------------		
	
	#100
	@(posedge clk or negedge resetn);
	//write_to_reg(32'h0970, 32'h181223EA ,1'b1,1'b1); // th = 250 --> knn_c = 1, th = 192 --> sv_c = 1.
	write_to_reg(32'h0970, 32'h18123456 ,1'b1,1'b1); // th = 1300 --> th>1024 --> knn_c = 0, th = 192 --> sv_c = 1.
	//write_to_reg(32'h0970, 32'h579223EA ,1'b1,1'b1); // th = 250 --> knn_c = 1, th = 700 --> sv_c = 0.
	#100
	@(posedge clk or negedge resetn);
	read_reg(32'h0970 ,1'b1,1'b0);
	#100
	@(posedge clk or negedge resetn); //REG OPERATION OR-0 | AND-1		
	write_to_reg(32'h0974, 32'h0 ,1'b1,1'b1);
	#100
	@(posedge clk or negedge resetn);
	read_reg(32'h0974 ,1'b1,1'b0);
	#100
	//-----------ADDED 7/12----------------
	//WRITE TO REG_START: 01-KNN | 10-SVM | 11-both
	@(posedge clk or negedge resetn);		
	write_to_reg(32'h0978, 32'h3 ,1'b1,1'b1);
	//-------------------------------------
	
end
	
// ----------------------------------------------------------------------
//             Tasks
// ----------------------------------------------------------------------
 
 task initiate_all;
	 begin
		 clk = 1'b0;
		 resetn = 1'b0;
		 Enable = 1'b0;
		 WRITE = 1'b0;
		 address = 32'b0;
		 write_data = 32'b0;
				 
	 end
 endtask
 
 task write_to_reg(input [31:0] reg_add, input [31:0] reg_data, input enable, input write);
	 begin
		 @(posedge clk or negedge resetn);								
		 address =  reg_add;
		 write_data = reg_data;
		 WRITE = write;
		 Enable = enable;
		 @(posedge clk or negedge resetn);
		 #1
		 address =  32'h0;
		 write_data = 32'h0;
		 WRITE = 1'b0;
		 Enable = 1'b0;
	 end
 endtask
 
 
 task read_reg(input [31:0] reg_add, input enable, input write);
	 begin
		 @(posedge clk or negedge resetn);								
		 address =  reg_add;
		 WRITE = write;
		 Enable = enable;
		 @(posedge clk or negedge resetn);
		 #1
		 address =  32'h0;
		 WRITE = 1'b0;
		 Enable = 1'b0;
		
		 
	 end
 endtask
 
 

endmodule