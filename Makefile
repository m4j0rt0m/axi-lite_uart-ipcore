###################################################################
# Description:      RTL Development Main Makefile                 #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template              #
###################################################################

SHELL                  := /bin/bash
REMOTE-URL-SSH         := git@github.com:m4j0rt0m/rtl-develop-template.git
REMOTE-URL-HTTPS       := https://github.com/m4j0rt0m/rtl-develop-template.git

MKFILE_PATH             = $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR                 = $(shell dirname $(MKFILE_PATH))

### directories ###
SOURCE_DIR              = $(TOP_DIR)/src
SYNTHESIS_DIR           = $(TOP_DIR)/synthesis
SIMULATION_DIR          = $(TOP_DIR)/simulation
FPGA_TEST_DIR           = $(TOP_DIR)/fpga
SCRIPTS_DIR             = $(TOP_DIR)/scripts

### external library source directory ###
EXT_LIB_SOURCE_DIR     ?=
ifneq ($(EXT_LIB_SOURCE_DIR),)
EXT_LIB_RTL_DIRS        = $(wildcard $(shell find $(abspath $(EXT_LIB_SOURCE_DIR)) -type d -iname rtl ! -path "*fpga*" ! -path "*simulation*"))
EXT_LIB_INCLUDE_DIRS    = $(wildcard $(shell find $(abspath $(EXT_LIB_SOURCE_DIR)) -type d -iname include ! -path "*fpga*" ! -path "*simulation*"))
EXT_LIB_PACKAGE_DIRS    = $(wildcard $(shell find $(abspath $(EXT_LIB_SOURCE_DIR)) -type d -iname package ! -path "*fpga*" ! -path "*simulation*"))
EXT_LIB_MEM_DIRS        = $(wildcard $(shell find $(abspath $(EXT_LIB_SOURCE_DIR)) -type d -iname mem ! -path "*fpga*" ! -path "*simulation*"))
EXT_LIB_RTL_PATHS       = $(EXT_LIB_RTL_DIRS) $(EXT_LIB_INCLUDE_DIRS) $(EXT_LIB_PACKAGE_DIRS) $(EXT_LIB_MEM_DIRS)
endif

### sources directories ###
RTL_DIRS                = $(EXT_LIB_RTL_DIRS) $(wildcard $(shell find $(SOURCE_DIR) -type d -iname rtl ! -path "*fpga*" ! -path "*simulation*"))
INCLUDE_DIRS            = $(EXT_LIB_INCLUDE_DIRS) $(wildcard $(shell find $(SOURCE_DIR) -type d -iname include ! -path "*fpga*" ! -path "*simulation*"))
PACKAGE_DIRS            = $(EXT_LIB_PACKAGE_DIRS) $(wildcard $(shell find $(SOURCE_DIR) -type d -iname package ! -path "*fpga*" ! -path "*simulation*"))
MEM_DIRS                = $(EXT_LIB_MEM_DIRS) $(wildcard $(shell find $(SOURCE_DIR) -type d -iname mem ! -path "*fpga*" ! -path "*simulation*"))
RTL_PATHS               = $(EXT_LIB_RTL_PATHS) $(RTL_DIRS) $(INCLUDE_DIRS) $(PACKAGE_DIRS) $(MEM_DIRS)
TOP_MODULE_FILE         = $(shell basename $(shell grep -i -w -r "module $(TOP_MODULE)" $(RTL_PATHS) | cut -d ":" -f 1))

### sources wildcards ###
VERILOG_SRC             = $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
VERILOG_HEADERS         = $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh -o -iname \*.sv -o -iname \*.v \)))
PACKAGE_SRC             = $(wildcard $(shell find $(PACKAGE_DIRS) -type f \( -iname \*.sv \)))
MEM_SRC                 = $(wildcard $(shell find $(MEM_DIRS) -type f \( -iname \*.bin -o -iname \*.hex \)))

### makefile includes ###
include $(SCRIPTS_DIR)/config.mk
include $(SCRIPTS_DIR)/misc.mk
include $(SCRIPTS_DIR)/funct.mk

