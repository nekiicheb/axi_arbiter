`ifndef AXI_ARBITER_RECEIVER
`define AXI_ARBITER_RECEIVER

`include "axi_stream_slave.sv"
import axi_arbiter_pkg::*;

class Receiver;

virtual IAxiStream.Slave slave_intf;
virtual Arbiter arbiter_intf;
IAxiStreamSlave slave;
mailbox rcvr2sb;
event startSb;

//// constructor method ////
function new(virtual IAxiStream.Slave slave_intf_new, virtual Arbiter arbiter_intf_new,
						 mailbox rcvr2sb_new, event startSb_new );

   this.slave_intf    = slave_intf_new;
	 this.arbiter_intf  = arbiter_intf_new;
	 slave = new( this.slave_intf, this.arbiter_intf );	
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

/*!
принимает пакеты из DUT и отправляет полученные значения в mailbox
\param[ref] cnt_of_packets количество принятых пакетов
\param[in] is_random_rdy Разрешить генерирование рандомного значения t_ready на шине axi_stream_slave
*/	
task start( ref int cnt_of_packets, input bit is_random_rdy = 0 );

	automatic axi_data_t dst[$];

	cnt_of_packets = 0;
	$display("%0t : INFO    : Receiver      : start get packets ", $time );		
	forever 
	begin
		dst = {};
		/* прринимаем пакет из DUT */
		slave.getPacket( dst, is_random_rdy );
		$display("%0t : INFO    : Receiver      : packet[%0d] with size = %0d was get: ", $time, cnt_of_packets + 1, dst.size );	
		/* кладём данные в mailbox ReceiverToScoreboard*/
		rcvr2sb.put( dst );
		-> startSb;			
		cnt_of_packets++;
	end
	$display("%0t : INFO    : Receiver      : end ", $time );		
endtask : start

endclass

`endif
