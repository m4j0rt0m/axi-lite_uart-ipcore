### display colours ###
_CBLUE=\033[0;34m
_CRED=\033[0;31m
_CWHITE=\033[0;37m
_COCHRE=\033[38;5;95m
_CYELLOW=\033[0;33m
_CBOLD=\033[1m
_reset_=\033[0m
_info_=$(_CBLUE)$(_CBOLD)
_flag_=$(_CYELLOW)
_error_=$(_CRED)
_segment_=$(_COCHRE)

### export variables ###
export _reset_
export _info_
export _flag_
export _error_
export _segment_

#H# print-config        : Display project configuration
print-config: check-config
	@echo -e "$(_info_)\n[INFO] Project Configuration File$(_reset_)";\
	echo -e "$(_segment_)";\
	echo -e " [+] Project";\
	echo -e "  |-> Project                    : $(PROJECT)";\
	echo -e "  |-> RTL Top                    : $(TOP_MODULE)";\
	echo -e " [+] RTL Synthesis";\
	echo -e "  |-> RTL Synthesis Tools        : $(RTL_SYN_TOOLS)";\
	echo -e "  |-> RTL Synthesis Clock        : $(RTL_SYN_CLK_SRC)";\
	for stool in $(RTL_SYN_TOOLS);\
	do\
		if [[ "$${stool}" == "quartus" ]]; then\
			echo -e "  |-> [+] Quartus Synthesis";\
			echo -e "  |    |-> Target                : $(RTL_SYN_Q_TARGET)";\
			echo -e "  |    |-> Device                : $(RTL_SYN_Q_DEVICE)";\
			echo -e "  |    |-> Clock Period (ns)     : $(RTL_SYN_Q_CLK_PERIOD)";\
		elif [[ "$${stool}" == "yosys" ]]; then\
			echo -e "  |-> [+] Yosys Synthesis";\
			echo -e "  |    |-> Target                : $(RTL_SYN_Y_TARGET)";\
			echo -e "  |    |-> Device                : $(RTL_SYN_Y_DEVICE)";\
			echo -e "  |    |-> Clock (MHz)           : $(RTL_SYN_Y_CLK_MHZ)";\
		fi;\
	done;\
	echo " [+] Simulation";\
	echo "  |-> Sim Top(s)                 : $(SIM_MODULES)";\
	echo "  |-> Sim Tool                   : $(SIM_TOOL)";\
	echo " [+] FPGA Test";\
	echo "  |-> FPGA Top                   : $(FPGA_TOP_MODULE)";\
	echo "  |-> FPGA Use Virtual Pins      : $(FPGA_VIRTUAL_PINS)";\
	echo "  |-> FPGA Board Test            : $(FPGA_BOARD_TEST)";\
	echo "  |-> FPGA Clock Source          : $(FPGA_CLOCK_SRC)";\
	echo "  |-> [+] Test with Altera FPGA  : $(FPGA_SYNTH_ALTERA)";\
	if [[ "$(FPGA_SYNTH_ALTERA)" == "yes" ]]; then\
		echo "  |    |-> Target                : $(ALTERA_TARGET)";\
		echo "  |    |-> Device                : $(ALTERA_DEVICE)";\
		echo "  |    |-> Package               : $(ALTERA_PACKAGE)";\
		echo "  |    |-> Min Temp              : $(ALTERA_MIN_TEMP)";\
		echo "  |    |-> Max Temp              : $(ALTERA_MAX_TEMP)";\
		if [[ "$(FPGA_CLOCK_SRC)" != "" ]]; then\
			echo "  |    |-> Clock Period          : $(ALTERA_CLOCK_PERIOD)";\
		fi;\
		if [[ "$(FPGA_VIRTUAL_PINS)" != "yes" ]]; then\
			echo "  |    |-> Pinout TCL            : $(FPGA_TEST_DIR)/altera/script/$(FPGA_TOP_MODULE)_set_pinout.tcl";\
		fi;\
	fi;\
	echo "  |-> [+] Test with Lattice FPGA : $(FPGA_SYNTH_LATTICE)";\
	if [[ "$(FPGA_SYNTH_LATTICE)" == "yes" ]]; then\
		echo "  |    |-> Device                : $(LATTICE_DEVICE)";\
		echo "  |    |-> Package               : $(LATTICE_PACKAGE)";\
		if [[ "$(FPGA_CLOCK_SRC)" != "" ]]; then\
			echo "  |    |-> Clock Frequency       : $(LATTICE_CLOCK_MHZ)";\
		fi;\
		if [[ $(FPGA_VIRTUAL_PINS) != "yes" ]]; then\
			echo "  |    |-> Pinout PCF            : $(FPGA_TEST_DIR)/lattice/script/$(FPGA_TOP_MODULE)_set_pinout.pcf";\
		fi;\
	fi;\
	echo -e "$(_reset_)"

#H# print-rtl-srcs      : Print RTL sources
print-rtl-srcs:
	$(call print-srcs-command)

#H# del-bak             : Delete backup files
del-bak:
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
