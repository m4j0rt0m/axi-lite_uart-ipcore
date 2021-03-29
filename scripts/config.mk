### configuration input ###
CONFIG_FILE                = $(TOP_DIR)/project.config
PARSE_CONFIG               = $(SCRIPTS_DIR)/parse_config $(CONFIG_FILE)

### project configuration ###
PROJECT                   ?= $(shell $(PARSE_CONFIG) project)
TOP_MODULE                ?= $(shell $(PARSE_CONFIG) rtl_top)
# - project-features
RTL_LINTER                ?= $(shell $(PARSE_CONFIG) rtl_linter)
RTL_SYN_TOOLS             ?= $(shell $(PARSE_CONFIG) rtl_synth_tools)
SIM_TOOL                  ?= $(shell $(PARSE_CONFIG) sim_tool)
FPGA_TEST                 ?= $(shell $(PARSE_CONFIG) fpga_test)
FPGA_SIM_TEST             ?= $(shell $(PARSE_CONFIG) fpga_sim_test)
FPGA_SIM_TOOL             ?= $(shell $(PARSE_CONFIG) fpga_sim_tool)
# - rtl-lint
RTL_LINTER_LICENSE        ?= $(shell $(PARSE_CONFIG) rtl_linter_license)
RTL_LINTER_REMOTE         ?= $(shell $(PARSE_CONFIG) rtl_linter_remote)
RTL_LINTER_REMOTE_IP      ?= $(shell $(PARSE_CONFIG) rtl_linter_remote_ip)
RTL_LINTER_ENV_SOURCE     ?= $(shell $(PARSE_CONFIG) rtl_linter_env_source)
# - rtl-synthesis
RTL_SYN_USES_CLK          ?= $(shell $(PARSE_CONFIG) rtl_synth_uses_clk)
RTL_SYN_CLK_SRC           ?= $(shell $(PARSE_CONFIG) rtl_synth_clk_src)
# - rtl-synthesis-quartus
RTL_SYN_Q_TARGET          ?= $(shell $(PARSE_CONFIG) rtl_synth_quartus_target)
RTL_SYN_Q_DEVICE          ?= $(shell $(PARSE_CONFIG) rtl_synth_quartus_device)
RTL_SYN_Q_CLK_MHZ         ?= $(shell $(PARSE_CONFIG) rtl_synth_quartus_clk_mhz)
# - rtl-synthesis-yosys
RTL_SYN_Y_TARGET          ?= $(shell $(PARSE_CONFIG) rtl_synth_yosys_target)
RTL_SYN_Y_DEVICE          ?= $(shell $(PARSE_CONFIG) rtl_synth_yosys_device)
RTL_SYN_Y_CLK_MHZ         ?= $(shell $(PARSE_CONFIG) rtl_synth_yosys_clk_mhz)
RTL_SYN_Y_PNR_TOOL        ?= $(shell $(PARSE_CONFIG) rtl_synth_yosys_pnr_tool)
# - sim
SIM_MODULES               ?= $(shell $(PARSE_CONFIG) sim_modules)
SIM_CREATE_VCD            ?= $(shell $(PARSE_CONFIG) sim_create_vcd)
SIM_OPEN_WAVE             ?= $(shell $(PARSE_CONFIG) sim_open_wave)
# - fpga-test
FPGA_TOP_MODULE           ?= $(shell $(PARSE_CONFIG) fpga_top)
FPGA_VIRTUAL_PINS         ?= $(shell $(PARSE_CONFIG) fpga_virtual_pins)
FPGA_BOARD_TEST           ?= $(shell $(PARSE_CONFIG) fpga_board_test)
FPGA_USES_CLOCK           ?= $(shell $(PARSE_CONFIG) fpga_uses_clk)
FPGA_CLOCK_SRC            ?= $(shell $(PARSE_CONFIG) fpga_clk_src)
# - fpga-test-altera
ALTERA_TARGET             ?= $(shell $(PARSE_CONFIG) fpga_altera_target)
ALTERA_DEVICE             ?= $(shell $(PARSE_CONFIG) fpga_altera_device)
ALTERA_PACKAGE            ?= $(shell $(PARSE_CONFIG) fpga_altera_package)
ALTERA_MIN_TEMP           ?= $(shell $(PARSE_CONFIG) fpga_altera_min_temp)
ALTERA_MAX_TEMP           ?= $(shell $(PARSE_CONFIG) fpga_altera_max_temp)
ALTERA_CLOCK_MHZ          ?= $(shell $(PARSE_CONFIG) fpga_altera_clk_mhz)
# - fpga-test-lattice
LATTICE_TARGET            ?= $(shell $(PARSE_CONFIG) fpga_lattice_target)
LATTICE_DEVICE            ?= $(shell $(PARSE_CONFIG) fpga_lattice_device)
LATTICE_PACKAGE           ?= $(shell $(PARSE_CONFIG) fpga_lattice_package)
LATTICE_CLOCK_MHZ         ?= $(shell $(PARSE_CONFIG) fpga_lattice_clk_mhz)
LATTICE_PNR_TOOL          ?= $(shell $(PARSE_CONFIG) fpga_lattice_pnr_tool)
# - fpga-rtl-sim
FPGA_SIM_INC_MAIN_SIM_DIR ?= $(shell $(PARSE_CONFIG) fpga_sim_inc_main_sim_dir)
FPGA_SIM_CREATE_VCD       ?= $(shell $(PARSE_CONFIG) fpga_sim_create_vcd)
FPGA_SIM_OPEN_WAVE        ?= $(shell $(PARSE_CONFIG) fpga_sim_open_wave)
# - fpga-rtl-sim-altera
FPGA_SIM_MODULES_ALTERA   ?= $(shell $(PARSE_CONFIG) fpga_sim_modules_altera)
# - fpga-rtl-sim-altera
FPGA_SIM_MODULES_LATTICE  ?= $(shell $(PARSE_CONFIG) fpga_sim_modules_lattice)

### export variables ###
export CONFIG_FILE
export PROJECT
export RTL_LINTER
export RTL_LINTER_LICENSE
export RTL_LINTER_REMOTE
export RTL_LINTER_REMOTE_IP
export RTL_LINTER_ENV_SOURCE
export RTL_SYN_USES_CLK
export RTL_SYN_CLK_SRC
export RTL_SYN_Q_TARGET
export RTL_SYN_Q_DEVICE
export RTL_SYN_Q_CLK_MHZ
export RTL_SYN_Y_TARGET
export RTL_SYN_Y_DEVICE
export RTL_SYN_Y_CLK_MHZ
export RTL_SYN_Y_PNR_TOOL
export FPGA_TOP_MODULE
export FPGA_VIRTUAL_PINS
export FPGA_BOARD_TEST
export FPGA_USES_CLOCK
export FPGA_CLOCK_SRC
export ALTERA_TARGET
export ALTERA_DEVICE
export ALTERA_PACKAGE
export ALTERA_MIN_TEMP
export ALTERA_MAX_TEMP
export ALTERA_CLOCK_MHZ
export LATTICE_TARGET
export LATTICE_DEVICE
export LATTICE_PACKAGE
export LATTICE_CLOCK_MHZ
export LATTICE_PNR_TOOL
export FPGA_SIM_MODULES_ALTERA
export FPGA_SIM_MODULES_LATTICE

#H# check-config        : Check project configuration
check-config:
	@echo "TODO: Project configuration checker rule"

### supported stuff flags ###
SUPPORTED_SYNTHESIS  = quartus yosys
SUPPORTED_FPGA_TEST  = altera lattice
SUPPORTED_SIMULATION = iverilog spyglass
