// Задержка модуля равна 1 такту, Латентность 0 тактов.
module axi_arbiter
#( 
  parameter NUM_CHANNELS  = 4, // допустимые значения, кратные степеням двойки: 2, 4, 8... ( TODO: протестировал только для 4 )
	parameter CHANNELS_W    = ( $clog2( NUM_CHANNELS ) )
)
(
  input 				  	clk_i,
  input 				  	rst_n,
  IAxiStream.Slave  in[NUM_CHANNELS],
  IAxiStream.Master out
	
	// synthesis translate_off
	/* для тестирования переключений мультиплексора */
	,output [CHANNELS_W-1:0] idx_channel
	// synthesis translate_on

);

// TODO: дублирование кода! можно избавиться, если разрешить редактирование файла axi_if.sv. 
// Исходя из задания файл axi_if.sv менять нельзя
localparam DATA_SIZE = 32;
localparam ID_SIZE   = 8;
typedef logic [DATA_SIZE - 1 : 0] TData;
typedef logic [ID_SIZE - 1 : 0] TId;
typedef struct {

	logic t_valid;
	logic t_ready;
	logic t_last;
	TData t_data;
	TId t_id;
	
} axi_stream_t;

/* не синтезируется конструкция вида: интерфейс[индекс, который является переменной ]
*  пример:  in[ idx_of_current_channel ].t_valid; не синтезируется!  
*  для обхода данной проблемы реализовал структуру, которая является адаптером  
*/
axi_stream_t in_adapter [NUM_CHANNELS-1:0];

/* индекс канала, выбранного арбитром */
logic [CHANNELS_W-1:0] idx_of_current_channel;

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


enum logic [1:0] { SELECT_CHANNEL_S, TRANSFER_PACKET_S } main_state,
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

always_ff @( negedge rst_n or posedge clk_i )
begin
	if( !rst_n ) idx_of_current_channel <= '1;
	else
	begin
		if( ( main_state == SELECT_CHANNEL_S ) && is_request ) 
				idx_of_current_channel <= getNewIdx( idx_of_current_channel, requests );
	end
end

generate
genvar j;
for( j = 0; j < NUM_CHANNELS; j++ ) 
begin : in_internal_connection
	assign in_adapter[j].t_valid = in[j].t_valid;
	assign in_adapter[j].t_last  = in[j].t_last;
	assign in_adapter[j].t_data  = in[j].t_data;
	assign in_adapter[j].t_id 	 = in[j].t_id;
end

endgenerate

assign out.t_valid = ( main_state == TRANSFER_PACKET_S )? in_adapter[idx_of_current_channel].t_valid : 1'b0;
assign out.t_last  = ( main_state == TRANSFER_PACKET_S )? in_adapter[idx_of_current_channel].t_last : 1'b0; 
assign out.t_data  = in_adapter[idx_of_current_channel].t_data;
assign out.t_id    = in_adapter[idx_of_current_channel].t_id;


generate
	/* маска выбранного канала */
	logic [NUM_CHANNELS-1:0] msk_of_current_channel;
	assign msk_of_current_channel[NUM_CHANNELS-1:0] = 1'b1 << idx_of_current_channel;
	genvar k;
	for( k = 0; k < NUM_CHANNELS; k++ ) 
	begin : in_t_ready
		assign in[k].t_ready = msk_of_current_channel[k] && ( main_state == TRANSFER_PACKET_S ) && out.t_ready;
	end
	
endgenerate

/*!
* реализация алгоритма round_robin, синтезируется в приоритетный мультиплексор,
* алгоритм работает только при чётном количестве входных каналов
\param[in] old_idx Индекс старого канала
\param[in] requests Шина запросов от входных каналов 
\param[return] getNewIdx Индекс нового канала, выбранный по алгоритму round_robin 
*/
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

assign idx_channel = idx_of_current_channel;

/* модуль зависнет, если выбранный axi_master не завершит передачу пакета, выведем предупреждение */

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
	if( cnt_of_wait_valid == '1 ) $display("%0t: RTL WARNING : in.t_valid wait is exceed!", $time ); 
end

// synthesis translate_on

endmodule