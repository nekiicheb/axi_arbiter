`ifndef AXI_STREAM_MASTER
`define AXI_STREAM_MASTER

import axi_arbiter_pkg::*;

class IAxiStreamMaster;

virtual IAxiStream.Master  master_intf;
virtual Arbiter  			arbiter_intf;

/* constructor method */
function new( virtual IAxiStream.Master master_intf_new, 
							virtual Arbiter arbiter_intf_new );

  this.master_intf    = master_intf_new  ;
  this.arbiter_intf    = arbiter_intf_new  ;
	
endfunction : new  

task reset();

  $display("%0t : INFO    : IAxiStreamMaster    : reset() method ",$time ); 
	@( posedge arbiter_intf.aclk );
	master_intf.t_data  <= 0;
	master_intf.t_valid <= 0;
	master_intf.t_last  <= 0;	
	master_intf.t_id    <= 0;
 	@( posedge arbiter_intf.aclk ); 

endtask : reset

/*!
отправляет пакет в DUT
\param[ref] src пакет для отправки в DUT 
\param[in] is_random_valid Разрешить генерирование рандомного значения t_valid на шине axi_stream_master
\param[in] is_random_packet_interval Разрешить генерирование рандомных пауз между пакетам на шине axi_stream_master
*/
task sendPacket( ref axi_data_t src[], input bit is_random_valid = 0, input bit is_random_packet_interval = 0 );
	
	automatic bit random_valid_value;
	automatic int random_packet_interval;
	
		/* устанавливаем интервал между пакетами */
	if( is_random_packet_interval )
	begin
		random_packet_interval =  {$random} % (NUM_CHANNELS * 8);	
		for( int i = 0; i < random_packet_interval; i++ )
		begin 
			@( posedge arbiter_intf.aclk );
		end
	end
  $display("%0t : INFO    : IAxiStreamMaster    : sendPacket() start ", $time );
	foreach( src[i] )
	begin
		if( !is_random_valid )
		begin
			master_intf.t_valid 	<= 1;
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
				@( posedge arbiter_intf.aclk );
			end
		end			
		master_intf.t_data 	  <= src[i].data;	
		master_intf.t_id    	<= src[i].id;
		if( i+1 >= src.size )
			master_intf.t_last  <= 1;
		else
			master_intf.t_last  <= 0;
		/* ждем захвата сигнала dut */
		@( negedge arbiter_intf.aclk );	
		forever
		begin
			@( posedge arbiter_intf.aclk );
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
	$display("%0t : INFO    : IAxiStreamMaster    : sendPacket() end ", $time );
	
endtask : sendPacket

endclass

`endif