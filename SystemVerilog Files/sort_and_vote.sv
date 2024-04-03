/*------------------------------------------------------------------------------
 * File          : sort_and_vote.sv
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : Sep 26, 2023
 * Description   : knn pe 1
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

module sort_and_vote  (
			input clk,RESETn,
			//sorting input:
			input [10:0] curr_MAE,
			input training_sample_c,
			input new_start, 				//pulse for a new sample
			//voting input :
			input [1:0] K_control,
			input sortEnable,
			input voteEnable,
			output reg sample_classification
			);
			
//--------------Internal variables---------------- 
	 reg [10:0] Rd1 ;
	 reg [10:0] Rd2 ;
	 reg [10:0] Rd3 ;
	 reg [10:0] Rd4 ;
	 reg [10:0] Rd5 ;
	 
	 reg [2:0] Rc1 ;
	 reg [2:0] Rc2 ;
	 reg [2:0] Rc3 ;
	 reg [2:0] Rc4 ;
	 reg [2:0] Rc5 ;
	 
	 wire tmp_cmp_1 ;
	 wire tmp_cmp_2 ;
	 wire tmp_cmp_3 ;
	 wire tmp_cmp_4 ;
	 wire tmp_cmp_5 ;
	 
	 wire  Rd1_en;
	 wire  Rd2_en;
	 wire  Rd3_en;
	 wire  Rd4_en;
	 wire  Rd5_en;
	 
	 assign Rd1_en = sortEnable & tmp_cmp_1;
	 assign Rd2_en = sortEnable & tmp_cmp_2 & !Rd1_en;
	 assign Rd3_en = sortEnable & tmp_cmp_3 & !Rd2_en & !Rd1_en;
	 assign Rd4_en = sortEnable & tmp_cmp_4 & !Rd3_en & !Rd2_en & !Rd1_en;
	 assign Rd5_en = sortEnable & tmp_cmp_5 & !Rd4_en & !Rd3_en & !Rd2_en & !Rd1_en;
	 
	 
	 always @(posedge clk or negedge RESETn) begin
		  if(!RESETn) Rd1 <= #1 11'b11111111111;
		  else if (new_start) Rd1 <= #1 11'b11111111111;
		  else if (K_control == 2'b00 || K_control == 2'b01) Rd1 <=#1 11'b0;
		  else if (Rd1_en) Rd1 <= #1 curr_MAE;
	 end
	 
	 always @(posedge clk or negedge RESETn) begin
		 if(!RESETn) Rd2 <= #1 11'b11111111111;
		 else if (new_start) Rd2 <= #1 11'b11111111111;
		 else if (K_control == 2'b00 || K_control == 2'b01) Rd2 <=#1 11'b0;
		 else if (Rd2_en) Rd2 <= #1 curr_MAE;
		 else if (Rd1_en) Rd2 <= #1 Rd1;
	 end
	 
	 always @(posedge clk or negedge RESETn) begin
		 if(!RESETn) Rd3 <= #1 11'b11111111111;
		 else if (new_start) Rd3 <= #1 11'b11111111111;
		 else if (K_control == 2'b00) Rd3 <=#1 11'b0;
		 else if (Rd3_en) Rd3 <= #1 curr_MAE;
		 else if (Rd2_en) Rd3 <= #1 Rd2;
		 else if (Rd1_en) Rd3 <= #1 Rd2;
	 end
	 
	 always @(posedge clk or negedge RESETn) begin
		 if(!RESETn) Rd4 <= #1 11'b11111111111;
		 else if (new_start) Rd4 <= #1 11'b11111111111;
		 else if (K_control == 2'b00) Rd4 <=#1 11'b0;
		 else if (Rd4_en) Rd4 <= #1 curr_MAE;
		 else if (Rd3_en) Rd4 <= #1 Rd3;
		 else if (Rd2_en) Rd4 <= #1 Rd3;
		 else if (Rd1_en) Rd4 <= #1 Rd3;
	 end
	 
	 always @(posedge clk or negedge RESETn) begin
		 if(!RESETn) Rd5 <= #1 11'b11111111111;
		 else if (new_start) Rd5 <= #1 11'b11111111111;
		 else if (Rd5_en) Rd5 <= #1 curr_MAE;
		 else if (Rd4_en) Rd5 <= #1 Rd4;
		 else if (Rd3_en) Rd5 <= #1 Rd4;
		 else if (Rd2_en) Rd5 <= #1 Rd4;
		 else if (Rd1_en) Rd5 <= #1 Rd4;
	 end
	 
	 always @(posedge clk or negedge RESETn) begin
		 if(!RESETn) Rc1 <= #1 3'b0;
		 else if (new_start) Rc1 <= #1 3'b0;
		 else if (K_control == 2'b00 || K_control == 2'b01) Rc1 <=#1 3'b0;
		 else if (Rd1_en) Rc1 <= #1 training_sample_c;
	end
	
	always @(posedge clk or negedge RESETn) begin
		if(!RESETn) Rc2 <= #1 3'b0;
		else if (new_start) Rc2 <= #1 3'b0;
		else if (K_control == 2'b00 || K_control == 2'b01) Rc2 <=#1 3'b0;
		else if (Rd2_en) Rc2 <= #1 training_sample_c;
		else if (Rd1_en) Rc2 <= #1 Rc1;
	end
	
	always @(posedge clk or negedge RESETn) begin
		if(!RESETn) Rc3 <= #1 3'b0;
		else if (new_start) Rc3 <= #1 3'b0;
		else if (K_control == 2'b00) Rc3 <=#1 3'b0;
		else if (Rd3_en) Rc3 <= #1 training_sample_c;
		else if (Rd2_en) Rc3 <= #1 Rc2;
		else if (Rd1_en) Rc3 <= #1 Rc2;
	end
	
	always @(posedge clk or negedge RESETn) begin
		if(!RESETn) Rc4 <= #1 3'b0;
		else if (new_start) Rc4 <= #1 3'b0;
		else if (K_control == 2'b00) Rc4 <=#1 3'b0;
		else if (Rd4_en) Rc4 <= #1 training_sample_c;
		else if (Rd3_en) Rc4 <= #1 Rc3;
		else if (Rd2_en) Rc4 <= #1 Rc3;
		else if (Rd1_en) Rc4 <= #1 Rc3;
	end
	
	always @(posedge clk or negedge RESETn) begin
		if(!RESETn) Rc5 <= #1 3'b0;
		else if (new_start) Rc5 <= #1 3'b0;
		else if (Rd5_en) Rc5 <= #1 training_sample_c;
		else if (Rd4_en) Rc5 <= #1 Rc4;
		else if (Rd3_en) Rc5 <= #1 Rc4;
		else if (Rd2_en) Rc5 <= #1 Rc4;
		else if (Rd1_en) Rc5 <= #1 Rc4;
	end
	 
	 
	 //----------------comparators for the priority encoder--------------------
	 assign tmp_cmp_1 = (curr_MAE < Rd1) ? 1'b1 : 1'b0;
	 assign tmp_cmp_2 = (curr_MAE < Rd2) ? 1'b1 : 1'b0;
	 assign tmp_cmp_3 = (curr_MAE < Rd3) ? 1'b1 : 1'b0;
	 assign tmp_cmp_4 = (curr_MAE < Rd4) ? 1'b1 : 1'b0;
	 assign tmp_cmp_5 = (curr_MAE < Rd5) ? 1'b1 : 1'b0;
	 
	 
	always @(posedge clk or negedge RESETn ) begin
		if (!RESETn) sample_classification <= #1 1'b0;
		else if (voteEnable) begin
			if ((Rc1+Rc2+Rc3+Rc4+Rc5) > K_control) sample_classification <= #1 1'b1;
			else sample_classification <= #1 1'b0;
		end
	end
	 
	
endmodule