### include flags ###
INCLUDES_FLAGS          = $(addprefix -I, $(RTL_PATHS))

### linter flags ###
VERILATOR_LINT          = verilator
VERILATOR_LINT_SV_FLAGS = +1800-2017ext+sv -sv
VERILATOR_LINT_W_FLAGS  = -Wall -Wno-IMPORTSTAR -Wno-fatal
VERILATOR_CONFIG_FILE   = $(SCRIPT_DIR)/config.vlt
ifeq ("$(wildcard $(VERILATOR_CONFIG_FILE))","")
VERILATOR_CONFIG_FILE   =
endif
SPYGLASS_LINT           = $(SCRIPTS_DIR)/spyglass_lint
SPYGLASS_WAIVER_FILE    = $(SCRIPTS_DIR)/spyglass_waiver.awl
ifeq ("$(wildcard $(SPYGLASS_WAIVER_FILE))","")
SPYGLASS_WAIVER_OPTION  =
else
SPYGLASS_WAIVER_OPTION  = --waiver $(subst $(TOP_DIR)/,,$(SPYGLASS_WAIVER_FILE))
endif
ifeq ("$(RTL_LINTER_ENV_SOURCE)","")
LINTER_ENV_OPTION       =
else
LINTER_ENV_OPTION       = --env-src $(RTL_LINTER_ENV_SOURCE)
endif
ifeq ($(RTL_LINTER_REMOTE),yes)
LINTER_REMOTE_OPTION    = --remote $(RTL_LINTER_REMOTE_IP) --use-env
else
LINTER_REMOTE_OPTION    =
endif
ifeq ($(RTL_LINTER),spyglass)
LINT                    = $(SPYGLASS_LINT)
LINT_FLAGS              = --top $(TOP_MODULE) --files $(subst $(TOP_DIR)/,,$(VERILOG_SRC)) --includes $(subst $(TOP_DIR)/,,$(RTL_PATHS)) --sv --license $(RTL_LINTER_LICENSE) $(LINTER_REMOTE_OPTION) $(LINTER_ENV_OPTION) $(SPYGLASS_WAIVER_OPTION) --move --debug
else
LINT                    = $(VERILATOR_LINT)
LINT_FLAGS              = --lint-only $(VERILATOR_LINT_SV_FLAGS) $(VERILATOR_LINT_W_FLAGS) --quiet-exit --error-limit 200 $(VERILATOR_CONFIG_FILE) $(PACKAGE_SRC) $(INCLUDES_FLAGS) $(TOP_MODULE_FILE)
endif

#H# all                 : Run linter, FPGA synthesis and simulation
all: lint rtl-synth rtl-sim fpga-test

#H# veritedium          : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

