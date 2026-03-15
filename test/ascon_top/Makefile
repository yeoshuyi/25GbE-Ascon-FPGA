SIM ?= icarus
TOPLEVEL_LANG ?= verilog

RTL_DIR = $(PWD)/../../rtl
VERILOG_SOURCES += $(RTL_DIR)/ascon_round.sv
VERILOG_SOURCES += $(RTL_DIR)/ascon_permute.sv
VERILOG_SOURCES += $(RTL_DIR)/ascon_xof.sv

TOPLEVEL = ascon_xof

MODULE = verify

export WAVES = 1
include $(shell cocotb-config --makefiles)/Makefile.sim

log:
	COCOTB_LOG_LEVEL=DEBUG $(MAKE) sim | tee sim.txt