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


//interface IAxiStreamLocal (
//  input logic aclk,
//  input logic areset_n
//);
//
//parameter DATA_SIZE = 32;
//parameter ID_SIZE = 8;
//
//typedef logic [DATA_SIZE - 1 : 0] TData;
//typedef logic [ID_SIZE - 1 : 0] TId;
//
//// -----------------------------------------------------------------------------
//logic t_valid;
//logic t_ready;
//logic t_last;
//TData t_data;
//TId t_id;
//
//endinterface //IAxiStream