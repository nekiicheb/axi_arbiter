`ifndef AXI_STREAM_SLAVE
`define AXI_STREAM_SLAVE

import axi_arbiter_pkg::*;

class IAxiStreamSlave;

virtual IAxiStream.Slave  slave_intf;
virtual Arbiter  			arbiter_intf;
//int i;

/* constructor method */
function new( virtual IAxiStream.Slave slave_intf_new, virtual Arbiter arbiter_intf_new );

  this.slave_intf       = slave_intf_new;
  this.arbiter_intf    = arbiter_intf_new;
	
endfunction : new  

task reset();

  $display("%0t : INFO    : IAxiStreamSlave    : reset() ",$time ); 
	@( posedge arbiter_intf.aclk );
	slave_intf.t_ready  <= 0;
 	@( posedge arbiter_intf.aclk ); 

endtask : reset

/*!
принимает пакеты из DUT
\param[ref] src приемный буфер из DUT
\param[in] is_random_rdy Разрешить генерирование рандомного значения t_ready на шине axi_stream_slave
*/	
task getPacket( ref axi_data_t src[$], input bit is_random_rdy = 0 );
	
	automatic bit random_bit;

  $display("%0t : INFO    : IAxiStreamSlave    : getPacket() ", $time );	
	forever
	begin
		if( is_random_rdy )
		begin
			@( posedge arbiter_intf.aclk );
			random_bit = $random;
			slave_intf.t_ready 	<= random_bit;	
		end
		else
		begin
			slave_intf.t_ready 	<= 1;			
		end
		/* во избежание состояния гонки между dut и testbench захватываем сигнал по отрицательному фронту */
		@( negedge arbiter_intf.aclk );	
		if( slave_intf.t_ready && slave_intf.t_valid )
		begin
			axi_data_t axi_data;
			axi_data.data = slave_intf.t_data;
			axi_data.id   = slave_intf.t_id;
			axi_data.idx_channel = arbiter_intf.idx_channel;
			src.push_back( axi_data );
			if( slave_intf.t_last )
			begin
				break;
			end
		end	
	end

endtask : getPacket

endclass

`endif