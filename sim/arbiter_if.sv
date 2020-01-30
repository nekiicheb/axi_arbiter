`ifndef ARBITER_INTERFACE
`define ARBITER_INTERFACE

import axi_arbiter_pkg::*;

/* интерфейс для диагностики переключений arbiter */
interface Arbiter(input bit aclk);
	logic [CHANNELS_W-1:0] idx_channel;

endinterface

`endif 