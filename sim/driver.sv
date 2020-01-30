`ifndef AXI_ARBITER_DRIVER
`define AXI_ARBITER_DRIVER

`include "axi_stream_master.sv"

import axi_arbiter_pkg::*;

class Driver;

virtual IAxiStream.Master master_intf;
virtual AxiAddition addition_intf;
mailbox drvr2sb;
IAxiStreamMaster master;
event startSb;

/* constructor method */
function new( virtual IAxiStream.Master master_intf_new, virtual AxiAddition addition_intf_new, 
							mailbox drvr2sb_new, event startSb_new  );

  this.master_intf = master_intf_new;
	this.addition_intf = addition_intf_new;
	master = new( this.master_intf, this.addition_intf );	
	this.startSb = startSb_new;		
  if( drvr2sb_new == null )
  begin
	  $display(" **ERROR**: drvr2sb_new is null");
	  $stop;
  end
  else
		this.drvr2sb = drvr2sb_new;
		
endfunction : new  

task reset();

	master.reset();

endtask : reset


/* method to send the packet to DUT */
task sendPackets( input int idx_channel, input int number_of_packets, 
									input bit is_random_valid = 0, input bit is_random_packet_interval = 0 ); 	
	
	automatic	axi_data_t data_to_mailbox[$];	
	
	$display("%0t : INFO    : Driver    : sendPackets() ", $time ); 									
	@( posedge addition_intf.aclk );
	for( int i = 0; i < number_of_packets; i++ )
	begin
		
		/* формируем пакет, длина не может быть = 0 */
		automatic int size_of_packet = ( i % MAX_PACKET_SIZE ) + 1;
		automatic axi_data_t data[];			
		data = new[ size_of_packet ];
		/* заполняем пакет данными от 1 до j+1 */
		foreach( data[j] )
		begin
			data[j].data = j+1;
			/* исключим логику сигнала из проверки */
			data[j].id  = size_of_packet;
		end
		master.sendPacket( data, is_random_valid, is_random_packet_interval );
		/* кладём данные в mailbox DriverToScoreboard */
		data_to_mailbox = {};
		foreach( data[j] )
		begin
			data[j].idx_channel = idx_channel;
			data_to_mailbox.push_back(data[j]);
		end
		drvr2sb.put(data_to_mailbox);
		////-> startSb;		
		$display("%0t : INFO    : Driver[%0d]    : packets[%0d] with size_of_packet = %0d sent", $time, idx_channel, i, size_of_packet );		
	end
	$display("%0t : INFO    : Driver[%0d]    : all packets sent ",$time, idx_channel ); 
endtask : sendPackets

endclass

`endif

