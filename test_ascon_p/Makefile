SIM ?= icarus
TOPLEVEL_LANG ?= verilog

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

VERILOG_SOURCES += $(PWD)/../rtl/ascon_permute.sv

TOPLEVEL = ascon_permute

MODULE = ascon_permute

export WAVES = 1

include $(shell cocotb-config --makefiles)/Makefile.sim