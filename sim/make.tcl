proc do_compile {} {
  # exec rm -rf work/
  vlib work
  vdel -lib work -all
  vlib work
 
  vlog -work work "../src/*.sv"	
	vlog -work work "axi_arbiter_pkg.sv" 		
	vlog -work work "arbiter_if.sv" 	
	vlog -work work "*.sv" 	
}

proc start_sim {} {
  # insert name of testbench module
	vsim -novopt -L lpm_ver -L sgate_ver -L altera_mf_ver tb_top 

  # adding all waveforms in hex view
  add wave -r -hex *

  # running simulation for some time
  # you can change for run -all for infinity simulation :-)
  run -all 
  # run 1ns
}


proc show_coverage {} {
  coverage save 1.ucdb
  vcover report 1.ucdb -verbose -cvg
}

proc run_test {} {
  do_compile
  start_sim
}

proc help {} {
  echo "help                - show this message"
  echo "do_compile          - compile all"
  echo "start_sim           - start simulation"
  echo "run_test            - do_compile & start_sim"
  echo "show_coverage       - show coverage report"
}

help
