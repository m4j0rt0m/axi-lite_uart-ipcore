ALTERA_CONNECT_USB_BLASTER  = $(SCRIPTS_DIR)/connect_usb_blaster

#H# altera-connect              : Run USB Blaster connection helper
altera-connect:
	$(ALTERA_CONNECT_USB_BLASTER) continue

#H# altera-scan                 : Scan for connected devices
altera-scan: altera-connect
	$(QUARTUS_PGM) --auto

#H# altera-sof                  : Run the RTL synthesis and generate the SOF file
altera-sof: $(ALTERA_SOF_FILE)

#H# altera-flash-fpga           : Program the SOF file into the connected Altera FPGA
altera-flash-fpga: $(ALTERA_SOF_FILE)
	$(QUARTUS_PGM) -m $(ALTERA_PROGRAM_MODE) -c $(ALTERA_FPGA_CABLE) -o "p;$(ALTERA_SOF_FILE)@1"
