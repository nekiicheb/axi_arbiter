`ifndef AXI_ADDITION_INTERFACE
`define AXI_ADDITION_INTERFACE

`include "globals.vh"

interface AxiAddition(input bit aclk);
	logic [`CHANNELS_W-1:0] idx_channel;

endinterface

`endif 