module arbiter
(
  input 				  	clk,
  input 				  	reset_n,
  IAxiStream.Slave  in_0,
  IAxiStream.Slave  in_1, 
  IAxiStream.Slave  in_2,
  IAxiStream.Slave  in_3,
  IAxiStream.Master out
	
	// synthesis translate_off
	/* для тестирования переключений каналов арбитера */
	,output 	[1:0] 	idx_channel
	// synthesis translate_on
);

/* количество входных каналов для арбитра*/	 
localparam NUM_CHANNELS  = 4;
/* размер каналов для арбитра*/	
localparam CHANNELS_W    = ( $clog2( NUM_CHANNELS ) );

IAxiStream in[NUM_CHANNELS] (clk, reset_n);

/* TODO 
*  Не параметризованный код, но рабочий. в rtl_viewer создаются буфера, 
*  Пока не нашёл способа работы с массивами интерфейсов
*/
generate
	assign in[0].t_valid = in_0.t_valid;
	assign in[0].t_last  = in_0.t_last;
	assign in[0].t_data  = in_0.t_data;
	assign in[0].t_id 	 = in_0.t_id;
	assign in_0.t_ready  = in[0].t_ready;

	assign in[1].t_valid = in_1.t_valid;
	assign in[1].t_last  = in_1.t_last;
	assign in[1].t_data  = in_1.t_data;
	assign in[1].t_id 	 = in_1.t_id;
	assign in_1.t_ready  = in[1].t_ready;

	assign in[2].t_valid = in_2.t_valid;
	assign in[2].t_last  = in_2.t_last;
	assign in[2].t_data  = in_2.t_data;
	assign in[2].t_id 	 = in_2.t_id;
	assign in_2.t_ready  = in[2].t_ready;

	assign in[3].t_valid = in_3.t_valid;
	assign in[3].t_last  = in_3.t_last;
	assign in[3].t_data  = in_3.t_data;
	assign in[3].t_id 	 = in_3.t_id;
	assign in_3.t_ready  = in[3].t_ready;
endgenerate


axi_arbiter
#( 
	.NUM_CHANNELS ( NUM_CHANNELS ),
	.CHANNELS_W   ( CHANNELS_W )

) axi_arbiter
(	
  .clk_i				( clk ),
  .rst_n				( reset_n ),

  .in 					( in ),
  .out					( out  )
  // synthesis translate_off
  ,.idx_channel	( idx_channel )
  // synthesis translate_on

);
	
endmodule