#H# lint                : Run the RTL code linter
lint: print-rtl-srcs
	@if [[ "$(TOP_MODULE)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined top module!$(_reset_)";\
	else\
		echo -e "$(_info_)\n[INFO] Linting using $(LINT) tool$(_reset_)";\
		for tmodule in $(TOP_MODULE);\
		do\
			$(MAKE) lint-module TOP_MODULE=$${tmodule};\
		done;\
	fi

lint-module:
	@echo -e "$(_flag_)\n [+] Top Module : [ $(TOP_MODULE) ]\n$(_reset_)";\
	echo "$(RTL_LINTER)";\
	echo -e "$(_flag_) cmd: $(LINT) $(LINT_FLAGS)\n$(_reset_)";\
	$(LINT) $(LINT_FLAGS);\

#H# rtl-synth           : Run RTL synthesis
rtl-synth:
	@echo -e "$(_info_)\n[INFO] RTL Synthesis$(_reset_)";\
	if [[ "$(RTL_SYN_TOOLS)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined RTL synthesis tool! Define \"RTL_SYN_TOOLS\" environment variable or define it in the \"project.config\" file."$(_reset_);\
	else\
		stool_list=($(RTL_SYN_TOOLS));\
		for sidx in `seq 0 $$(($${#stool_list[@]}-1))`;\
		do\
			stool=$${stool_list[$$sidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=synthesis RTL_ENV_SUBFEATURE=$${stool};\
			if [[ "$(TOP_MODULE)" == "" ]]; then\
				echo -e "$(_error_)[ERROR] No defined top module!$(_reset_)";\
			else\
				echo -e "$(_info_)\n[INFO] Running $${stool} synthesis tool$(_reset_)";\
				tmodule_list=($(TOP_MODULE));\
				for tidx in `seq 0 $$(($${#tmodule_list[@]}-1))`;\
				do\
					tmodule=$${tmodule_list[$$tidx]};\
					echo -e "$(_flag_)\n [*] Synthesis Top Module : $${tmodule}\n$(_reset_)";\
					$(MAKE) -C $(SYNTHESIS_DIR)/$${stool} rtl-synth\
						TOP_MODULE=$${tmodule}\
						VERILOG_SRC="$(VERILOG_SRC)"\
						VERILOG_HEADERS="$(VERILOG_HEADERS)"\
						PACKAGE_SRC="$(PACKAGE_SRC)"\
						MEM_SRC="$(MEM_SRC)"\
						RTL_PATHS="$(RTL_PATHS)";\
			  done;\
		  fi;\
		done;\
	fi

#H# rtl-sim             : Run RTL simulation
rtl-sim:
	@echo -e "$(_info_)\n[INFO] RTL Simulation\n$(_reset_)";\
	if [[ "$(SIM_TOOL)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined RTL simulation tool! Define \"SIM_TOOL\" environment variable or define it in the \"project.config\" file.$(_reset_)";\
	else\
		stool_list=($(SIM_TOOL));\
		for sidx in `seq 0 $$(($${#stool_list[@]}-1))`;\
		do\
			stool=$${stool_list[$$sidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=simulation;\
			if [[ "$(SIM_MODULES)" == "" ]]; then\
				echo -e "$(_error_)[ERROR] No defined simulation top module!$(_reset_)";\
			else\
				echo -e "$(_info_)[INFO] Simulation with $${stool} tool\n$(_reset_)";\
				smodule_list=($(SIM_MODULES));\
				for sidx in `seq 0 $$(($${#smodule_list[@]}-1))`;\
				do\
					smodule=$${smodule_list[$$sidx]};\
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

#H# fpga-test           : Run the FPGA test
fpga-test:
	@echo -e "$(_flag_)\n[INFO] FPGA Test$(_reset_)";\
	if [[ "$(FPGA_TEST)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined FPGA test! Define it in the \"project.config\" file.$(_reset_)";\
	else\
		ftest_list=($(FPGA_TEST));\
		for fidx in `seq 0 $$(($${#ftest_list[@]}-1))`;\
		do\
			ftest=$${ftest_list[$$fidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=fpga RTL_ENV_SUBFEATURE=$${ftest};\
			fpga_target=$${ftest^^}_TARGET;\
			fpga_device=$${ftest^^}_DEVICE;\
			echo -e "$(_flag_)\n [*] Running compilation flow - $${ftest^}";\
			echo -e "  |-> Target     : $${!fpga_target}";\
			echo -e "  |-> Device     : $${!fpga_device}";\
			echo -e "  |-> Top Module : $(FPGA_TOP_MODULE)\n$(_reset_)";\
			$(MAKE) -C $(FPGA_TEST_DIR)/$${ftest} $${ftest}-project\
			  EXT_VERILOG_SRC="$(VERILOG_SRC)"\
			  EXT_VERILOG_HEADERS="$(VERILOG_HEADERS)"\
			  EXT_PACKAGE_SRC="$(PACKAGE_SRC)"\
			  EXT_MEM_SRC="$(MEM_SRC)"\
			  EXT_RTL_PATHS="$(RTL_PATHS)";\
		done;\
	fi

#H# fpga-rtl-sim        : Run FPGA Test RTL simulation
fpga-rtl-sim:
	@echo -e "$(_info_)\n[INFO] FPGA Test Simulation\n$(_reset_)";\
	if [[ "$(FPGA_SIM_TEST)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined FPGA test simulation target! Define it in the \"project.config\" file.$(_reset_)";\
	elif [[ "$(FPGA_SIM_TOOL)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined simulation tool for the FPGA test! Define it in the \"project.config\" file.$(_reset_)";\
	else\
		fsim_list=($(FPGA_SIM_TEST));\
		stool_list=($(FPGA_SIM_TOOL));\
		for fidx in `seq 0 $$(($${#fsim_list[@]}-1))`;\
		do\
			fsim=$${fsim_list[$$fidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=fpga RTL_ENV_SUBFEATURE=$${fsim};\
			fsim_modules=FPGA_SIM_MODULES_$${fsim^^};\
			for sidx in `seq 0 $$(($${#stool_list[@]}-1))`;\
			do\
				stool=$${stool_list[$$sidx]};\
				$(MAKE) -C $(FPGA_TEST_DIR)/$${fsim} fpga-rtl-sim\
					FPGA_SIM_MODULES="$${!fsim_modules}"\
					SIM_TOOL="$${stool}"\
					SIM_CREATE_VCD=$(FPGA_SIM_CREATE_VCD)\
					SIM_OPEN_WAVE=$(FPGA_SIM_OPEN_WAVE)\
					EXT_VERILOG_SRC="$(VERILOG_SRC)"\
					EXT_VERILOG_HEADERS="$(VERILOG_HEADERS)"\
					EXT_PACKAGE_SRC="$(PACKAGE_SRC)"\
					EXT_MEM_SRC="$(MEM_SRC)"\
					EXT_RTL_PATHS="$(RTL_PATHS)";\
			done;\
		done;\
	fi

#H# fpga-flash          : Flash FPGA bitstream
fpga-flash:
	@if [[ "$(FPGA_TEST)" == "" ]]; then\
		echo -e "$(_error_)\n[ERROR] No defined FPGA test! Define it in the \"project.config\" file.$(_reset_)";\
	else\
		ftest_list=($(FPGA_TEST));\
		for fidx in `seq 0 $$(($${#ftest_list[@]}-1))`;\
		do\
			ftest=$${ftest_list[$$fidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=fpga RTL_ENV_SUBFEATURE=$${ftest};\
			fpga_target=$${ftest^^}_TARGET;\
			fpga_device=$${ftest^^}_DEVICE;\
			echo -e "$(_flag_)\n [*] Running flash FPGA job - $${ftest^}";\
			echo -e "  |-> Target     : $${!fpga_target}";\
			echo -e "  |-> Device     : $${!fpga_device}";\
			echo -e "  |-> Top Module : $(FPGA_TOP_MODULE)\n$(_reset_)";\
			$(MAKE) -C $(FPGA_TEST_DIR)/$${ftest} $${ftest}-flash-fpga\
			  EXT_VERILOG_SRC="$(VERILOG_SRC)"\
			  EXT_VERILOG_HEADERS="$(VERILOG_HEADERS)"\
			  EXT_PACKAGE_SRC="$(PACKAGE_SRC)"\
			  EXT_MEM_SRC="$(MEM_SRC)"\
			  EXT_RTL_PATHS="$(RTL_PATHS)";\
		done;\
	fi

#H# lint-fpga           : Run the verilator linter for the RTL code used in the FPGA test
lint-fpga-test:
	@if [[ "$(FPGA_TEST)" == "" ]]; then\
		echo -e "$(_error_)[ERROR] No defined FPGA test! Define it in the \"project.config\" file.$(_reset_)";\
	else\
		ftest_list=($(FPGA_TEST));\
		for fidx in `seq 0 $$(($${#ftest_list[@]}-1))`;\
		do\
			ftest=$${ftest_list[$$fidx]};\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=fpga RTL_ENV_SUBFEATURE=$${ftest};\
			echo -e "$(_flag_)\n [*] Running linter for $${ftest^} FPGA test";\
			echo -e "  |-> Top Module : $(FPGA_TOP_MODULE)\n$(_reset_)";\
			$(MAKE) -C $(FPGA_TEST_DIR)/$${ftest} lint\
			  EXT_VERILOG_SRC="$(VERILOG_SRC)"\
			  EXT_VERILOG_HEADERS="$(VERILOG_HEADERS)"\
			  EXT_PACKAGE_SRC="$(PACKAGE_SRC)"\
			  EXT_MEM_SRC="$(MEM_SRC)"\
			  EXT_RTL_PATHS="$(RTL_PATHS)";\
		done;\
	fi

#H# clean               : Clean the build directory
clean: del-bak
	rm -rf build/*

#H# clean-all           : Clean all the build directories
clean-all: clean
	@if [ -d $(SIMULATION_DIR) ]; then $(MAKE) -C $(SIMULATION_DIR) clean; fi
	@syn_tool_list=($(SUPPORTED_SYNTHESIS));\
	for sidx in `seq 0 $$(($${#syn_tool_list[@]}-1))`;\
	do\
		stool=$${syn_tool_list[$$sidx]};\
		if [ -d $(SYNTHESIS_DIR)/$${stool} ]; then $(MAKE) -C $(SYNTHESIS_DIR)/$${stool} clean; fi;\
	done
	@fpga_test_list=($(SUPPORTED_FPGA_TEST));\
	for fidx in `seq 0 $$(($${#fpga_test_list[@]}-1))`;\
	do\
		ftest=$${fpga_test_list[$$fidx]};\
		if [ -d $(FPGA_TEST_DIR)/$${ftest} ]; then $(MAKE) -C $(FPGA_TEST_DIR)/$${ftest} clean; fi;\
		if [ -d $(FPGA_TEST_DIR)/$${ftest}/simulation ]; then $(MAKE) -C $(FPGA_TEST_DIR)/$${ftest}/simulation clean; fi;\
	done

#H# env-dirs            : Create features environment directories (synthesis, fpga-test, simulation, etc.)
env-dirs:
	@if [[ "$(RTL_SYN_TOOLS)" != "" ]]; then\
		for stool in $(RTL_SYN_TOOLS);\
		do\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=synthesis RTL_ENV_SUBFEATURE=$${stool};\
		done;\
	fi
	@if [[ "$(SIM_TOOL)" != "" ]]; then\
		$(MAKE) check-dir-env RTL_ENV_FEATURE=simulation;\
	fi
	@if [[ "$(FPGA_TEST)" != "" ]]; then\
		for ftest in $(FPGA_TEST);\
		do\
			$(MAKE) check-dir-env RTL_ENV_FEATURE=fpga RTL_ENV_SUBFEATURE=$${ftest};\
		done;\
	fi

#H# init-repo           : Initialize repository (submodules)
init-repo:
	@git submodule update --init --recursive

#H# rm-git-db           : Remove GIT databases (.git and .gitmodules)
rm-git-db: init-repo
	$(eval remote-url=$(shell git config --get remote.origin.url))
	@if [[ "$(remote-url)" == "$(REMOTE-URL-SSH)" ]] || [[ "$(remote-url)" == "$(REMOTE-URL-HTTPS)" ]] ; then\
		find ./* -name ".git";\
		find ./* -name ".gitmodules";\
	else\
	  echo -e "$(_error_)\n [ERROR] You are trying to delete your own project GIT database!\n$(_flag_)  >>> $(remote-url)$(_reset_)";\
	fi
#		rm -rf .git .gitmodules;\

#H# help                : Display help
help: Makefile scripts/misc.mk
	@echo -e "\nHelp!...(8)\n"
	@sed -n 's/^#H#//p' $^
	@echo ""

#H# help-all            : Display complete rules help
help-all: help
	@$(MAKE) -C $(SYNTHESIS_DIR)/quartus help
	@$(MAKE) -C $(SYNTHESIS_DIR)/yosys help
	@$(MAKE) -C $(FPGA_TEST_DIR)/altera help
	@$(MAKE) -C $(FPGA_TEST_DIR)/lattice help
	@$(MAKE) -C $(SIMULATION_DIR) help

.PHONY: all lint rtl-synth rtl-sim fpga-test print-rtl-srcs print-config check-config clean clean-all del-bak help help-all
