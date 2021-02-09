### function define: veritedium AUTO directive ###
define veritedium-command
emacs --batch $(1) -f verilog-auto -f save-buffer;
endef

### function define: print sources ###
define print-srcs-command
	@echo -e "$(_info_)\n[INFO] RTL Source Files$(_reset_)";\
	echo -e "$(_segment_)"
	@echo " [+] Verilog Source Files: $(words $(VERILOG_SRC))";\
	for vsrc in $(VERILOG_SRC);\
	do\
		echo "  |-> $${vsrc}";\
	done
	@echo " [+] Verilog Headers Files: $(words $(VERILOG_HEADERS))";\
	for vheader in $(VERILOG_HEADERS);\
	do\
		echo "  |-> $${vheader}";\
	done
	@echo " [+] Packages Source Files: $(words $(PACKAGE_SRC))";\
	for psrc in $(PACKAGES_SRC);\
	do\
		echo "  |-> $${psrc}";\
	done
	@echo " [+] Memory Source Files: $(words $(MEM_SRC))";\
	for msrc in $(MEM_SRC);\
	do\
		echo "  |-> $${msrc}";\
	done;\
	echo -e "$(_reset_)"
endef
