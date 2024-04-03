/*------------------------------------------------------------------------------
 * File          : KNN_PE.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : Sep 26, 2023
 * Description   : knn pe 1
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module KNN_PE  (
			input 		CLK,RESETn,
			input [1:0] control,
			input [31:0] sample_data,
			input classify_enable,// turn true when the new sample is ready to be classified 
			
			output sample_classification,
			output classify_sample_done // Done with the specific sample.
			);
	
	//============================================================================================================================//
	//--------------Internal variables---------------- 
	reg [7:0] curr_address;		

	reg cs_control;
	reg we_control;
	reg oe_control;
	
	reg [2:0] i;
	reg [2:0] j;
	reg [2:0] t;
	
	
	wire [32:0] curr_training_sample_wire;
	reg		curr_training_sample_c;
	reg 	sortEn;
	reg 	voteEn;
	
	wire sample_c; 		//to save the result of sort and vote in.
	reg new_sample;		//pulse that indicate for the s&v that we started handling a new sample
	
	reg [31:0] sample_data_d;
	
	reg signed [7:0] segment1 [3:0]; // Array to store 8-bit segments of sample_data
	reg signed [7:0] segment2 [3:0]; // Array to store 8-bit segments of curr_training_sample
	reg [7:0] abs_result[3:0];
	reg  [10:0] sum_stage;      // Final sum result for stage 
	wire [10:0] sum_result;
	
	//flags to indicate the start of the calculations of each stage
	
	wire start_idle_pos;
	wire start_fetch_pos;
	wire start_extract_pos;
	wire start_process_pos;
	wire start_mae_pos;
	wire start_sort_pos;
	wire start_vote_pos;
	wire start_done_pos;	
	
	//counter to count how many training_samples were processed thus far
	reg [8:0] count_training_samples;
	reg [8:0] counter;

	//============================================================================================================================//
	//--------------Instantiations---------------- 

	training_data_mem TrainingData_1 (.clk(CLK),.address(curr_address), .data(curr_training_sample_wire),.cs(cs_control),.we(we_control),.oe(oe_control));  
	
	sort_and_vote SortAndVote(.clk(CLK), .RESETn(RESETn), .curr_MAE(sum_result),.training_sample_c(curr_training_sample_c),.new_start(new_sample),.K_control(control[1:0]),.sortEnable(sortEn),
								.voteEnable(voteEn),.sample_classification(sample_c));
	
	//============================================================================================================================//
	//--------------FSM variables---------------- 
	
	enum logic [3:0] {Idle_st = 4'b0000, Fetch_st = 4'b0001, Extract_st = 4'b0010, Process_st = 4'b0011, Abs_st = 4'b0100, 
		MAE_Result_st = 4'b0101, Sort_st = 4'b0110, Vote_st = 4'b0111, Done_st = 4'b1000 } CUR_ST,CUR_ST_D,NEXT_ST;

	
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sample_data_d <=#1 32'b0;
		else sample_data_d <= #1 sample_data;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) begin
			// Reset logic here add #1
			CUR_ST <= Idle_st;
			count_training_samples <= 0;
   
		end 
		else begin
			// FSM logic
			CUR_ST <= #1 NEXT_ST;
			count_training_samples <= #1 counter;
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
					sortEn = 1'b0;
					voteEn = 1'b0;
				// Check conditions to transition to the next state and set control signals
				if (classify_enable == 1'b1) begin
					NEXT_ST = Fetch_st;
				end
				else NEXT_ST = Idle_st;
				end //end IDLE

			Fetch_st:
				begin 
					
					new_sample = 1'b0;
					sortEn = 1'b0;
					voteEn = 1'b0;
					
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
										
					NEXT_ST = Extract_st;
				
				end // end FETCH
			
			Extract_st:
				begin
					
					sortEn = 1'b0;
					voteEn = 1'b0;
					
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
					new_sample = 1'b0;
					
					NEXT_ST = Process_st;
				
				end //end EXTRACT
				
			Process_st:
				
				begin 
					
					sortEn = 1'b0;
					voteEn = 1'b0;
					
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
					
					NEXT_ST = Abs_st;				
				
				end // end PROCESS
			
			Abs_st:
			
				begin 
				
					sortEn = 1'b0;
					voteEn = 1'b0;
				
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
				
					NEXT_ST = MAE_Result_st;				
			
			end // end PROCESS
				
			MAE_Result_st:
				begin
									
					voteEn = 1'b0;
					
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
					
					NEXT_ST = Sort_st;
					sortEn = 1'b0; // Start sorting the result of the fetched sample				
				
				end // end MAE RES
			
			Sort_st:
				begin
					
					voteEn = 1'b0;
					sortEn = 1'b1;
					
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;
					
				// the sorting takes 1 cycle
				if (count_training_samples == 9'b100000000 ) NEXT_ST = Vote_st;
				else NEXT_ST = Fetch_st;
					
				end //end sort
			
			Vote_st:
				
				begin
					
					
					sortEn = 1'b0;
					voteEn = 1'b1;
					
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					new_sample = 1'b0;

					NEXT_ST = Done_st;
				
				end // end VOTE

			Done_st:
					begin
						
						sortEn = 1'b0;
						voteEn = 1'b0;
						
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
				sortEn = 1'b0;
				voteEn = 1'b0;

					end 

		endcase
	end
	
		//============================================================================================================================//
		//--------------Code Starts Here------------------ 
		

	
	assign start_idle_pos = (CUR_ST == Idle_st) && (CUR_ST_D != CUR_ST);
	assign start_fetch_pos = (CUR_ST == Fetch_st) && (CUR_ST_D != CUR_ST);
	assign start_extract_pos = (CUR_ST == Extract_st) && (CUR_ST_D != CUR_ST);
	assign start_process_pos = (CUR_ST == Process_st) && (CUR_ST_D != CUR_ST);
	assign start_abs_pos = (CUR_ST == Abs_st) && (CUR_ST_D != CUR_ST);
	assign start_mae_pos = (CUR_ST == MAE_Result_st) && (CUR_ST_D != CUR_ST);
	assign start_sort_pos = (CUR_ST == Sort_st) && (CUR_ST_D != CUR_ST);
	assign start_vote_pos = (CUR_ST == Vote_st) && (CUR_ST_D != CUR_ST);
	assign start_done_pos = (CUR_ST == Done_st) && (CUR_ST_D != CUR_ST);
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) counter <= #1 9'b0 ;
		else if (start_idle_pos) counter <= #1 9'b0; 
		else if(start_fetch_pos) counter <= #1 count_training_samples + 9'b1;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) curr_address <= #1 8'b0 ;
		else if (start_idle_pos) curr_address <= #1 8'b0; 
		else if(start_fetch_pos) curr_address <= #1 curr_address + 9'b1;
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) curr_training_sample_c <= #1 1'b0 ;
		else if(start_extract_pos) curr_training_sample_c <= #1 curr_training_sample_wire[32];
	end

		
		// Extract 8-bit segments from sample_data and curr_training_sample - turn into a seperate alwaysff
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) begin
			t <= 0;
			for (t = 0; t < 4; t = t + 1) begin
				segment1[t] <= #1 8'b0;
			end
		end
		else if(classify_enable) begin 
			t <= 0;
			for (t = 0; t < 4; t = t + 1) begin
				segment1[t] <= #1 sample_data_d[8*t +: 8];
			end
		end
		else if(start_idle_pos) begin
			t <= 0;
			for (t = 0; t < 4; t = t + 1) begin
				segment1[t] <= #1 sample_data[8*t +: 8];
			end
		end
	end
		
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) begin
			for (i = 0; i < 4; i = i + 1) begin
				segment2[i] <= #1 8'b0;
			end
		end
		else if(start_extract_pos) begin
			for (i = 0; i < 4; i = i + 1) begin
				segment2[i] <= #1 curr_training_sample_wire[8*i +: 8];
			end
		end
	end
		
		reg signed [7:0] temp_result [3:0];
		
		// Subtract corresponding 8-bit segments and calculate absolute value
		always @(posedge CLK or negedge RESETn) begin
			if (!RESETn) begin
				for (j = 0; j < 4; j = j + 1) begin
					temp_result[j] <= #1 8'b0;
				end
			end
			else if (start_process_pos) begin
				for (j = 0; j < 4; j = j + 1) begin
					temp_result[j] <= #1 segment1[j] - segment2[j]; // Subtract
				end
				
			end			
		end
		
		// Subtract corresponding 8-bit segments and calculate absolute value
		always @(posedge CLK or negedge RESETn) begin
			if (!RESETn) begin
				for (j = 0; j < 4; j = j + 1) begin
					abs_result[j] <= #1 8'b0;
				end
			end
			else if (start_abs_pos) begin
				for (j = 0; j < 4; j = j + 1) begin
					abs_result[j] <= #1 (temp_result[j] < 0) ? -temp_result[j] : temp_result[j];
				end
				
			end			
		end
		
		

		always @(posedge CLK or negedge RESETn) begin
			if (!RESETn) sum_stage <= #1 11'b0;
			else if (start_mae_pos) sum_stage <= #1 abs_result[0] + abs_result[1] + abs_result[2] + abs_result[3];//change to 3 + in the same always
		end


 	assign sum_result = sum_stage; // Assign the final sum to the output
	assign sample_classification = sample_c;
	assign classify_sample_done = start_done_pos;
	

endmodule