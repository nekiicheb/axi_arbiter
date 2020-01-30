`ifndef AXI_STREAM_SLAVE
`define AXI_STREAM_SLAVE

`include "globals.vh"

import axi_arbiter_pkg::*;

class IAxiStreamSlave;

virtual IAxiStream.Slave  slave_intf;
virtual AxiAddition  			addition_intf;
//int i;

/* constructor method */
function new( virtual IAxiStream.Slave slave_intf_new, virtual AxiAddition addition_intf_new );

  this.slave_intf       = slave_intf_new;
  this.addition_intf    = addition_intf_new;
	
endfunction : new  

task reset();

  $display("%0t : INFO    : IAxiStreamSlave    : reset() ",$time ); 
	@( posedge addition_intf.aclk );
	slave_intf.t_ready  <= 0;
 	@( posedge addition_intf.aclk ); 

endtask : reset

task getPacket( ref axi_data_t data[$], input Channel channel, input bit is_random_rdy = 0 );
	
	automatic bit random_bit;

  $display("%0t : INFO    : IAxiStreamSlave    : getPacket() ", $time );
	//@( negedge addition_intf.aclk );		
	forever
	begin
		if( is_random_rdy )
		begin
			@( posedge addition_intf.aclk );
			random_bit = $random;
			slave_intf.t_ready 	<= random_bit;	
		end
		else
		begin
			slave_intf.t_ready 	<= 1;			
		end
		@( negedge addition_intf.aclk );	
		if( slave_intf.t_ready && slave_intf.t_valid )
		begin
			//$display("%0t : INFO    : BufRun ", $time );
			axi_data_t axi_data;
			axi_data.data = slave_intf.t_data;
			axi_data.id   = slave_intf.t_id;
			axi_data.idx_channel = addition_intf.idx_channel;
			data.push_back( axi_data );
			//$display("%0t : RCVR0 = %0x ", $time, slave_intf.t_data );
			if( slave_intf.t_last )
			begin
				$display("%0t : RCVR1 = %0x ", $time, slave_intf.t_data );
				break;
			end
		end	
	end

endtask : getPacket

endclass

`endif