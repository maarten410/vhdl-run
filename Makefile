
install:	vhdl-run.tcl
	install vhdl-run.tcl /usr/local/bin/vhdl-run
	chmod +x /usr/local/bin/vhdl-run
uninstall:
	rm -f /usr/local/bin/vhdl-run