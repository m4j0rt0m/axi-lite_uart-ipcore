###################################################################
# Description:      RTL Simulation - Makefile                     #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template-simulation   #
###################################################################

SHELL                := /bin/bash
REMOTE-URL-SSH       := git@github.com:m4j0rt0m/rtl-develop-template-simulation.git
REMOTE-URL-HTTPS     := https://github.com/m4j0rt0m/rtl-develop-template-simulation.git

MKFILE_PATH           = $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR               = $(shell dirname $(MKFILE_PATH))

### directories ###
SOURCE_DIR            = $(TOP_DIR)/src
OUTPUT_DIR            = $(TOP_DIR)/build
SCRIPTS_DIR           = $(TOP_DIR)/scripts

### makefile includes ###
include $(SCRIPTS_DIR)/funct.mk

### external sources wildcards ###
EXT_VERILOG_SRC      ?=
EXT_VERILOG_HEADERS  ?=
EXT_PACKAGE_SRC      ?=
EXT_MEM_SRC          ?=
EXT_RTL_PATHS        ?=

### simulation sources directories ###
RTL_DIRS              = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname rtl \)))
INCLUDE_DIRS          = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname include \)))
PACKAGE_DIRS          = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname package \)))
MEM_DIRS              = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname mem \)))

### sources wildcards ###
VERILOG_SRC           = $(EXT_VERILOG_SRC) $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.sv -o -iname \*.vhdl \)))
VERILOG_HEADERS       = $(EXT_VERILOG_HEADERS) $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.svh -o -iname \*.sv -o -iname \*.v \)))
PACKAGE_SRC           = $(EXT_PACKAGE_SRC) $(wildcard $(shell find $(PACKAGE_DIRS) -type f \( -iname \*.sv \)))
MEM_SRC               = $(EXT_MEM_SRC) $(wildcard $(shell find $(MEM_DIRS) -type f \( -iname \*.bin -o -iname \*.hex \)))
RTL_PATHS             = $(EXT_RTL_PATHS) $(RTL_DIRS) $(INCLUDE_DIRS) $(PACKAGE_DIRS) $(MEM_DIRS)

### include flags ###
INCLUDES_FLAGS        = $(addprefix -I, $(RTL_PATHS))

### simulation flags ###
SIM_TOOL             ?= iverilog
SIM_CREATE_VCD       ?= yes
ifeq ($(SIM_CREATE_VCD),yes)
VCD_FLAG              = -D__VCD__
else
VCD_FLAG              =
endif
SIM_OPEN_WAVE        ?= no
SIM_IVERILOG_FLAGS   ?= -o $(BUILD_DIR)/$(SIM_TOP_MODULE).tb -s $(SIM_TOP_MODULE) -g2012 -DSIMULATION $(VCD_FLAG) $(INCLUDES_FLAGS) $(VERILOG_SRC) $(PACKAGE_SRC)
SIM_RUN_VVP          ?= vvp

### simulation objects ###
SIM_TOP_MODULE       ?=
BUILD_DIR             = $(OUTPUT_DIR)/$(SIM_TOP_MODULE)
RTL_OBJS              = $(VERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(MEM_SRC)
VCD_FILE              = $(BUILD_DIR)/$(SIM_TOP_MODULE).vcd
GTK_FILE              = $(SCRIPTS_DIR)/$(SIM_TOP_MODULE).gtkw

all: sim

#H# sim             : Run simulation
sim: clean-top $(VCD_FILE)

#H# veritedium      : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

%.vcd: %.tb $(RTL_OBJS)
	@if [[ "$(SIM_TOOL)" == "iverilog" ]]; then\
		$(SIM_RUN_VVP) $<;\
	fi
	@if [[ "$(SIM_CREATE_VCD)" == "yes" ]]; then\
		mv $(SIM_TOP_MODULE).vcd $(VCD_FILE);\
		if [[ "$(SIM_OPEN_WAVE)" == "yes" ]]; then\
			if [[ -f "$(GTK_FILE)" ]]; then\
				echo -e "$(_info_)\n[INFO] Opening existing GTKW template...$(_reset_)";\
				gtkwave $(GTK_FILE);\
			else\
				gtkwave $(VCD_FILE);\
			fi;\
		fi;\
	fi

%.tb: $(RTL_OBJS)
	$(print-srcs-command)
	@mkdir -p $(BUILD_DIR)
	@if [[ "$(SIM_TOOL)" == "iverilog" ]]; then\
		$(SIM_TOOL) $(SIM_IVERILOG_FLAGS);\
	fi

#H# print-rtl-srcs  : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# clean-top       : Delete Top module's build directory
clean-top:
	rm -rf $(BUILD_DIR)

#H# clean           : Clean build directory
clean:
	rm -rf build/*

#H# help            : Display help
help: Makefile
	@echo -e "\nSimulation Help\n"
	@sed -n 's/^#H#//p' $<
	@echo ""

.PHONY: all sim veritedium clean help
