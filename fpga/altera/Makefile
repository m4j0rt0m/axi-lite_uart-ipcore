###################################################################
# Description:      Altera FPGA Board Test - Makefile             #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template-fpga-altera  #
###################################################################

SHELL                      := /bin/bash
REMOTE-URL-SSH             := git@github.com:m4j0rt0m/rtl-develop-template-fpga-altera.git
REMOTE-URL-HTTPS           := https://github.com/m4j0rt0m/rtl-develop-template-fpga-altera.git

MKFILE_PATH                := $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR                    := $(shell dirname $(MKFILE_PATH))

### directories ###
SOURCE_DIR                  = $(TOP_DIR)/src
OUTPUT_DIR                  = $(TOP_DIR)/build
SIMULATION_DIR              = $(TOP_DIR)/simulation
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

### sources wildcards ###
VERILOG_SRC                 = $(EXT_VERILOG_SRC) $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
VERILOG_HEADERS             = $(EXT_VERILOG_HEADERS) $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh -o -iname \*.sv -o -iname \*.v \)))
PACKAGE_SRC                 = $(EXT_PACKAGE_SRC) $(wildcard $(shell find $(PACKAGE_DIRS) -type f \( -iname \*.sv \)))
MEM_SRC                     = $(EXT_MEM_SRC) $(wildcard $(shell find $(MEM_DIRS) -type f \( -iname \*.bin -o -iname \*.hex \)))
RTL_PATHS                   = $(EXT_RTL_PATHS) $(RTL_DIRS) $(INCLUDE_DIRS) $(PACKAGE_DIRS) $(MEM_DIRS)
TOP_MODULE_FILE             = $(shell basename $(shell grep -i -w -r "module $(FPGA_TOP_MODULE)" $(RTL_PATHS) | cut -d ":" -f 1))

### include flags ###
INCLUDES_FLAGS              = $(addprefix -I, $(RTL_PATHS))

### quartus cli ###
QUARTUS_SH                  = quartus_sh
QUARTUS_PGM                 = quartus_pgm

### altera fpga compilation flags ###
ALTERA_TARGET              := $(or $(ALTERA_TARGET),$(DEFAULT_ALTERA_TARGET))
ALTERA_DEVICE              := $(or $(ALTERA_DEVICE),$(DEFAULT_ALTERA_DEVICE))
ALTERA_PACKAGE             := $(or $(ALTERA_PACKAGE),$(DEFAULT_ALTERA_PACKAGE))
ALTERA_CLOCK_MHZ           := $(or $(ALTERA_CLOCK_MHZ),$(DEFAULT_ALTERA_CLOCK_MHZ))
ALTERA_MIN_TEMP            := $(or $(ALTERA_MIN_TEMP),$(DEFAULT_ALTERA_MIN_TEMP))
ALTERA_MAX_TEMP            := $(or $(ALTERA_MAX_TEMP),$(DEFAULT_ALTERA_MAX_TEMP))

