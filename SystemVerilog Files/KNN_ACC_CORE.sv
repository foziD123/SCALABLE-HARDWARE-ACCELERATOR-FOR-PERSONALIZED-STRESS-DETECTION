/*------------------------------------------------------------------------------
 * File          : KNN_ACC_CORE.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : May 21, 2023
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module KNN_ACC_CORE  (
			input 		CLK,RESETn,
			input [31:0] control, //[0:1] = k_control, [2:12] = threshold
			input reg_start,// 1 bits to control knn/svm machines -->00=none 01=knn , 10=svm , 11=knn+svm
						
			output reg KNN_done,
			output reg KNN_classification
			);


	//============================================================================================================================//
	//--------------Internal Variables---------------- 
	reg [7:0] input_buffer_addr;
	
	reg cs_control;
	reg we_control;
	reg oe_control;
	
	wire [127:0] new_samples;

	wire PE1_classification;
	wire PE1_done;
	wire PE2_classification;
	wire PE2_done;
	wire PE3_classification;
	wire PE3_done;
	wire PE4_classification;
	wire PE4_done;

	wire [10:0] counter_res_1;
	wire [10:0] counter_res_2;
	wire [10:0] counter_res_3;
	wire [10:0] counter_res_4;
	
	reg reset_counter;
	
	reg [10:0] sum_1;
	reg [10:0] sum_2;
	reg [10:0] sum_3;
	
	//flags to indicate the start of the calculations of each stage
	wire start_idle_pos;
	wire start_fetch_pos;
	wire start_classify_pos;	//new sample is ready to be classified
	wire start_done_pos;	
	wire line_done;
	
	//counter to count how samples (lines) were classified thus far
	reg [8:0] count_line_samples;
	reg [8:0] counter;
	
	
	
	//============================================================================================================================//
	//--------------Instantiations---------------- 
	
	input_buffer Input_Buffer_1 (.clk(CLK),.address(input_buffer_addr), .data(new_samples),.cs(cs_control),.we(we_control),.oe(oe_control));  

	KNN_PE PE1 (.CLK(CLK), .RESETn(RESETn), .control(control[1:0]), .sample_data(new_samples[31:0]), 
	.classify_enable(start_classify_pos),.sample_classification(PE1_classification), .classify_sample_done(PE1_done));

	KNN_PE PE2 (.CLK(CLK), .RESETn(RESETn), .control(control[1:0]), .sample_data(new_samples[63:32]), 
	.classify_enable(start_classify_pos),.sample_classification(PE2_classification), .classify_sample_done(PE2_done));

	KNN_PE PE3 (.CLK(CLK), .RESETn(RESETn), .control(control[1:0]), .sample_data(new_samples[95:64]), 
	.classify_enable(start_classify_pos),.sample_classification(PE3_classification), .classify_sample_done(PE3_done));

	KNN_PE PE4 (.CLK(CLK), .RESETn(RESETn), .control(control[1:0]), .sample_data(new_samples[127:96]), 
	.classify_enable(start_classify_pos),.sample_classification(PE4_classification), .classify_sample_done(PE4_done));

	counter count1 (.clk(CLK), .RESETn(RESETn), .init(reset_counter), .trigger(PE1_done), .classification(PE1_classification), .count(counter_res_1));

	counter count2 (.clk(CLK), .RESETn(RESETn), .init(reset_counter), .trigger(PE2_done), .classification(PE2_classification), .count(counter_res_2));

	counter count3 (.clk(CLK), .RESETn(RESETn), .init(reset_counter), .trigger(PE3_done), .classification(PE3_classification), .count(counter_res_3));

	counter count4 (.clk(CLK), .RESETn(RESETn), .init(reset_counter), .trigger(PE4_done), .classification(PE4_classification), .count(counter_res_4));

	//============================================================================================================================//
	//--------------FSM---------------- 
	
	typedef enum logic [1:0] {Idle_st = 2'b00, Fetch_st = 2'b01, Classify_st = 2'b10, Done_st = 2'b11} STATE;
	STATE CUR_ST,CUR_ST_D,NEXT_ST;
		

	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) begin
			// Reset logic here add #1
			CUR_ST <= Idle_st;
			count_line_samples <= 0;
   
		end 
		else begin
			// FSM logic
			CUR_ST <= #1 NEXT_ST;
			count_line_samples <= #1 counter;
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
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
				// Check conditions to transition to the next state and set control signals
				if (reg_start == 1'b1) begin
					NEXT_ST = Fetch_st;
				end
				else NEXT_ST = Idle_st;
			end //end IDLE

			Fetch_st:
				begin 
					cs_control = 1'b1;
					we_control = 1'b0;
					oe_control = 1'b1;
										
					NEXT_ST = Classify_st;
				
				end // end FETCH
			
			Classify_st:
				begin
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;
					
					// Check conditions to transition to the next state and set control signals
					if (line_done == 1'b1 && count_line_samples == 9'b100000000 )begin
						NEXT_ST = Done_st;
					end
					else if(line_done == 1'b1) NEXT_ST = Fetch_st;
					else NEXT_ST = Classify_st; 
				
				end //end CLASSIFY
				

			Done_st:
					begin
						cs_control = 1'b0;
						we_control = 1'b0;
						oe_control = 1'b0;
						NEXT_ST = Done_st;
					
					end//end done
				
			default:
					begin
					NEXT_ST = Idle_st;
					cs_control = 1'b0;
					we_control = 1'b0;
					oe_control = 1'b0;

					end 

		endcase
	end
	
	
	assign start_idle_pos = (CUR_ST == Idle_st) && (reg_start == 1'b1);
	assign start_fetch_pos = (CUR_ST == Fetch_st) && (CUR_ST_D != CUR_ST);
	assign start_classify_pos = (CUR_ST == Classify_st) && (CUR_ST_D != CUR_ST);
	assign start_done_pos = (CUR_ST == Done_st) && (CUR_ST_D != CUR_ST);
	assign line_done = (PE1_done && PE2_done && PE3_done && PE4_done);
	assign KNN_classification = (control[12:2] >= 11'd1024) ? (sum_3 >= 11'd512) :(sum_3 >= control[12:2]) ;
	assign KNN_done = (sum_3 >= control[12:2]) ? 1'b1 :(CUR_ST == Done_st);
	
	//============================================================================================================================//
	//--------------Code---------------- 
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) counter <= #1 9'b0 ;
		else if (start_idle_pos) counter <= #1 9'b0; 
		else if(start_fetch_pos) counter <= #1 count_line_samples + 9'b1;
	end
	
	//=========================ADEED	12/12=============================
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) count_line_samples <= #1 9'b0 ;
		else if (start_idle_pos) count_line_samples <= #1 9'b1; 
	end
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) reset_counter <= #1 0 ;
		else if (start_done_pos) reset_counter <= #1 1; 
	end
	
	//================================================================
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) input_buffer_addr <= #1 8'b0 ;
		else if (start_idle_pos) input_buffer_addr <= #1 8'b1; 
		else if(start_fetch_pos) input_buffer_addr <= #1 input_buffer_addr + 1;
	end
	
	

	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sum_1 <= #1 11'b0;
		else sum_1 <= #1 counter_res_1 + counter_res_2;
	end
	
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sum_2 <= #1 11'b0;
		else sum_2 <= #1 counter_res_3 + counter_res_4;
	end
	
	
	always @(posedge CLK or negedge RESETn) begin
		if (!RESETn) sum_3 <= #1 11'b0; 
		else  
			sum_3 <= #1 sum_1 + sum_2;
	end
	
	
		
endmodule