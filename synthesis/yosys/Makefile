###################################################################
# Description:      RTL Synthesis with Yosys - Makefile           #
#                                                                 #
# Template written by Abraham J. Ruiz R.                          #
#   https://github.com/m4j0rt0m/rtl-develop-template-syn-yosys    #
###################################################################

SHELL                := /bin/bash
REMOTE-URL-SSH       := git@github.com:m4j0rt0m/rtl-develop-template-synthesis-yosys.git
REMOTE-URL-HTTPS     := https://github.com/m4j0rt0m/rtl-develop-template-synthesis-yosys.git

MKFILE_PATH          := $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR              := $(shell dirname $(MKFILE_PATH))

### directories ###
OUTPUT_DIR            = $(TOP_DIR)/build
SCRIPTS_DIR           = $(TOP_DIR)/scripts

### makefile includes ###
include $(SCRIPTS_DIR)/funct.mk
include $(SCRIPTS_DIR)/default.mk

### project configuration ###
PROJECT              ?=
TOP_MODULE           ?=
RTL_SYN_CLK_SRC      ?=

### sources wildcards ###
VERILOG_SRC          ?=
VERILOG_HEADERS      ?=
PACKAGE_SRC          ?=
MEM_SRC              ?=
RTL_PATHS            ?=

### synthesis configuration ###
RTL_SYN_Y_TARGET     := $(or $(RTL_SYN_Y_TARGET),$(DEFAULT_RTL_SYN_Y_TARGET))
RTL_SYN_Y_DEVICE     := $(or $(RTL_SYN_Y_DEVICE),$(DEFAULT_RTL_SYN_Y_DEVICE))
RTL_SYN_Y_CLK_MHZ    := $(or $(RTL_SYN_Y_CLK_MHZ),$(DEFAULT_RTL_SYN_Y_CLK_MHZ))
RTL_SYN_Y_PNR_TOOL   := $(or $(RTL_SYN_Y_PNR_TOOL),$(DEFAULT_RTL_SYN_Y_PNR_TOOL))

### synthesis objects ###
SYN_DIR               = $(OUTPUT_DIR)/$(TOP_MODULE)
RTL_OBJS              = $(VERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(MEM_SRC)
RPT_OBJ               = $(SYN_DIR)/$(PROJECT).rpt
CLOCKS_CONST          = $(SYN_DIR)/$(PROJECT).clocks.py

### yosys synthesis cli flags ###
YOSYS_SYN             = yosys
YOSYS_SYN_INC_FLAGS   = $(addprefix -I, $(RTL_PATHS))
ifeq ($(RTL_SYN_Y_PNR_TOOL),nextpnr)
YOSYS_SYN_FLAGS       = -p "read_verilog -sv -formal $(YOSYS_SYN_INC_FLAGS) $(VERILOG_SRC) $(PACKAGE_SRC); synth_$(RTL_SYN_Y_TARGET) -top $(TOP_MODULE) -json $@"
YOSYS_PNR             = nextpnr-ice40
ifeq ($(RTL_SYN_USES_CLK),yes)
YOSYS_PNR_FLAGS       = --$(RTL_SYN_Y_DEVICE) --json $(filter %.json, $^) --asc $@ --pre-pack $(filter %.clocks.py, $^)
else
YOSYS_PNR_FLAGS       = --$(RTL_SYN_Y_DEVICE) --json $(filter %.json, $^) --asc $@
endif
else
YOSYS_SYN_FLAGS       = -p "read_verilog -sv -formal $(YOSYS_SYN_INC_FLAGS) $(VERILOG_SRC) $(PACKAGE_SRC); synth_$(RTL_SYN_Y_TARGET) -top $(TOP_MODULE) -blif $@"
YOSYS_PNR             = arachne-pnr
YOSYS_PNR_FLAGS       = $< -d $(subst up,,$(subst hx,,$(subst lp,,$(RTL_SYN_Y_DEVICE)))) -o $@
endif
YOSYS_TIME_STA        = icetime
ifeq ($(RTL_SYN_USES_CLK),yes)
YOSYS_TIME_STA_FLAGS  = -tmd $(RTL_SYN_Y_DEVICE) $(addprefix -c ,$(RTL_SYN_Y_CLK_MHZ)) -o $(SYN_DIR)/$(TOP_MODULE).v -r $@ $<
else
YOSYS_TIME_STA_FLAGS  = -tmd $(RTL_SYN_Y_DEVICE) -o $(SYN_DIR)/$(TOP_MODULE).v -r $@ $<
endif
#WIP...
#YOSYS_SYN_SHOW_FLAGS  = -stretch -width -prefix $(SYN_DIR)/$(TOP_MODULE) -format png

all: rtl-synth

#H# rtl-synth       : Run RTL synthesis with Yosys
rtl-synth: print-rtl-srcs $(RPT_OBJ)

#H# veritedium      : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

%.blif %.json: $(RTL_OBJS)
	@mkdir -p $(SYN_DIR)
	@echo -e '\n$(_flag_) cmd: ${YOSYS_SYN} ${YOSYS_SYN_FLAGS}$(_reset_)\n'
	@$(YOSYS_SYN) $(YOSYS_SYN_FLAGS)

ifeq ($(RTL_SYN_Y_PNR_TOOL),nextpnr)
ifeq ($(RTL_SYN_USES_CLK),yes)
%.asc: %.json %.clocks.py
else
%.asc: %.json
endif
else
%.asc: %.blif
endif
	@echo -e '\n$(_flag_) cmd: ${YOSYS_PNR} ${YOSYS_PNR_FLAGS}$(_reset_)\n'
	$(YOSYS_PNR) $(YOSYS_PNR_FLAGS);\

%.clocks.py:
	@mkdir -p $(SYN_DIR);\
	echo -e "\n$(_info_) Creating clock constraints...\n";\
	echo "# Automatically created by the Makefile #" | tee $(CLOCKS_CONST);\
	rtl_syn_clock_src=($(RTL_SYN_CLK_SRC));\
	rtl_syn_clock_mhz=($(RTL_SYN_Y_CLK_MHZ));\
	for csrc in `seq 0 $$(($${#rtl_syn_clock_src[@]}-1))`;\
	do\
		echo "ctx.addClock(\"$${rtl_syn_clock_src[$$csrc]}\",$${rtl_syn_clock_mhz[$$csrc]})" | tee -a $(CLOCKS_CONST);\
	done

%.rpt: %.asc
	@echo -e '\n$(_flag_) cmd: ${YOSYS_TIME_STA} ${YOSYS_TIME_STA_FLAGS}$(_reset_)\n';\
	$(YOSYS_TIME_STA) $(YOSYS_TIME_STA_FLAGS)

#H# print-rtl-srcs  : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# clean           : Remove build directory
clean:
	rm -rf build/*

#H# help            : Display help
help: Makefile
	@echo -e "\nRTL Synthesis Help - Yosys\n"
	@sed -n 's/^#H#//p' $<
	@echo ""

.PHONY: all rtl-synth veritedium print-rtl-srcs clean help
