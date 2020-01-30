`ifndef AXI_STREAM_MASTER
`define AXI_STREAM_MASTER

`include "globals.vh"

import axi_arbiter_pkg::*;

class IAxiStreamMaster;

virtual IAxiStream.Master  master_intf;
virtual AxiAddition  			addition_intf;
//int i;

/* constructor method */
function new( virtual IAxiStream.Master master_intf_new, 
							virtual AxiAddition addition_intf_new );

  this.master_intf    = master_intf_new  ;
  this.addition_intf    = addition_intf_new  ;
	
endfunction : new  

task reset();

  $display("%0t : INFO    : IAxiStreamMaster    : reset() method ",$time ); 
	@( posedge addition_intf.aclk );
	master_intf.t_data  <= 0;
	master_intf.t_valid <= 0;
	master_intf.t_last  <= 0;	
	master_intf.t_id    <= 0;
 	@( posedge addition_intf.aclk ); 

endtask : reset

task sendPacket( ref axi_data_t data[], input bit is_random_valid = 0, input bit is_random_packet_interval = 0 );
	
	automatic bit random_valid_value;
	automatic int random_packet_interval;
	
		/* устанавливаем интервал между пакетами */
	if( is_random_packet_interval )
	begin
		random_packet_interval =  {$random} % (`NUM_CHANNELS * 8);
		$display("%0t : INFO    : IAxiStreamMaster    : random_packet_interval = %0d ", $time, random_packet_interval );		
		for( int i = 0; i < random_packet_interval; i++ )
		begin 
			@( posedge addition_intf.aclk );
		end
	end
	
  $display("%0t : INFO    : IAxiStreamMaster    : sendPacket() start ", $time );
	foreach( data[i] )
	begin
		//@( negedge addition_intf.aclk );	
		if( !is_random_valid )
		begin
			master_intf.t_valid 	<= 1;//$random;
		end		
		else
		begin
			forever
			begin
				random_valid_value = $random;
				master_intf.t_valid 	<= random_valid_value;
				if( random_valid_value )	
				begin
					break;
				end
				$display("%0t : WAIT ", $time );
				@( posedge addition_intf.aclk );
/* 				master_intf.t_valid 	<= $random;
				//#0;
				if( master_intf.t_valid == 1 )	
				begin
					break;
				end
				$display("%0t : WAIT ", $time );
				@( posedge addition_intf.aclk );		 */		
			end
		end			

		master_intf.t_data 	  <= data[i].data;	
		master_intf.t_id    	<= data[i].id;
		if( i+1 >= data.size )
			master_intf.t_last  <= 1;
		else
			master_intf.t_last  <= 0;
		/* ждем захвата сигнала dut */
		@( negedge addition_intf.aclk );	
		forever
		begin
			/* во избежание состояния гонки между dut и testbench захватываем сигнал по отрицательному фронту */
			@( posedge addition_intf.aclk );
 			if( master_intf.t_ready )
			begin
				master_intf.t_data  <= 0;
				master_intf.t_valid <= 0;
				master_intf.t_last  <= 0;	
				master_intf.t_id    <= 0;
				break;
			end
		end
	end	
/* 	@( posedge addition_intf.aclk );	
	master_intf.t_data  <= 0;
	master_intf.t_valid <= 0;
	master_intf.t_last  <= 0;	
	master_intf.t_id    <= 0; */
	$display("%0t : INFO    : IAxiStreamMaster    : sendPacket() end ", $time );
	
endtask : sendPacket

/* task sendPacket( ref bit [`DATA_SIZE-1:0] data[] );

  $display("%0t : INFO    : IAxiStreamMaster    : sendPacket() start ", $time );
	foreach( data[i] )
	begin
		@( posedge addition_intf.aclk );	
		master_intf.t_data 	  <= data[i];
		master_intf.t_valid 	<= 1;//$random;
		master_intf.t_last  	<= 0;
		master_intf.t_id    	<= 0;
		if( i+1 == data.size )
		begin
			master_intf.t_last  <= 1;
		end
		forever
		begin
			if( master_intf.t_ready )
				break;
			else
			begin
				$display("%0t : WAIT ", $time );
				@( posedge addition_intf.aclk );
			end	
		end
	end	
	@( negedge addition_intf.aclk );	
	master_intf.t_data  <= 0;
	master_intf.t_valid <= 0;
	master_intf.t_last  <= 0;	
	master_intf.t_id    <= 0;
	$display("%0t : INFO    : IAxiStreamMaster    : sendPacket() end ", $time );
	
endtask : sendPacket */

endclass

`endif