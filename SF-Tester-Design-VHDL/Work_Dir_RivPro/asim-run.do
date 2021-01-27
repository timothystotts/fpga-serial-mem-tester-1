source ./asim-compile-osvvm.do
source ./asim-compile-work.do

asim +access +r -dbg work.test_default_fpga_regression
#asim work.test_default_fpga_regression
run -all
