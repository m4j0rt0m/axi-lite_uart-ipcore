###################################################################
# Description:      Lattice FPGA Board Test - Makefile            #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template-fpga-lattice #
###################################################################

SHELL                      := /bin/bash
REMOTE-URL-SSH             := git@github.com:m4j0rt0m/rtl-develop-template-fpga-lattice.git
REMOTE-URL-HTTPS           := https://github.com/m4j0rt0m/rtl-develop-template-fpga-lattice.git

MKFILE_PATH                := $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR                    := $(shell dirname $(MKFILE_PATH))

### directories ###
SOURCE_DIR                  = $(TOP_DIR)/src
OUTPUT_DIR                  = $(TOP_DIR)/build
SCRIPTS_DIR                 = $(TOP_DIR)/scripts

### makefile includes ###
include $(SCRIPTS_DIR)/funct.mk
include $(SCRIPTS_DIR)/default.mk

### fpga test configuration ###
FPGA_TOP_MODULE            ?=
FPGA_VIRTUAL_PINS          ?=
FPGA_BOARD_TEST            ?=
FPGA_CLOCK_SRC             ?=

### external sources wildcards ###
EXT_VERILOG_SRC            ?=
EXT_VERILOG_HEADERS        ?=
EXT_PACKAGE_SRC            ?=
EXT_MEM_SRC                ?=
EXT_RTL_PATHS              ?=

### fpga rtl directories ###
RTL_DIRS                    = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname rtl \)))
INCLUDE_DIRS                = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname include \)))
PACKAGE_DIRS                = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname package \)))
MEM_DIRS                    = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname mem \)))

### sources directories ###
VERILOG_SRC                 = $(EXT_VERILOG_SRC) $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
VERILOG_HEADERS             = $(EXT_VERILOG_HEADERS) $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh -o -iname \*.sv -o -iname \*.v \)))
PACKAGE_SRC                 = $(EXT_PACKAGE_SRC) $(wildcard $(shell find $(PACKAGE_DIRS) -type f \( -iname \*.sv \)))
MEM_SRC                     = $(EXT_MEM_SRC) $(wildcard $(shell find $(MEM_DIRS) -type f \( -iname \*.bin -o -iname \*.hex \)))
RTL_PATHS                   = $(EXT_RTL_PATHS) $(RTL_DIRS) $(INCLUDE_DIRS) $(PACKAGE_DIRS) $(MEM_DIRS)
TOP_MODULE_FILE             = $(shell basename $(shell grep -i -w -r "module $(FPGA_TOP_MODULE)" $(RTL_PATHS) | cut -d ":" -f 1))

### include flags ###
INCLUDES_FLAGS              = $(addprefix -I, $(RTL_PATHS))

