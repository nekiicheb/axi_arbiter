# axi_arbiter
test task from company

Продемонстрируйте свои знания

Дан AXI-Stream-подобный интерфейс:

interface IAxiStream (
  input logic aclk,
  input logic areset_n
);

parameter DATA_SIZE = 32;
parameter ID_SIZE = 8;

typedef logic [DATA_SIZE - 1 : 0] TData;
typedef logic [ID_SIZE - 1 : 0] TId;

// -----------------------------------------------------------------------------
logic t_valid;
logic t_ready;
logic t_last;
TData t_data;
TId t_id;

// -----------------------------------------------------------------------------
modport Master(
  output t_valid,
  input  t_ready,
  output t_last,
  output t_data,
  output t_id
);

modport Slave(
  input  t_valid,
  output t_ready,
  input  t_last,
  input  t_data,
  input  t_id
);
endinterface //IAxiStream
Дан шаблон модуля арбитра, описание портов менять нельзя:

`timescale 1ns/10ps

module arbiter (
  input logic clk,
  input logic reset_n,
  IAxiStream.Slave in_0,
  IAxiStream.Slave in_1,
  IAxiStream.Slave in_2,
  IAxiStream.Slave in_3,
  IAxiStream.Master out
);
endmodule
Напишите синтезируемый модуль объединения четырёх входных потоков в один выходной. Модуль должен:

— синтезироваться как минимум в среде Quartus и симулироваться в ModelSim;
— корректно отрабатывать сигнал t_ready выходного интерфейса, приостанавливая передачу во входных интерфейсах, если это необходимо;
— осуществлять round robin арбитраж входных потоков;
— выполнять арбитраж за минимально возможное время;
— передавать пакеты целиком.

После сброса первым на передачу выбирается интерфейс с минимальным номером.