### synthesis objects ###
BUILD_DIR                   = $(OUTPUT_DIR)/$(FPGA_TOP_MODULE)
ALTERA_PROJECT_FILES        = $(BUILD_DIR)/$(PROJECT).qpf $(BUILD_DIR)/$(PROJECT).qsf
ALTERA_CREATE_PROJECT_TCL   = $(BUILD_DIR)/quartus_create_project_$(PROJECT).tcl
ALTERA_PROJECT_SDC          = $(BUILD_DIR)/quartus_project_$(PROJECT).sdc
Q_MAP_RPT                   = $(BUILD_DIR)/$(PROJECT).map.rpt
Q_FIT_RPT                   = $(BUILD_DIR)/$(PROJECT).fit.rpt
Q_ASM_RPT                   = $(BUILD_DIR)/$(PROJECT).asm.rpt
Q_STA_RPT                   = $(BUILD_DIR)/$(PROJECT).sta.rpt
RTL_OBJS                    = $(VERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(MEM_SRC)
RPT_OBJS                    = $(Q_MAP_RPT) $(Q_FIT_RPT) $(Q_ASM_RPT) $(Q_STA_RPT)
ifeq ($(FPGA_USES_CLOCK),yes)
ALTERA_VIRTUAL_PINS_TCL     = $(SCRIPTS_DIR)/virtual_pins_all_pins_xcpt_clk.tcl
else
ALTERA_VIRTUAL_PINS_TCL     = $(SCRIPTS_DIR)/virtual_pins_all_pins.tcl
endif

### altera fpga board flags ###
ALTERA_FPGA_CABLE           = usb-blaster
ALTERA_PROGRAM_MODE         = jtag
ALTERA_CONNECT_USB_BLASTER  = $(SCRIPTS_DIR)/connect_usb_blaster
ALTERA_PINOUT_TCL           = $(SCRIPTS_DIR)/$(FPGA_TOP_MODULE)_set_pinout.tcl
ALTERA_SOF_FILE             = $(BUILD_DIR)/$(PROJECT).sof

### linter flags ###
LINT                        = verilator
LINT_SV_FLAGS               = +1800-2017ext+sv -sv
LINT_W_FLAGS                = -Wall -Wno-IMPORTSTAR -Wno-fatal
LINT_FLAGS                  = --lint-only --top-module $(FPGA_TOP_MODULE) $(LINT_SV_FLAGS) $(LINT_W_FLAGS) --quiet-exit --error-limit 200 $(PACKAGE_SRC) $(INCLUDES_FLAGS) $(TOP_MODULE_FILE)

all: altera-project

#H# veritedium                  : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

#H# lint                        : Run the verilator linter for the RTL code
lint: print-rtl-srcs
	@if [[ "$(FPGA_TOP_MODULE)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined top module!$(_reset_)";\
	else\
		echo -e "$(_info_)\n[INFO] Linting using $(LINT) tool$(_reset_)";\
		echo -e "\n$(_flag_) cmd: $(LINT) $(LINT_FLAGS)$(_reset_)\n";\
		$(LINT) $(LINT_FLAGS);\
	fi

#H# altera-project              : Run Altera FPGA test
ifeq ($(FPGA_BOARD_TEST),yes)
altera-project: print-rtl-srcs $(RPT_OBJS) altera-flash-fpga
else
altera-project: print-rtl-srcs $(RPT_OBJS)
endif

#H# altera-rtl-synth            : Run RTL synthesis with Quartus
altera-rtl-synth: print-rtl-srcs $(RPT_OBJS)

#H# quartus-create-project      : Create the Quartus project
quartus-create-project: $(ALTERA_PROJECT_FILES)
	@rm -rf $(ALTERA_PROJECT_FILES);\
	mkdir -p $(BUILD_DIR);\
	cd $(BUILD_DIR);\
	$(QUARTUS_SH) -t $(ALTERA_CREATE_PROJECT_TCL)

#H# altera-set-pinout           : Set Altera FPGA pinout using the TCL script
altera-set-pinout:
	@mkdir -p $(BUILD_DIR);\
	cd $(BUILD_DIR);\
	$(QUARTUS_SH) -t $(ALTERA_PINOUT_TCL) $(PROJECT)

#H# altera-flash-fpga           : Program the SOF file into the connected Altera FPGA
altera-flash-fpga: altera-scan $(ALTERA_SOF_FILE)
	$(QUARTUS_PGM) -m $(ALTERA_PROGRAM_MODE) -c $(ALTERA_FPGA_CABLE) -o "p;$(ALTERA_SOF_FILE)@1"

#H# altera-connect              : Run USB Blaster connection helper
altera-connect:
	$(ALTERA_CONNECT_USB_BLASTER) continue

#H# altera-scan                 : Scan for connected devices
altera-scan: altera-connect
	$(QUARTUS_PGM) --auto

#H# fpga-rtl-sim                : Run RTL simulation (FPGA test)
fpga-rtl-sim:
	@echo -e "$(_info_)\n[INFO] FPGA Test RTL Simulation\n$(_reset_)";\
	if [[ "$(SIM_TOOL)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined RTL simulation tool!$(_reset_)";\
	else\
		for stool in $(SIM_TOOL);\
		do\
			if [[ "$(FPGA_SIM_MODULES)" == "" ]]; then\
				echo -e "$(_error_)[ERROR] No defined simulation top module!$(_reset_)";\
			else\
				echo -e "$(_info_)[INFO] Simulation with $${stool} tool\n$(_reset_)";\
				for smodule in $(FPGA_SIM_MODULES);\
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

$(ALTERA_SOF_FILE): $(RTL_OBJS)
	@echo -e "$(_info_)\n[INFO] Missing SOF file, generating it...$(_reset_)\n"
	$(MAKE) altera-project

$(RPT_OBJS): $(RTL_OBJS)
	@$(MAKE) quartus-create-project
	@if [[ "$(FPGA_VIRTUAL_PINS)" != "yes" ]]; then\
		$(MAKE) altera-set-pinout;\
	fi
	@cd $(BUILD_DIR);\
	$(QUARTUS_SH) --flow compile $(PROJECT)

ifeq ($(FPGA_USES_CLOCK),yes)
$(ALTERA_PROJECT_FILES): $(ALTERA_PROJECT_SDC) $(ALTERA_CREATE_PROJECT_TCL)
else
$(ALTERA_PROJECT_FILES): $(ALTERA_CREATE_PROJECT_TCL)
endif

$(ALTERA_PROJECT_SDC):
	@mkdir -p $(BUILD_DIR);\
	echo "# Automatically created by the Makefile #" > $(ALTERA_PROJECT_SDC);\
	fpga_clock_src=($(FPGA_CLOCK_SRC));\
	altera_clock_mhz=($(ALTERA_CLOCK_MHZ));\
	for csrc in `seq 0 $$(($${#fpga_clock_src[@]}-1))`;\
	do\
		echo "create_clock -name $${fpga_clock_src[$$csrc]} -period $${altera_clock_mhz[$$csrc]}MHz [get_ports {$${fpga_clock_src[$$csrc]}}]" >> $(ALTERA_PROJECT_SDC);\
	done;\
	echo "derive_clock_uncertainty" >> $(ALTERA_PROJECT_SDC)

$(ALTERA_CREATE_PROJECT_TCL):
	@mkdir -p $(BUILD_DIR);\
	echo "# Automatically created by the Makefile #" > $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set project_name $(PROJECT)" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "if [catch {project_open $(PROJECT)}] {project_new $(PROJECT)}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name VERILOG_MACRO \"__QUARTUS_SYN__\"" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name FAMILY \"$(ALTERA_TARGET)\"" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name DEVICE \"$(ALTERA_DEVICE)\"" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name TOP_LEVEL_ENTITY $(FPGA_TOP_MODULE)" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256" >> $(ALTERA_CREATE_PROJECT_TCL);\
	for spath in $(RTL_PATHS);\
	do\
		echo "set_global_assignment -name SEARCH_PATH $${spath}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	done;\
	for vsrc in $(VERILOG_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${vsrc}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	done;\
	for vheader in $(VERILOG_HEADERS);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${vheader}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	done;\
	for psrc in $(PACKAGE_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${psrc}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	done;\
	for msrc in $(MEM_SRC);\
	do\
		echo "set_global_assignment -name SOURCE_FILE $${msrc}" >> $(ALTERA_CREATE_PROJECT_TCL);\
	done;\
	if [[ "$(FPGA_USES_CLOCK)" == "yes" ]]; then\
		echo "set_global_assignment -name SDC_FILE $(ALTERA_PROJECT_SDC)" >> $(ALTERA_CREATE_PROJECT_TCL);\
	fi;\
	if [[ "$(FPGA_VIRTUAL_PINS)" == "yes" ]]; then\
		cat "$(ALTERA_VIRTUAL_PINS_TCL)" >> $(ALTERA_CREATE_PROJECT_TCL);\
		if [[ "$(FPGA_USES_CLOCK)" == "yes" ]]; then\
			echo "make_all_pins_virtual $(FPGA_CLOCK_SRC)" >> $(ALTERA_CREATE_PROJECT_TCL);\
		fi;\
	fi;\
	echo "project_close" >> $(ALTERA_CREATE_PROJECT_TCL);\
	echo "qexit -success" >> $(ALTERA_CREATE_PROJECT_TCL)

#H# print-rtl-srcs              : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# clean                       : Clean build directory
clean:
	rm -rf build/*

#H# help                        : Display help
help: Makefile
	@echo -e "\nFPGA Test Help - Altera\n"
	@sed -n 's/^#H#//p' $<
	@echo ""

.PHONY: all veritedium altera-project altera-rtl-synth quartus-create-project altera-set-pinout altera-flash-fpga altera-connect altera-scan help
