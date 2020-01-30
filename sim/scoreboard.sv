`ifndef AXI_ARBITER_SCOREBOARD
`define AXI_ARBITER_SCOREBOARD

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

/*!
принимает пакеты из DUT
\param[ref] cnt_of_packets количество проверенных пакетов
\param[in] is_check_sequence Разрешить контроль последовательности переключений arbiter. Например 0->1->2..
*/	
task start( ref int cnt_of_packets, input int is_check_sequence = 1 );

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
			/* сравниваем принятые t_data с ожидаемыми t_data  */
			if( rcvrBuf[i].data != drvrBuf[i].data )
			begin
				$display("%0t : ERROR : Scoreboard      :  rcvrData[%0d].t_data =%0x doesn't equal drvrData[%0d].t_data =%0x", 
									$time, i, rcvrBuf[i].data, i, drvrBuf[i].data );						
				$stop;			
			end						
			else
			begin
/* 				$display("%0t : INFO    : Scoreboard      : rcvrData[%0d].t_data =%0x equal  drvrData[%0d].t_data =%0x", 
									$time, i, rcvrBuf[i].data, i, drvrBuf[i].data ); */
			end
			/* сравниваем принятые t_id с ожидаемыми t_id  */
			if( rcvrBuf[i].id != drvrBuf[i].id )
			begin
				$display("%0t : ERROR : Scoreboard      :  doesn't equal rcvrData[%0d].t_id = %0x, drvrData[%0d].t_id = %0x", 
									$time, i, rcvrBuf[i].id, i, drvrBuf[i].id );			
				$stop;							
			end
			else
			begin
/* 				$display("%0t : INFO    : Scoreboard      : rcvrData[%0d].t_id = %0x equal drvrData[%0d].t_id = %0x", 
									$time, i, rcvrBuf[i].id, i, drvrBuf[i].id );		 */	
			end				
			/* сравниваем принятый индекс канала  и ожидаемый индекс канала */
			if( rcvrBuf[i].idx_channel != drvrBuf[i].idx_channel )
			begin
				$display("%0t : ERROR : Scoreboard      :  doesn't equal rcvrData[%0d].idx_channel = %0x doesn't equal drvrData[%0d].idx_channel = %0x", 
									$time, i, rcvrBuf[i].idx_channel, i, drvrBuf[i].idx_channel );		
				$stop;										
			end
			else
			begin
/* 				$display("%0t : INFO    : Scoreboard      : rcvrData[%0d].idx_channel = %0x equal  drvrData[%0d].idx_channel = %0x", 
									$time, i, rcvrBuf[i].idx_channel, i, drvrBuf[i].idx_channel );		 */					
			end			
			/* тестирование алгоритма round-robin 
			*  сравниваем ожидаемую последователность переключений каналов с получаемой, после reset первый канал = 0! */
			if( is_check_sequence )
			begin
				if( cnt_of_packets % NUM_CHANNELS != rcvrBuf[i].idx_channel )
				begin
					$display("%0t : ERROR    : Scoreboard      : expected_round_robin_idx = %0d doesn't equal rcvrBuf.idx_channel = %0d", 
											$time, cnt_of_packets % NUM_CHANNELS, rcvrBuf[i].idx_channel );	
					$stop;											
				end
				else
				begin
/* 					$display("%0t : INFO    : Scoreboard      : expected_round_robin_idx = %0d equal rcvrBuf.idx_channel = %0d", 
											$time, cnt_of_packets % NUM_CHANNELS, rcvrBuf[i].idx_channel );		 */			
				
				end
			end
		end	
		
		/* сравниваем размер принятого и ожидаемого буферов */
		if( drvrBuf.size() != rcvrBuf.size() )
		begin
			$display("%0t : ERROR    : Scoreboard      : drvr2sb.size = %0d doesn't equal rcvr2sb.size = %0d", 
																																			$time, drvrBuf.size(), rcvrBuf.size() );	
			$stop;		
		end
		else
		begin
			$display("%0t : INFO    : Scoreboard      : drvr2sb.size = %0d equal rcvr2sb.size = %0d", 
																																			$time, drvrBuf.size(), rcvrBuf.size() );		
		end		
		cnt_of_packets++;	
	end

endtask : start

endclass

`endif