### synthesis objects ###
BUILD_DIR                   = $(OUTPUT_DIR)/$(FPGA_TOP_MODULE)
RTL_OBJS                    = $(VERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(MEM_SRC)
BIN_OBJ                     = $(BUILD_DIR)/$(PROJECT).bin
RPT_OBJ                     = $(BUILD_DIR)/$(PROJECT).rpt
CLOCKS_CONST                = $(BUILD_DIR)/$(PROJECT).clocks.py

### lattice fpga flags ###
LATTICE_TARGET             := $(or $(LATTICE_TARGET),$(DEFAULT_LATTICE_TARGET))
LATTICE_DEVICE             := $(or $(LATTICE_DEVICE),$(DEFAULT_LATTICE_DEVICE))
LATTICE_PACKAGE            := $(or $(LATTICE_PACKAGE),$(DEFAULT_LATTICE_PACKAGE))
LATTICE_CLOCK_MHZ          := $(or $(LATTICE_CLOCK_MHZ),$(DEFAULT_LATTICE_CLOCK_MHZ))
LATTICE_PNR_TOOL           := $(or $(LATTICE_PNR_TOOL),$(DEFAULT_LATTICE_PNR_TOOL))

### rtl yosys synthesis flags ###
LATTICE_SYN                 = yosys
LATTICE_SYN_INC_FLAGS       = $(addprefix -I, $(RTL_PATHS))
ifeq ($(LATTICE_PNR_TOOL),nextpnr)
LATTICE_SYN_FLAGS           = -p "read_verilog -sv -formal $(LATTICE_SYN_INC_FLAGS) $(VERILOG_SRC) $(PACKAGE_SRC); proc; opt; proc; synth_$(LATTICE_TARGET) -top $(FPGA_TOP_MODULE) -json $@"
LATTICE_PNR                 = nextpnr-ice40
ifeq ($(FPGA_USES_CLOCK),yes)
LATTICE_PNR_FLAGS           = --$(LATTICE_DEVICE) --package $(LATTICE_PACKAGE) --json $(filter %.json, $^) --asc $@ --pre-pack $(filter %.clocks.py, $^) --pcf-allow-unconstrained
else
LATTICE_PNR_FLAGS           = --$(LATTICE_DEVICE) --package $(LATTICE_PACKAGE) --json $(filter %.json, $^) --asc $@ --pcf-allow-unconstrained
endif
else
LATTICE_SYN_FLAGS           = -p "read_verilog -sv -formal $(LATTICE_SYN_INC_FLAGS) $(VERILOG_SRC) $(PACKAGE_SRC); proc; opt; proc; synth_$(LATTICE_TARGET) -top $(FPGA_TOP_MODULE) -blif $@"
LATTICE_PNR                 = arachne-pnr
LATTICE_PNR_FLAGS           = $< -d $(subst up,,$(subst hx,,$(subst lp,,$(LATTICE_DEVICE)))) -P $(LATTICE_PACKAGE) -o $@
endif
LATTICE_PCK                 = icepack
LATTICE_PCK_FLAGS           = -v $< $@
LATTICE_TIME_STA            = icetime
ifeq ($(FPGA_USES_CLOCK),yes)
LATTICE_TIME_STA_FLAGS      = -tmd $(LATTICE_DEVICE) $(addprefix -c ,$(LATTICE_CLOCK_MHZ)) -o $(BUILD_DIR)/$(PROJECT).v -r $@ $<
else
LATTICE_TIME_STA_FLAGS      = -tmd $(LATTICE_DEVICE) -o $(BUILD_DIR)/$(PROJECT).v -r $@ $<
endif
LATTICE_PROG                = iceprog
LATTICE_PROG_FLAGS          = $(BIN_OBJ)
LATTICE_PINOUT_PCF          = $(SCRIPTS_DIR)/$(FPGA_TOP_MODULE)_set_pinout.pcf
#WIP...
#LATTICE_SYN_SHOW_FLAGS      = -stretch -width -prefix $(BUILD_DIR)/$(PROJECT) -format png

### linter flags ###
LINT                        = verilator
LINT_SV_FLAGS               = +1800-2017ext+sv -sv
LINT_W_FLAGS                = -Wall -Wno-IMPORTSTAR -Wno-fatal
LINT_FLAGS                  = --lint-only --top-module $(FPGA_TOP_MODULE) $(LINT_SV_FLAGS) $(LINT_W_FLAGS) --quiet-exit --error-limit 200 $(PACKAGE_SRC) $(INCLUDES_FLAGS) $(TOP_MODULE_FILE)

all: lattice-project

ifeq ($(FPGA_BOARD_TEST),yes)
lattice-project: rtl-bin rtl-report lattice-flash-fpga
else
lattice-project: rtl-report
endif

#H# rtl-synth          : Run RTL synthesis with Yosys
rtl-bin: $(BIN_OBJ)

#H# rtl-report         : Generate report
rtl-report: $(RPT_OBJ)

#H# veritedium         : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

#H# lint               : Run the verilator linter for the RTL code
lint: print-rtl-srcs
	@if [[ "$(FPGA_TOP_MODULE)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined top module!$(_reset_)";\
	else\
		echo -e "$(_info_)\n[INFO] Linting using $(LINT) tool$(_reset_)";\
		echo -e "\n$(_flag_) cmd: $(LINT) $(LINT_FLAGS)$(_reset_)\n";\
		$(LINT) $(LINT_FLAGS);\
	fi

#H# lattice-flash-fpga : Program the BIN file into the connected Lattice FPGA
lattice-flash-fpga: $(BIN_OBJ) $(RTL_OBJS)
	@echo -e '\n$(_flag_) cmd: ${LATTICE_PROG} ${LATTICE_PROG_FLAGS}$(_reset_)\n'
	@$(LATTICE_PROG) $(LATTICE_PROG_FLAGS)

#H# fpga-rtl-sim       : Run RTL simulation (FPGA test)
fpga-rtl-sim:
	@echo -e "$(_info_)\n[INFO] FPGA Test RTL Simulation\n$(_reset_)";\
	if [[ "$(SIM_TOOL)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined RTL simulation tool!$(_reset_)";\
	else\
		for stool in $(SIM_TOOL);\
		do\
			if [[ "$(SIM_MODULES)" == "" ]]; then\
				echo -e "$(_error_)[ERROR] No defined simulation top module!$(_reset_)";\
			else\
				echo -e "$(_info_)[INFO] Simulation with $${stool} tool\n$(_reset_)";\
				for smodule in $(SIM_MODULES);\
				do\
					echo -e "$(_flag_)\n [*] Simulating Top Module : $${smodule}\n$(_reset_)";\
					$(MAKE) -C $(SIMULATION_DIR) sim\
						SIM_TOP_MODULE=$${smodule}\
						SIM_TOOL=$${stool}\
						SIM_CREATE_VCD=$(SIM_CREATE_VCD)\
						SIM_OPEN_WAVE=$(SIM_OPEN_WAVE)\
						EXT_VERILOG_SRC="$(VERILOG_SRC)"\
						EXT_VERILOG_HEADERS="$(VERILOG_HEADERS)"\
						EXT_PACKAGE_SRC="$(PACKAGE_SRC)"\
						EXT_MEM_SRC="$(MEM_SRC)"\
						EXT_RTL_PATHS="$(RTL_PATHS)";\
				done;\
			fi;\
		done;\
	fi

%.blif %.json: $(RTL_OBJS)
	@mkdir -p $(BUILD_DIR)
	@echo -e '\n$(_flag_) cmd: ${LATTICE_SYN} ${LATTICE_SYN_FLAGS}$(_reset_)\n'
	@$(LATTICE_SYN) $(LATTICE_SYN_FLAGS)

ifeq ($(LATTICE_PNR_TOOL),nextpnr)
ifeq ($(FPGA_USES_CLOCK),yes)
%.asc: %.json %.clocks.py
else
%.asc: %.json
endif
	@if [[ "$(FPGA_VIRTUAL_PINS)" == "yes" ]]; then\
		echo -e '\n$(_flag_) cmd: ${LATTICE_PNR} ${LATTICE_PNR_FLAGS}$(_reset_)\n';\
		$(LATTICE_PNR) $(LATTICE_PNR_FLAGS);\
	else\
		echo -e '\n$(_flag_) cmd: ${LATTICE_PNR} --pcf ${LATTICE_PINOUT_PCF} ${LATTICE_PNR_FLAGS}$(_reset_)\n';\
		$(LATTICE_PNR) --pcf $(LATTICE_PINOUT_PCF) $(LATTICE_PNR_FLAGS);\
	fi
else
%.asc: %.blif
	@if [[ "$(FPGA_VIRTUAL_PINS)" == "yes" ]]; then\
		echo -e '\n$(_flag_) cmd: ${LATTICE_PNR} ${LATTICE_PNR_FLAGS}$(_reset_)\n';\
		$(LATTICE_PNR) $(LATTICE_PNR_FLAGS);\
	else\
		echo -e '\n$(_flag_) cmd: ${LATTICE_PNR} -p ${LATTICE_PINOUT_PCF} ${LATTICE_PNR_FLAGS}$(_reset_)\n';\
		$(LATTICE_PNR) -p $(LATTICE_PINOUT_PCF) $(LATTICE_PNR_FLAGS);\
	fi
endif

%.clocks.py:
	@mkdir -p $(BUILD_DIR);\
	echo -e "\n$(_info_) Creating clock constraints...\n";\
	echo "# Automatically created by the Makefile #" | tee $(CLOCKS_CONST);\
	fpga_clock_src=($(FPGA_CLOCK_SRC));\
	lattice_clock_mhz=($(LATTICE_CLOCK_MHZ));\
	for csrc in `seq 0 $$(($${#fpga_clock_src[@]}-1))`;\
	do\
		echo "ctx.addClock(\"$${fpga_clock_src[$$csrc]}\",$${lattice_clock_mhz[$$csrc]})" | tee -a $(CLOCKS_CONST);\
	done

%.rpt: %.asc
	@if [[ "$(FPGA_VIRTUAL_PINS)" == "yes" ]]; then\
		echo -e '\n$(_flag_) cmd: ${LATTICE_TIME_STA} ${LATTICE_TIME_STA_FLAGS}$(_reset_)\n';\
		$(LATTICE_TIME_STA) $(LATTICE_TIME_STA_FLAGS);\
	else\
		echo -e '\n$(_flag_) cmd: ${LATTICE_TIME_STA} -p ${LATTICE_PINOUT_PCF} ${LATTICE_TIME_STA_FLAGS}$(_reset_)\n';\
		$(LATTICE_TIME_STA) -p $(LATTICE_PINOUT_PCF) $(LATTICE_TIME_STA_FLAGS);\
	fi

%.bin: %.asc
	@echo -e '\n$(_flag_) cmd: ${LATTICE_PCK} ${LATTICE_PCK_FLAGS}$(_reset_)\n'
	@$(LATTICE_PCK) $(LATTICE_PCK_FLAGS)

#H# print-rtl-srcs     : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# clean              : Clean build directory
clean:
	rm -rf build/*

#H# help               : Display help
help: Makefile
	@echo -e "\nFPGA Test Help - Lattice\n"
	@sed -n 's/^#H#//p' $<
	@echo ""

.PHONY: all lattice-project rtl-bin rtl-report veritedium lint lattice-flash-fpga print-rtl-srcs clean help
