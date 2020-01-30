`ifndef AXI_ARBITER_RECEIVER
`define AXI_ARBITER_RECEIVER

`include "globals.vh"
`include "axi_stream_slave.sv"

import axi_arbiter_pkg::*;

class Receiver;

virtual IAxiStream.Slave slave_intf;
virtual AxiAddition addition_intf;
IAxiStreamSlave slave;
mailbox rcvr2sb;
event startSb;

//// constructor method ////
function new(virtual IAxiStream.Slave slave_intf_new, virtual AxiAddition addition_intf_new,
						 mailbox rcvr2sb_new, event startSb_new );

   this.slave_intf    = slave_intf_new;
	 this.addition_intf  = addition_intf_new;
	 slave = new( this.slave_intf, this.addition_intf );	
	 this.startSb = startSb_new;	
   if(rcvr2sb_new == null)
   begin
     $display(" **ERROR**: rcvr2sb_new is null");
     $stop;
   end
   else
	 begin
		this.rcvr2sb = rcvr2sb_new;	 
	 end

endfunction : new  

task reset();

	slave.reset();

endtask : reset

task start( ref int cnt_of_packets, input bit is_random_rdy = 0 );

	automatic axi_data_t data[$];
	//automatic int number_of_packet = 1;
	cnt_of_packets = 0;
	$display("%0t : INFO    : Receiver      : start get packets ", $time );		
	forever 
	begin

		data = {};
		/* получаем пакет */
		slave.getPacket( data, is_random_rdy );
		$display("%0t : INFO    : receiver      : finished get packet number = %0d : size = %0d", $time, cnt_of_packets + 1, data.size );	
		/* кладём данные в mailbox ReceiverToScoreboard*/
		rcvr2sb.put( data );
		foreach( data[i] )
			$display("%0t : RCVR2 data[%0d] = %0x ", $time, i, data[i] );
		-> startSb;			
		cnt_of_packets++;
	end
	$display("%0t : INFO    : receiver      : end ", $time );		
endtask : start

endclass

`endif
