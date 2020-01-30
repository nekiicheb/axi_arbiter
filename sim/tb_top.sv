`ifndef AXI_ARBITER_TOP
`define AXI_ARBITER_TOP

`include "environment.sv"

import axi_arbiter_pkg::*;

module tb_top();

/////////////////////////////////////////////////////
// Clock Declaration and Generation                //
/////////////////////////////////////////////////////

bit clk_i;
bit nrst_i;

initial
  forever #5 clk_i = ~clk_i;

IAxiStream 	 in_intf[4] ( clk_i, nrst_i );
IAxiStream   out_intf  ( clk_i, nrst_i );
AxiAddition  addition_intf( clk_i );

/////////////////////////////////////////////////////
//  DUT instance and signal connection             //
/////////////////////////////////////////////////////


/* IAxiStream in_0 (clk_i, nrst_i);
IAxiStream in_1 (clk_i, nrst_i);
IAxiStream in_2 (clk_i, nrst_i);
IAxiStream in_3 (clk_i, nrst_i);
IAxiStream out  (clk_i, nrst_i);

generate
	assign in_0.t_valid   			= in_intf[0].t_valid;
	assign in_0.t_last    			= in_intf[0].t_last;
	assign in_0.t_data    			= in_intf[0].t_data;
	assign in_0.t_id	    			= in_intf[0].t_id ;
  assign in_intf[0].t_ready   = in_0.t_ready;


	assign in_1.t_valid   			= in_intf[1].t_valid;
	assign in_1.t_last    			= in_intf[1].t_last;
	assign in_1.t_data    			= in_intf[1].t_data;
  assign in_1.t_id	    			= in_intf[1].t_id ;
	assign in_intf[1].t_ready   = in_1.t_ready;

	assign in_2.t_valid  			  = in_intf[2].t_valid;
	assign in_2.t_last    			= in_intf[2].t_last;
	assign in_2.t_data    			= in_intf[2].t_data;
	assign in_2.t_id	    			= in_intf[2].t_id ;
	assign in_intf[2].t_ready   = in_2.t_ready;

	assign in_3.t_valid   			= in_intf[3].t_valid;
	assign in_3.t_last    			= in_intf[3].t_last;
	assign in_3.t_data    			= in_intf[3].t_data;
	assign in_3.t_id	    			= in_intf[3].t_id ;
	assign in_intf[3].t_ready   = in_3.t_ready;
	
	assign out_intf.t_valid 		= out.t_valid;
	assign out_intf.t_last  		= out.t_last;
	assign out_intf.t_data  		= out.t_data;
	assign out_intf.t_id	  		= out.t_id ;
	assign out.t_ready  				= out_intf.t_ready; 
	
endgenerate
 */
arbiter DUT
(
	.clk											  ( clk_i ),	
	.reset_n									  ( nrst_i ),

	.in_0								 	 			( in_intf[0] ),
	.in_1								 	 			( in_intf[1] ),
	.in_2								 	 			( in_intf[2] ),	
	.in_3								 	 			( in_intf[3] ),	
	
	.out											 	( out_intf ),
	.idx_channel								( addition_intf.idx_channel )
	
);

/*
* Test Case 1: 
* action: тест одновременно выдаёт на DUT несколько пакетов разной длины одновременно на всех каналах
* expected result: 
*										1) нет потерь пакетов 
*										2) нет потерь данных IAxiStream.Master.t_data, IAxiStream.Master.t_id в пакетах различной длины 
*										3) мультиплексирование каналов addition_intf.idx_channel по алгориму round-robin, начиная с 0-го канала 
*/
task test_case_1();

	automatic Environment env;
	automatic int number_of_packets = 20;

  $display("**************************************");
  $display(" %0t : TestCase 1 : start()", $time);
  $display("**************************************");
	env = new( in_intf, out_intf, addition_intf );
	env.reset( nrst_i );
	env.run( number_of_packets );
	env.wait_for_end();
	env.report();
  $display("**************************************");
  $display(" %0t : TestCase 1 : end()", $time);
  $display("**************************************");

endtask : test_case_1

/*
* Test Case 2: 
* action: тест одновременно выдаёт на DUT несколько пакетов одновременно на всех каналах с рандомным сигналом IAxiStream.Slave.t_ready 
* 				( за счет рандомности IAxiStream.Slave.t_ready получаем проверку модуля в граничных условиях ) 
* expected result: 
*										1) нет потерь пакетов при граничных значениях IAxiStream.Slave.t_ready
*										2) нет потерь данных IAxiStream.Master.t_data, IAxiStream.Master.t_id в пакетах различной длины и 
*											 значениях IAxiStream.Slave.t_ready
*										3) мультиплексирование входных каналов по алгориму round-robin, начиная с 0-го канала
*/	
task test_case_2();

	automatic Environment env;
	automatic int number_of_packets = 1000;
	automatic bit is_random_rdy = 1;

  $display("**************************************");
  $display(" %0t : TestCase 2 : start()", $time);
  $display("**************************************");
	env = new( in_intf, out_intf, addition_intf );
	env.reset( nrst_i );
	env.run( number_of_packets, 0, 0, is_random_rdy );
	env.wait_for_end();
	env.report();	
  $display("**************************************");
  $display(" %0t : TestCase 2 : end()", $time);
  $display("**************************************");	

endtask : test_case_2

/*
* Test Case 3: 
* action: тест одновременно выдаёт на DUT несколько пакетов одновременно на всех каналах с рандомным сигналом IAxiStream.Slave.t_ready и
*         рандомными сигналами IAxiStream.Slave.t_valid
*					( за счет рандомности IAxiStream.Slave.t_ready, IAxiStream.Slave.t_valid получаем проверку модуля в граничных условиях ) 
* expected result: 
*										1) нет потерь пакетов при граничных значениях IAxiStream.Slave.t_ready и IAxiStream.Slave.t_valid
*										2) нет потерь данных IAxiStream.Master.t_data, IAxiStream.Master.t_id в пакетах различной длины и 
*											 значениях IAxiStream.Slave.t_ready и IAxiStream.Slave.t_valid
*/	
task test_case_3();

	automatic Environment env;
	automatic int number_of_packets = 1000;
	automatic bit is_random_valid = 1;
	automatic bit is_random_rdy = 1;
	
  $display("**************************************");
  $display(" %0t : TestCase 3 : start()", $time);
  $display("**************************************");
	env = new( in_intf, out_intf, addition_intf );
	env.reset( nrst_i );
	env.run( number_of_packets, is_random_valid, 0, is_random_rdy, 0 );
	env.wait_for_end();
	env.report();	
  $display("**************************************");
  $display(" %0t : TestCase 3 : end()", $time);
  $display("**************************************");	

endtask : test_case_3

/*
* Test Case 4: 
* action: тест одновременно выдаёт на DUT несколько пакетов одновременно на всех каналах с рандомным сигналом IAxiStream.Slave.t_ready и
*         рандомными сигналами IAxiStream.Slave.t_valid и рандомными паузами между пакетами
*					( за счет рандомности IAxiStream.Slave.t_ready, IAxiStream.Slave.t_valid, интервала между пакетами
* 					 получаем проверку модуля в граничных условиях и непоследовательных пакетах между каналами ) 
* expected result: 									
*										1) нет потерь пакетов при граничных значениях IAxiStream.Slave.t_ready и IAxiStream.Slave.t_valid
*										2) нет потерь данных IAxiStream.Master.t_data, IAxiStream.Master.t_id в пакетах различной длины, паузы и 
*											 значениях IAxiStream.Slave.t_ready и IAxiStream.Slave.t_valid
*/	
task test_case_4();

	automatic Environment env;
	automatic int number_of_packets = 1000;
	automatic bit is_random_valid = 1;
	automatic bit is_random_rdy = 1;
	automatic bit is_random_packet_interval = 1;
	automatic bit is_check_sequence = 0;
	
  $display("**************************************");
  $display(" %0t : TestCase 4 : start()", $time);
  $display("**************************************");
	env = new( in_intf, out_intf, addition_intf );
	env.reset( nrst_i );
	env.run( number_of_packets, is_random_valid, is_random_packet_interval, is_random_rdy, is_check_sequence );
	env.wait_for_end();
	env.report();	
  $display("**************************************");
  $display(" %0t : TestCase 4 : end()", $time);
  $display("**************************************");	
	
endtask : test_case_4

initial
begin
	test_case_1();
	test_case_2();
	test_case_3();
	test_case_4();
	$stop;
end

endmodule

`endif
