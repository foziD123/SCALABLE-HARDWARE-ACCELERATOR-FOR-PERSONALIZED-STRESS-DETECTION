/*------------------------------------------------------------------------------
 * File          : SVM_PE.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : Nov 14, 2023
 * Description   :
 *------------------------------------------------------------------------------*/

module SVM_PE(
	input 		CLK,RESETn,
	input signed [7:0] control,		// control [13:20] for determining bias
	input [31:0] sample_data,
	input classify_enable,		// turn true when the new sample is ready to be classified 
	
	output sample_classification,
	output classify_sample_done // Done with the specific sample.
);

	//============================================================================================================================//
	//--------------Internal variables---------------- 
	reg [5:0] curr_address;		

	reg cs_control;
	reg we_control;
	reg oe_control;

	wire [31:0] curr_support_vector;
	reg sample_c; 		//to save the result of sort and vote in.
	reg new_sample;
	
	// Define the support vectors for each feature and the bias
	// Adjust the values based on your specific support vectors and bias
	reg [31:0] sample_data_d;
	reg signed [7:0] support_vector_1; // Support vector for feature 1 - HR
	reg signed [7:0] support_vector_2; // Support vector for feature 2 - acc.x
	reg signed [7:0] support_vector_3; // Support vector for feature 3 - acc.y
	reg signed [7:0] support_vector_4; // Support vector for feature 4 - acc.z
	
	// extract the new sample data (32 bit) to 4 8 bit featurs
	reg signed [7:0] sample_data_1; //  feature 1 - HR
	reg signed [7:0] sample_data_2; //  feature 2 - acc.x
	reg signed [7:0] sample_data_3; //  feature 3 - acc.y
	reg signed [7:0] sample_data_4; //  feature 4 - acc.z
	
	//registers for holding the intermediate dot product results
	reg signed [31:0] dot_result_1;
	reg signed [31:0] dot_result_2;
	reg signed [31:0] dot_result_3;
	reg signed [31:0] dot_result_4;
	
	//register for accumulating the dot product results 
	reg signed [31:0] internal_sum_1;
	reg signed [31:0] internal_sum_2;
	reg signed [31:0] internal_sum_3;
	reg signed [31:0] internal_sum_4;
	
	
	wire start_idle_pos;
	wire start_fetch_pos;
	wire start_extract_pos;
	wire start_process_pos;
	wire start_internal_sum_pos;
	wire start_bias_pos;
	wire start_done_pos;	
	
	//counter to count how many support_vectors were processed thus far
	reg [6:0] count_support_vectors;
	reg [6:0] counter;

	//============================================================================================================================//
	//--------------Instantiations---------------- 

	support_vectors SV_1 (.clk(CLK),.address(curr_address), .data(curr_support_vector),.cs(cs_control),.we(we_control),.oe(oe_control));  
	
	//============================================================================================================================//
	//---------------FSM-------------------------
	
	enum logic [2:0] {Idle_st = 3'b000, Fetch_st = 3'b001, Extract_st = 3'b010, Process_st = 3'b011, 
		Internal_sum_st = 3'b100, Bias_st = 3'b101, Done_st = 3'b110} CUR_ST,CUR_ST_D,NEXT_ST;
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) begin
			// Reset logic here add #1
			CUR_ST <= Idle_st;
			count_support_vectors <= 0;
   
		end 
		else begin
			// FSM logic
			CUR_ST <= #1 NEXT_ST;
			count_support_vectors <= #1 counter;
		end
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) CUR_ST_D <= #1 Idle_st;
		else CUR_ST_D <= #1 CUR_ST;
	end
	
	always_comb
	begin
			
		case (CUR_ST)
			Idle_st:
				begin
					
					new_sample = 1'b1;
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					
					// Check conditions to transition to the next state and set control signals
					if (classify_enable == 1'b1) NEXT_ST = Fetch_st;
					else NEXT_ST = Idle_st;
					
				end //end IDLE

			Fetch_st:
				begin 
					
					new_sample = 1'b0;
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
										
					NEXT_ST = Extract_st;
				
				end // end FETCH
			
			Extract_st:
				begin
					
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
					new_sample = 1'b0;
					
					NEXT_ST = Process_st;
				
				end //end EXTRACT
				
			Process_st:
				
				begin 
					
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
					
					NEXT_ST = Internal_sum_st;				
				
				end // end PROCESS
				
			Internal_sum_st:
				begin
									
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
					
					if ( count_support_vectors == 7'b1000000 ) NEXT_ST = Bias_st;
					else NEXT_ST = Fetch_st;
				
				end // end internal sum
			
			Bias_st:
				begin

					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
								
					NEXT_ST = Done_st; 
					
				end //end bias

			Done_st:
					begin
						
						cs_control = 1'b0;
						we_control = 1'b0;
						oe_control = 1'b0;
						new_sample = 1'b0;
						
						NEXT_ST = Idle_st;
					
					end//end done
				
			default:
					begin
						NEXT_ST = Idle_st;
						cs_control = 1'b0;
						we_control = 1'b0;
						oe_control = 1'b0;
						new_sample = 1'b0;

					end 

		endcase
	end
	
	
	//============================================================================================================================//
	//--------------Code Starts Here------------------ 
	
	//Assuming that we have one sample from the input buffer(sample_data) and one sample from training_data_mem (curr_training_sample).

	assign start_idle_pos = (CUR_ST == Idle_st) && (CUR_ST_D != CUR_ST);
	assign start_fetch_pos = (CUR_ST == Fetch_st) && (CUR_ST_D != CUR_ST);
	assign start_extract_pos = (CUR_ST == Extract_st) && (CUR_ST_D != CUR_ST);
	assign start_process_pos = (CUR_ST == Process_st) && (CUR_ST_D != CUR_ST);
	assign start_internal_sum_pos = (CUR_ST == Internal_sum_st) && (CUR_ST_D != CUR_ST);
	assign start_bias_pos = (CUR_ST == Bias_st) && (CUR_ST_D != CUR_ST);
	assign start_done_pos = (CUR_ST == Done_st) && (CUR_ST_D != CUR_ST);
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_d <=#1 32'b0;
		else sample_data_d <= #1 sample_data;
	end

always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) counter <= #1 7'b0 ;
	else if (start_idle_pos) counter <= #1 7'b0; 
	else if(start_fetch_pos) counter <= #1 count_support_vectors + 7'b0000001;
end

always @(posedge CLK or negedge RESETn) begin
	if (!RESETn) curr_address <= #1 6'b0 ;
	else if (start_idle_pos) curr_address <= #1 6'b0; 
	else if(start_fetch_pos) curr_address <= #1 curr_address + 6'b000001;
end


	// Extract 4 8-bit segments from curr_support_vectotr
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) support_vector_1 <= #1 8'b0;
		else if(start_extract_pos) support_vector_1 <= #1 curr_support_vector[7:0];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) support_vector_2 <= #1 8'b0;
		else if(start_extract_pos) support_vector_2 <= #1 curr_support_vector[15:8];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) support_vector_3 <= #1 8'b0;
		else if(start_extract_pos) support_vector_3 <= #1 curr_support_vector[23:16];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) support_vector_4 <= #1 8'b0;
		else if(start_extract_pos) support_vector_4 <= #1 curr_support_vector[31:24];
	end
	
	// Extract 4 8-bit segments from curr sample data
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_1 <= #1 8'b0;
		else if(classify_enable) sample_data_1 <= #1 sample_data_d[7:0];
		else if(start_idle_pos) sample_data_1 <= #1 sample_data[7:0];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_2 <= #1 8'b0;
		else if(classify_enable) sample_data_2 <= #1 sample_data_d[15:8];
		else if(start_idle_pos) sample_data_2 <= #1 sample_data[15:8];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_3 <= #1 8'b0;
		else if(classify_enable) sample_data_3 <= #1 sample_data_d[23:16];
		else if(start_idle_pos) sample_data_3 <= #1 sample_data[23:16];
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_4 <= #1 8'b0;
		else if(classify_enable) sample_data_4 <= #1 sample_data_d[31:24];
		else if(start_idle_pos) sample_data_4 <= #1 sample_data[31:24];
	end
	
	// dot product
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) dot_result_1 <= #1 32'b0;
		else if(start_fetch_pos) dot_result_1 <= #1 32'b0;
		else if (start_process_pos) dot_result_1 <= #1 support_vector_1 * sample_data_1;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) dot_result_2 <= #1 32'b0;
		else if(start_fetch_pos) dot_result_2 <= #1 32'b0;
		else if (start_process_pos) dot_result_2 <= #1 support_vector_2 * sample_data_2;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) dot_result_3 <= #1 32'b0;
		else if(start_fetch_pos) dot_result_3 <= #1 32'b0;
		else if (start_process_pos) dot_result_3 <= #1 support_vector_3 * sample_data_3;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) dot_result_4 <= #1 32'b0;
		else if(start_fetch_pos) dot_result_4 <= #1 32'b0;
		else if (start_process_pos) dot_result_4 <= #1 support_vector_4 * sample_data_4;
				
	end
	
	//sum of dot products
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) internal_sum_1 <= #1 32'b0;
		else if(start_idle_pos) internal_sum_1 <= #1 32'b0;
		else if (start_internal_sum_pos) internal_sum_1 <= #1 (dot_result_1 + internal_sum_1);
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) internal_sum_2 <= #1 32'b0;
		else if(start_idle_pos) internal_sum_2 <= #1 32'b0;
		else if (start_internal_sum_pos) internal_sum_2 <= #1 dot_result_2 + internal_sum_2;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) internal_sum_3 <= #1 32'b0;
		else if(start_idle_pos) internal_sum_3 <= #1 32'b0;
		else if (start_internal_sum_pos) internal_sum_3 <= #1 dot_result_3 + internal_sum_3;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) internal_sum_4 <= #1 32'b0;
		else if(start_idle_pos) internal_sum_4 <= #1 32'b0;
		else if (start_internal_sum_pos) internal_sum_4 <= #1 dot_result_4 + internal_sum_4;
	end
	
	// adding bias and classifying
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_c <= #1 1'b0;
		else if(start_idle_pos) sample_c <= #1 1'b0;
		else if (start_bias_pos) begin
			if (internal_sum_1 + internal_sum_2 + internal_sum_3 + internal_sum_4 + control > 0 ) sample_c <= #1 1'b1;
			else sample_c <= #1 1'b0;
		end
	end
	

assign sample_classification = sample_c;
assign classify_sample_done = start_done_pos;

	
endmodule
