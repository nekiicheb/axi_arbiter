`ifndef AXI_ARBITER_ENV
`define AXI_ARBITER_ENV

`include "driver.sv"
`include "receiver.sv"
`include "scoreboard.sv"

class Environment ;


virtual IAxiStream.Master  master_intf[4];
virtual IAxiStream.Slave  slave_intf;
virtual AxiAddition addition_intf;
  
Driver   driver[4];
Receiver receiver;
Scoreboard scoreboard;
mailbox  driver2scoreboard;
mailbox  receiver2scoreboard;
event startSb;
  // Receiver receiver[4];
  // Scoreboard scoreboard;
  // mailbox driver2scoreboard;
  // mailbox receiver2scoreboard;

function new( virtual IAxiStream.Master master_intf_new[4],
							virtual IAxiStream.Slave  slave_intf_new,
							virtual AxiAddition addition_intf_new );

  $display("%0t : Environment : start of create object",$time);
  this.master_intf  = master_intf_new;
  this.slave_intf   = slave_intf_new;
	this.addition_intf   = addition_intf_new;
	driver2scoreboard = new(1); 
	receiver2scoreboard = new(1); 
	receiver = new( slave_intf_new, addition_intf, receiver2scoreboard, startSb );
	scoreboard = new( receiver2scoreboard, driver2scoreboard, startSb );
	foreach( driver[i] )
	begin
		driver[i] = new( master_intf_new[i], addition_intf, driver2scoreboard, startSb );
	end
	
  $display("%0t : Environment : created object", $time);

endfunction : new

task reset( ref bit nrst );

  $display("%0t : Environment : start of reset()",$time);
  /* установить все входа DUT в известное состояние */
	driver[0].reset();
	driver[1].reset();
	driver[2].reset();
	driver[3].reset();
	receiver.reset();	
  /* reset the DUT */
  nrst  = 0;
  repeat (4) @(addition_intf.aclk);
  nrst  = 1;
  repeat (4) @(addition_intf.aclk);  
  $display("%0t : Environment : end of reset()",$time);
	
endtask : reset
 
task wait_for_end();
   $display("%0t : Environment : start of wait_for_end() ",$time);
   repeat(500) @(addition_intf.aclk);
   $display("%0t : Environment : end of wait_for_end() ",$time);
endtask : wait_for_end
 
/* проверяем работу только 0-го канала, сигнал ready от slave всегда в 1 */	
// task test_case_1();
  // $display("**************************************");
  // $display(" %0t : TestCase 1 : start()", $time);
  // $display("**************************************");	
	// /* сбросим все входа DUT */
	// driver[0].reset();
	// driver[1].reset();
	// driver[2].reset();
	// driver[3].reset();
	// receiver.reset();
	// fork
		// driver[0].sendPackets(4, );
		// receiver.start( );
		// scoreboard.start();
	// join_any
	// wait_for_end();
// endtask : test_case_1

// /* проверяем работу только 0-го канала, сигнал ready от slave и сигнал от master рандомные */	
// task test_case_2();
  // $display("**************************************");
  // $display(" %0t : TestCase 2 : start()", $time);
  // $display("**************************************");	
	// /* сбросим все входа DUT */
	// driver[0].reset();
	// driver[1].reset();
	// driver[2].reset();
	// driver[3].reset();
	// receiver.reset();
	// fork
		// driver[0].sendPackets(4, 1);
		// receiver.start( 1 );
		// scoreboard.start();
	// join_any
	// wait_for_end();
// /* 	disable receiver.start();
	// disable driver[0].sendPackets(4);	
	// disable scoreboard.start();	 */
// endtask : test_case_2
	
task run( input int number_of_packets, bit is_random_valid = 0, bit is_random_interval = 0, bit is_random_rdy = 0, bit is_check_sequence = 1 );

	automatic int cnt_of_packets_from_driver[`NUM_CHANNELS];
	automatic int cnt_of_packets_from_drivers;	
	automatic int cnt_of_packets_from_receiver;
	automatic int cnt_of_packets_from_scoreboard;	


  $display("%0t : Environment : run() ",$time);	
	// добавить enum индексов!!!!!!!!!!
	
	fork
		driver[0].sendPackets( 0, number_of_packets, is_random_valid, is_random_interval );
		driver[1].sendPackets( 1, number_of_packets, is_random_valid, is_random_interval );
		driver[2].sendPackets( 2, number_of_packets, is_random_valid, is_random_interval );
		driver[3].sendPackets( 3, number_of_packets, is_random_valid, is_random_interval );		
		receiver.start( cnt_of_packets_from_receiver, is_random_rdy );
		scoreboard.start( cnt_of_packets_from_scoreboard, is_check_sequence );
	join_any
	wait_for_end();
	/* сравниваем количество отправленных пакетов с количеством принятых пакетов */
	for( int i = 0; i < `NUM_CHANNELS; i++ )
	begin
		$display("%0t : INFO    : Environment : cnt_of_packets_from_driver[%0d] = %0d ",$time, cnt_of_packets_from_driver[i], i );
	end	
	
	$display("%0t : INFO    : Environment : cnt_of_packets_from_receiver = %0d ",$time, cnt_of_packets_from_receiver );
	$display("%0t : INFO    : Environment : cnt_of_packets_from_scoreboard = %0d ",$time, cnt_of_packets_from_scoreboard );
	cnt_of_packets_from_drivers = `NUM_CHANNELS * number_of_packets;
	if( ( cnt_of_packets_from_drivers == cnt_of_packets_from_receiver ) && 
			( cnt_of_packets_from_receiver == cnt_of_packets_from_scoreboard ) )
	begin
		$display("%0t : INFO    : Environment : expected_cnt_of_packets is equal current_cnt_of _packets ",$time);	
	end
	else
	begin
		$display("%0t : ERROR    : Environment : expected_cnt_of_packets is not equal current_cnt_of _packets ",$time);	
		$stop;
	end

  $display("%0t : Environment : end of run() ",$time);
endtask : run

task report();
   $display("\n*************************************************");
	 $display("********            TEST PASSED         *********");
	 $display("*************************************************\n");
endtask : report

endclass

`endif
