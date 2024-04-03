Scalable-Hardware-Accelerator-for-Personalized-Stress-Detection

The accelerator integrates various components, including Support Vector Machine (SVM) and K Nearest Neighbors (KNN) cores for classification, clock synchronization mechanisms, and efficient register file (regfile) management.

After thorough planning, the accelerator was implemented in SystemVerilog and zero-order verification was done to ensure the correct functionality of the accelerator using simulations and testing.

Steps to run :
	1	Put all the files inside the desing directory of your projcet (both .sv and .mem files)
	2	Open terminal in the parent directory of the 'design' directory and run : $ start_veride in order to run the IDE (optional)
	3	Open another terminal in the 'design' directory
	4	To analyze all the .sv files run : $ vlogan -kdb -sverilog -full64 *.sv
	5	To elaborate the top module run : $ vcs -kdb -debug_access+all SVM_KNN_ACC_TB
	6	to run a simulation, run : $ simv -gui
 
Notes:
	•	the files .mem are randomly generated tests for the specific size of the behavioral memories used in the project and they are loaded using commands in the testbench.
	•	the files 'temp_training_data_binary_test0.mem' and 'temp_training_data_binary_test1.mem', are tests that check the edge cases of "every traning sample has a '0' classification" and "every traning sample has a '1' classification" respectively.
	•	in the testbench file, the control parameters can be altered such as: threshold for each core, bias value, K value (KNN), and the chosen logic operation (AND/OR).
