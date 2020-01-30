`ifndef AXI_ARBITER_SCOREBOARD
`define AXI_ARBITER_SCOREBOARD

`include "globals.vh"

import axi_arbiter_pkg::*;

class Scoreboard;

mailbox drvr2sb;
mailbox rcvr2sb;
event startSb; 

function new( mailbox drvr2sb_new, mailbox rcvr2sb_new, event startSb_new  );

  this.drvr2sb = drvr2sb_new;
  this.rcvr2sb = rcvr2sb_new;
	this.startSb = startSb_new;

endfunction : new


task start( ref int cnt_of_packets, input int is_check_sequence = 1 );

	automatic int number_of_packet;
	automatic axi_data_t	drvrBuf[$];	
	automatic axi_data_t	rcvrBuf[$];

	cnt_of_packets = 0;
	forever 
	begin
		drvrBuf = {}; // clear queue
		rcvrBuf = {}; // clear queue	
		/* ожидаем данных от receiver и driver */
		@startSb;
		$display( "%0t : INFO    : Scoreboard      : 	cnt_of_packets = %0d", $time, 	cnt_of_packets + 1 ); 	
    rcvr2sb.get(rcvrBuf);
    drvr2sb.get(drvrBuf);

		foreach( rcvrBuf[i] )
		begin
			/* сравниваем данные буферов driver и receiver */
			if( rcvrBuf[i].data == drvrBuf[i].data )
			begin
				$display("%0t : INFO    : Scoreboard      : equal rcvrData[%0d].data =%0x, drvrData[%0d].data =%0x,", 
									$time, i, rcvrBuf[i].data, i, drvrBuf[i].data );
			end						
			else
			begin
				$display("%0t : ERROR : Scoreboard      :  doesn't equal rcvrData[%0d].data =%0x, drvrData[%0d].data =%0x,", 
									$time, i, rcvrBuf[i].data, i, drvrBuf[i].data );	
				$display("%0t : ERROR    : Scoreboard      : drvr2sb.size = %0d, rcvr2sb.size = %0d, length doesn't equal", 
																																			$time, drvrBuf.size(), rcvrBuf.size() );						
				//#20;
				$stop;
			end
			/* сравниваем текущий id канала driver и ожидаемый id канала receiver */
			if( rcvrBuf[i].id == drvrBuf[i].id )
			begin
				$display("%0t : INFO    : Scoreboard      : equal rcvrData[%0d].id = %0x, drvrData[%0d].id = %0x,", 
									$time, i, rcvrBuf[i].id, i, drvrBuf[i].id );				
			end
			else
			begin
				$display("%0t : ERROR : Scoreboard      :  doesn't equal rcvrData[%0d].id = %0x, drvrData[%0d].id = %0x,", 
									$time, i, rcvrBuf[i].id, i, drvrBuf[i].id );			
				//#20;
				$stop;			
			end				
			/* сравниваем текущий индекс канала driver и ожидаемый индекс канала receiver */
			if( rcvrBuf[i].idx_channel == drvrBuf[i].idx_channel )
			begin
				$display("%0t : INFO    : Scoreboard      : equal rcvrData[%0d].idx_channel = %0x, drvrData[%0d].idx_channel = %0x,", 
									$time, i, rcvrBuf[i].idx_channel, i, drvrBuf[i].idx_channel );				
			end
			else
			begin
				$display("%0t : ERROR : Scoreboard      :  doesn't equal rcvrData[%0d].idx_channel = %0x, drvrData[%0d].idx_channel = %0x,", 
									$time, i, rcvrBuf[i].idx_channel, i, drvrBuf[i].idx_channel );			
				//#20;
				$stop;			
			end			
			/* тестирование алгоритма round-robin 
			*  сравниваем ожидаемую последователность переключений каналов с получаемой, после reset первый канал = 0! */
			if( is_check_sequence )
			begin
				if( cnt_of_packets % `NUM_CHANNELS != rcvrBuf[i].idx_channel )
				begin
					$display("%0t : ERROR    : Scoreboard      : expected_round_robin_idx = %0d is not equal rcvrBuf.idx_channel = %0d", 
											$time, cnt_of_packets % `NUM_CHANNELS, rcvrBuf[i].idx_channel );	
					//#20;
					$stop;											
				end
				else
				begin
					$display("%0t : INFO    : Scoreboard      : expected_round_robin_idx = %0d is equal rcvrBuf.idx_channel = %0d", 
											$time, cnt_of_packets % `NUM_CHANNELS, rcvrBuf[i].idx_channel );					
				
				end
			end
		end	
		
		/* сравниваем размер буферов driver и receiver */
		if( drvrBuf.size() != rcvrBuf.size() )
		begin
			$display("%0t : ERROR    : Scoreboard      : drvr2sb.size = %0d, rcvr2sb.size = %0d, length doesn't equal", 
																																			$time, drvrBuf.size(), rcvrBuf.size() );	
			//#20;
			$stop;		
		end
		else
		begin
			$display("%0t : INFO    : Scoreboard      : drvr2sb.size = %0d, rcvr2sb.size = %0d, length equal", 
																																			$time, drvrBuf.size(), rcvrBuf.size() );		
		end		
		cnt_of_packets++;	
	end

endtask : start

endclass

`endif

