IVERILOG ?= iverilog
VVP ?= vvp

INSTRUCTION_RTL = rtl/program_counter.v rtl/instruction_memory.v
DATA_RTL = rtl/data_path.v rtl/address_decoder.v rtl/read_write_control.v rtl/data_memory.v
HARVARD_RTL = $(INSTRUCTION_RTL) $(DATA_RTL) rtl/harvard_top.v

.PHONY: test-instruction test-data test-harvard test-harvard-directed test-comparison

test-instruction: build/tb_instruction_path
	$(VVP) $<

test-data: build/tb_data_path
	$(VVP) $<

test-harvard: build/tb_harvard
	$(VVP) $<

test-harvard-directed: build/tb_harvard_directed
	$(VVP) $<

test-comparison: build/tb_comparison
	$(VVP) $<

build/tb_instruction_path: $(INSTRUCTION_RTL) testbench/tb_instruction_path.v
build/tb_data_path: $(DATA_RTL) testbench/tb_data_path.v
build/tb_harvard: $(HARVARD_RTL) rtl/controller.v testbench/tb_harvard.v
build/tb_harvard_directed: $(HARVARD_RTL) testbench/tb_harvard_directed.v
build/tb_comparison: $(HARVARD_RTL) rtl/shared_memory.v testbench/tb_comparison.v

build/tb_instruction_path build/tb_data_path build/tb_harvard build/tb_harvard_directed build/tb_comparison:
	mkdir -p build
	$(IVERILOG) -g2005 -Wall -s $(@F) -o $@ $^
