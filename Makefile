#################################################################
# Author:       Abraham J. Ruiz R. (https://github.com/m4j0rt0m)
# Description:  AXI-Lite UART Slave Project Makefile
#################################################################

MKFILE_PATH         = $(abspath $(lastword $(MAKEFILE_LIST)))
TOP_DIR             = $(shell dirname $(MKFILE_PATH))

### DIRECTORIES ###
SOURCE_DIR          = $(TOP_DIR)/rtl
OUTPUT_DIR          = $(TOP_DIR)/build
#TESTBENCH_DIR       = $(TOP_DIR)/test_bench
SCRIPT_DIR          = $(TOP_DIR)/scripts

### RTL WILDCARDS ###
PRJ_SRC             = $(wildcard $(shell find $(SOURCE_DIR) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
PRJ_DIRS            = $(wildcard $(shell find $(SOURCE_DIR) -type d))
PRJ_HEADERS         = $(wildcard $(shell find $(SOURCE_DIR) -type f \( -iname \*.h \)))
#TESTBENCH_SRC       = $(wildcard $(shell find $(TESTBENCH_DIR) -type f \( -iname \*.v \)))
PRJ_INCLUDES        = $(addprefix -I, $(PRJ_DIRS))

### PROJECT ###
PROJECT             = axi_uart
TOP_MODULE          = axi_uart_top
TOP_MODULE_FILE     = $(shell basename $(shell grep -r "module $(TOP_MODULE)" $(SOURCE_DIR) | cut -d ":" -f 1))

### LINTER ###
LINT                = verilator
LINT_FLAGS          = --lint-only --top-module $(TOP_MODULE) -Wall -Wno-fatal $(PRJ_INCLUDES)

### SIMULATION ###
TOP_MODULE_SIM      = axi_uart_top
NAME_MODULE_SIM     = $(TOP_MODULE_SIM)_tb
SIM                 = iverilog
SIM_FLAGS           = -o $(OUTPUT_DIR)/$(TOP_MODULE).tb -s $(NAME_MODULE_SIM) -DSIMULATION $(PRJ_INCLUDES) -v -Wall
RUN                 = vvp
RUN_FLAGS           = -v

### FUNCTION DEFINES ###
define veritedium-command
emacs --batch $(1) -f verilog-auto -f save-buffer;
endef
define set_source_file_tcl
echo "set_global_assignment -name SOURCE_FILE $(1)" >> $(CREATE_PROJECT_TCL);
endef
define set_sdc_file_tcl
echo "set_global_assignment -name SDC_FILE $(1)" >> $(CREATE_PROJECT_TCL);
endef

### ALTERA FPGA COMPILATION ###
CLOCK_PORT					=	clk_i
CLOCK_PERIOD				=	10
SOF_FILE            = $(TOP_MODULE).sof
CREATE_PROJECT_TCL  = $(SCRIPT_DIR)/create_project.tcl
PROJECT_SDC         = $(SCRIPT_DIR)/$(PROJECT).sdc
DEVICE_FAMILY       = "Cyclone IV E"
DEVICE_PART         = "EP4CE22F17C6"
MIN_CORE_TEMP       = 0
MAX_CORE_TEMP       = 85
PACKING_OPTION      = "normal"
PINOUT_TCL          = $(SCRIPT_DIR)/set_pinout.tcl
FPGA_CABLE          = usb-blaster
PROGRAM_MODE        = jtag
CONNECT_USB_BLASTER = $(SCRIPT_DIR)/connect_usb_blaster.sh

### QUARTUS CLI ###
QUARTUS_SH          = quartus_sh
QUARTUS_MAP         = quartus_map
QUARTUS_FIT         = quartus_fit
QUARTUS_ASM         = quartus_asm
QUARTUS_STA         = quartus_sta
QUARTUS_PGM         = quartus_pgm

all: veritedium lint sim

veritedium:
	$(foreach SRC,$(PRJ_SRC),$(call veritedium-command,$(SRC)))
	$(foreach SRC,$(TESTBENCH_SRC),$(call veritedium-command,$(SRC)))

lint:
	$(LINT) $(TOP_MODULE_FILE) $(LINT_FLAGS)

sim-all: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd $(TESTBENCH_SRC)
	@(gtkwave $< > /dev/null 2>&1 &)

sim: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd $(TESTBENCH_SRC)

run-sim: $(TESTBENCH_SRC) $(PRJ_SRC) $(PRJ_HEADERS)
	mkdir -p $(OUTPUT_DIR)
	$(SIM) $(SIM_FLAGS) $^
	$(RUN) $(RUN_FLAGS) $(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb
	mv $(TOP_MODULE_SIM).vcd $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd

project: compile

compile: veritedium create_project set_pinout compile_flow

compile_flow:
	$(QUARTUS_SH) --flow compile $(PROJECT)

set_pinout:
	$(QUARTUS_SH) -t $(PINOUT_TCL) $(PROJECT)

connect:
	$(CONNECT_USB_BLASTER)

scan:
	$(QUARTUS_PGM) --auto

flash_fpga:
	$(QUARTUS_PGM) -m $(PROGRAM_MODE) -c $(FPGA_CABLE) -o "p;$(SOF_FILE)@1"

create_project: create_project_tcl
	$(QUARTUS_SH) -t $(CREATE_PROJECT_TCL)

create_project_tcl: create_sdc
	rm -rf $(CREATE_PROJECT_TCL)
	@(echo "# Automatically created by Makefile #" > $(CREATE_PROJECT_TCL))
	@(echo "set project_name $(PROJECT)" >> $(CREATE_PROJECT_TCL))
	@(echo "if [catch {project_open $(PROJECT)}] {project_new $(PROJECT)}" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name MIN_CORE_JUNCTION_TEMP $(MIN_CORE_TEMP)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name MAX_CORE_JUNCTION_TEMP $(MAX_CORE_TEMP)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name FAMILY \"$(DEVICE_FAMILY)\"" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP_MODULE)" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name DEVICE \"$(DEVICE_PART)\"" >> $(CREATE_PROJECT_TCL))
	@(echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256" >> $(CREATE_PROJECT_TCL))
	$(foreach SRC,$(PRJ_SRC),$(call set_source_file_tcl,$(SRC)))
	$(foreach SRC,$(PRJ_HEADERS),$(call set_source_file_tcl,$(SRC)))
	$(foreach SRC,$(QSYS_SRC),$(call set_source_file_tcl,$(SRC)))
	@(echo "set_global_assignment -name SDC_FILE $(PROJECT_SDC)" >> $(CREATE_PROJECT_TCL))
	@(echo "project_close" >> $(CREATE_PROJECT_TCL))
	@(echo "qexit -success" >> $(CREATE_PROJECT_TCL))

create_sdc:
	rm -rf $(PROJECT_SDC)
	@(echo "create_clock -name $(CLOCK_PORT) -period $(CLOCK_PERIOD) [get_ports {$(CLOCK_PORT)}]" > $(PROJECT_SDC))
	@(echo "derive_clock_uncertainty" >> $(PROJECT_SDC))

del-bak:
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete

clean:
	rm -rf ./build/*

clean-all: del-bak
	rm -rf ./build
	rm -rf ./db
	rm -rf ./incremental_db
	rm -rf ./simulation
	rm -rf ./*.rpt
	rm -rf ./*.smsg
	rm -rf ./*.summary
	rm -rf ./*.jdi
	rm -rf ./*.pin
	rm -rf ./*.qpf
	rm -rf ./*.qsf
	rm -rf ./*.sld
	rm -rf ./*.qws
	rm -rf ./*.done
	rm -rf ./*.sof

$(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb: $(TESTBENCH_SRC) $(PRJ_SRC) $(PRJ_HEADERS)
	mkdir -p $(OUTPUT_DIR)
	$(SIM) $(SIM_FLAGS) $^

$(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd: $(OUTPUT_DIR)/$(TOP_MODULE_SIM).tb $(PRJ_SRC) $(PRJ_HEADERS)
	$(RUN) $(RUN_FLAGS) $<
	mv $(TOP_MODULE_SIM).vcd $(OUTPUT_DIR)/$(TOP_MODULE_SIM).vcd

.PHONY: all veritedium lint sim clean clean-all project compile compile_flow set_pinout connect scan flash_fpga create_project create_project_tcl
