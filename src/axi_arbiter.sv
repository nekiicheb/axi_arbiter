module axi_arbiter
//import arbiter_pkg::*;  
#( 
  parameter NUM_CHANNELS  = 4,
	parameter CHANNELS_W    = ( $clog2( NUM_CHANNELS ) )
)
(
  input 				  	clk_i,
  input 				  	rst_n,
  IAxiStream.Slave  in[NUM_CHANNELS],
  IAxiStream.Master out//,
	//output axi_stream_t in_adapter[NUM_CHANNELS]
	
	// synthesis translate_off
	/* для тестирования переключений мультиплексора */
	,output [CHANNELS_W-1:0] idx_channel
	// synthesis translate_on

);

// TODO: дублирование кода!!! можно избавиться, если разрешить редактирование файла axi_if.sv. Исходя из задания файл axi_if.sv менять нельзя
localparam DATA_SIZE = 32;
localparam ID_SIZE   = 8;
typedef logic [DATA_SIZE - 1 : 0] TData;
typedef logic [ID_SIZE - 1 : 0] TId;
typedef struct {
	//`include "axi_if.sv"
	logic t_valid;
	logic t_ready;
	logic t_last;
	TData t_data;
	TId t_id;
	
} axi_stream_t;

/* не синтезируется конструкция вида: интерфейс[индекс, который является переменной ]
*  пример:  in[ idx_of_selected_channel ].t_valid; не синтезируется!  
*  для обхода данной проблемы реализовал структуру, которая является синтезируемым адаптером  
*/
axi_stream_t in_adapter [NUM_CHANNELS-1:0];



/* запоминаем индекс  */
logic [CHANNELS_W-1:0] idx_of_selected_channel;

logic [NUM_CHANNELS-1:0] requests;


generate
genvar i;
for( i = 0; i < NUM_CHANNELS; i++ ) 
begin : requsts_assign
	assign requests[i] = in[i].t_valid;
end

endgenerate

logic is_request;
assign is_request = |requests;


enum logic [2:0] { SELECT_CHANNEL_S, TRANSFER_PACKET_S } main_state,
																												 next_main_state;
always_comb 
begin : STATE_MACHINE_COMB
	next_main_state = main_state;
	unique case ( main_state )
		SELECT_CHANNEL_S        : if( is_request )   next_main_state = TRANSFER_PACKET_S;
			
		TRANSFER_PACKET_S       : if( out.t_valid && out.t_last && out.t_ready ) next_main_state = SELECT_CHANNEL_S;
	endcase 	 
end
	
always_ff @( negedge rst_n or posedge clk_i )
begin : STATE_MACHINE_LATCH
	if( !rst_n ) main_state <= SELECT_CHANNEL_S;
	else
	begin
		main_state <= next_main_state;
	end
end

logic [CHANNELS_W-1:0] idx_of_new_channel;

always_comb
begin //: MULTIPLEXING CHANNELS ROUND_ROBIN 
	idx_of_new_channel = getNewIdx( idx_of_selected_channel, requests ); 
end

always_ff @( negedge rst_n or posedge clk_i )
begin
	if( !rst_n ) idx_of_selected_channel <= '1;
	else
	begin
		if( ( main_state == SELECT_CHANNEL_S ) && is_request ) idx_of_selected_channel <= idx_of_new_channel;
	end
end

/* проверить сброс!!!!!!! */ 
/* нет условия!!! */

generate
genvar j;
for( j = 0; j < NUM_CHANNELS; j++ ) 
begin : in_internal_connection
	assign in_adapter[j].t_valid = in[j].t_valid;
	assign in_adapter[j].t_last  = in[j].t_last;
	assign in_adapter[j].t_data  = in[j].t_data;
	assign in_adapter[j].t_id 		= in[j].t_id;
end

endgenerate

assign out.t_valid = ( main_state == TRANSFER_PACKET_S )? in_adapter[idx_of_selected_channel].t_valid : 1'b0;
assign out.t_last  = ( main_state == TRANSFER_PACKET_S )? in_adapter[idx_of_selected_channel].t_last : 1'b0; //in_adapter[idx_of_selected_channel].t_last;
assign out.t_data  = in_adapter[idx_of_selected_channel].t_data;
assign out.t_id    = in_adapter[idx_of_selected_channel].t_id;


generate

	logic [NUM_CHANNELS-1:0] msk_of_selected_channel;
	assign msk_of_selected_channel[NUM_CHANNELS-1:0] = 1'b1 << idx_of_selected_channel;
	genvar k;
	for( k = 0; k < NUM_CHANNELS; k++ ) 
	begin : in_t_ready
		assign in_adapter[k].t_ready = msk_of_selected_channel[k] && ( main_state == TRANSFER_PACKET_S ) && out.t_ready;
		assign in[k].t_ready = in_adapter[k].t_ready;
	end
	
endgenerate

function logic [CHANNELS_W-1:0] getNewIdx ( input logic [CHANNELS_W-1:0] old_idx, 
																						input logic [NUM_CHANNELS-1:0] requests );
 /* старшая часть отбрасывается */
	getNewIdx[CHANNELS_W-1:0] = old_idx + 1'b1;
	for( int i = 0; i < NUM_CHANNELS; i++ ) 
	begin
		if( requests[getNewIdx] ) 
				break;
		else
				getNewIdx[CHANNELS_W-1:0] = getNewIdx + 1'b1;
				
	end

endfunction


// synthesis translate_off

assign idx_channel = idx_of_selected_channel;

/* модуль зависнет, если выбранный axi_master не завершит передачу пакета */

/* счетчик превышения ожидания валидности сигнала */
logic [7:0] cnt_of_wait_valid;
always_ff @( negedge rst_n or posedge clk_i )
begin
	if( !rst_n ) cnt_of_wait_valid <= '0;
	else
	begin
	if( ( main_state == TRANSFER_PACKET_S ) && out.t_valid ) cnt_of_wait_valid <= '0;
	else if( ( main_state == TRANSFER_PACKET_S ) && !out.t_valid ) cnt_of_wait_valid <= cnt_of_wait_valid + 1;
	end
end

/* если ожидание in.t_valid = 255 тактов, выводим предупреждение */
always_ff @( posedge clk_i )
begin
	if( cnt_of_wait_valid == '1 ) $display("%0t: RTL WARNING : in.t_valid wait is exceed!!!", $time ); 
end

// synthesis translate_on




endmodule