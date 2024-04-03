/*------------------------------------------------------------------------------
 * File          : SVM_KNN_ACC_REGFILE.vs
 * Project       : RTL
 * Author        : epfdhs
 * Creation date : May 8, 2023
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/100ps

// Registers address.
`define REG1_Address    32'h0970
`define REG2_Address    32'h0974
`define REG_Start_Addr  32'h0978

module SVM_KNN_ACC_REGFILE ( 
	
// ----------------------------------------------------------------------
//                   REGFILE Interface
// ----------------------------------------------------------------------
			input 		PCLK,PRESETn,
			input 		PENABLE,
			input 		PWRITE_regFile,
		 	input 		[31:0]PADDR,PWDATA,
			
			output reg [31:0]PRDATA,			
			output reg PREADY,
			output reg logic_op,
			output reg [1:0] reg_start
);

// ----------------------------------------------------------------------
//                   REGISTERS
// ----------------------------------------------------------------------
			reg [31:0]   reg1;
		
			reg			 reg2;			
			
// ----------------------------------------------------------------------
//                   Writing & Reading
// ----------------------------------------------------------------------
			
			always@(posedge PCLK or negedge PRESETn)
				begin
					if(!PRESETn) 
						reg1 <= #1 32'b0;
					else if(PWRITE_regFile && (PADDR == `REG1_Address) && PENABLE)
						reg1 <= #1 PWDATA;
					
				end
			
			always@(posedge PCLK or negedge PRESETn)
				begin
					if(!PRESETn) 
						reg2 <= #1 1'b0;
					else if(PWRITE_regFile && (PADDR == `REG2_Address) && PENABLE)
						reg2 <= #1 PWDATA[0];
				end
			
			
			always@(posedge PCLK or negedge PRESETn)
			begin
				if(!PRESETn) 
					reg_start <= #1 2'b0;
				else if(PWRITE_regFile && (PADDR == `REG_Start_Addr) && PENABLE)
					reg_start <= #1 PWDATA[1:0];
			end
			
			
			always@(posedge PCLK or negedge PRESETn)
				begin 
					if(!PRESETn)
						PRDATA <= #1 32'b0;
					else if (!PWRITE_regFile && (PADDR == `REG1_Address) && PENABLE)
						PRDATA <= #1 reg1;
				end
			
			always@(posedge PCLK or negedge PRESETn)
			begin 
				if(!PRESETn)
					logic_op <= #1 1'b0;
				else if (!PWRITE_regFile && (PADDR == `REG2_Address) && PENABLE)
					logic_op <= #1 reg2;
			end
			

			always@(posedge PCLK or negedge PRESETn)
				begin 
					if(!PRESETn)
						PREADY <= #1 1'b0;
					else if (!PWRITE_regFile && ((PADDR == 32'h0970) || (PADDR == 32'h0974) || (PADDR == 32'h0978)) && PENABLE)
						PREADY <= #1 1'b1;
					else
						PREADY <= #1 1'b0;
				
				end


			
			
  endmodule

