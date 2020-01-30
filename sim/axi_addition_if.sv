`ifndef AXI_ADDITION_INTERFACE
`define AXI_ADDITION_INTERFACE

import axi_arbiter_pkg::*;

interface AxiAddition(input bit aclk);
	logic [CHANNELS_W-1:0] idx_channel;

endinterface

`endif 