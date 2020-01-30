package axi_arbiter_pkg;

/* параметр из файла axi_if.sv из задания нельзя менять входной файл */
parameter DATA_SIZE  = 32;
/* параметр из файла axi_if.sv из задания нельзя менять входной файл */
parameter ID_SIZE    = 8;
/* количество входных каналов в арбитр */
parameter NUM_CHANNELS  = 4;
/* размер входных каналов в арбитр */
parameter CHANNELS_W  = ( $clog2( NUM_CHANNELS ) );
/* максимальный размер пакета драйвера */
parameter MAX_PACKET_SIZE = 4;

//`include "axi_addition_if.sv"

/* структура для обмена данными средствами mailbox */
typedef logic [CHANNELS_W-1:0] Channel;
typedef struct packed{
	logic  [DATA_SIZE-1:0] data;
	logic    [ID_SIZE-1:0] id;
	Channel idx_channel;
	
} axi_data_t;

endpackage