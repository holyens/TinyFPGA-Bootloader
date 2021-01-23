# Makefile borrowed from https://github.com/cliffordwolf/icestorm/blob/master/examples/icestick/Makefile
#
# The following license is from the icestorm project and specifically applies to this file only:
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

PROJ = factory_bootloader

PIN_DEF = pins.pcf
DEVICE = up5k
PKG = sg48
SEED ?= 20210106

all: factory_bootloader.bin

%.json: %.v ../../common/*.v 
	yosys -q -p 'synth_ice40 -top $(basename $@) -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 \
		--seed $(SEED) \
		--$(DEVICE) \
		--package $(PKG) \
		--json $(basename $@).json \
		--pcf $(PIN_DEF) \
		--asc $@ \

%.bin: %.asc
	icepack $< $@

factory_bootloader.bin: bootloader.bin hardware_test.bin
	icemulti -v -o factory_bootloader.bin -a16 -p0 bootloader.bin hardware_test.bin

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_syn.v: %.json
	yosys -p 'read_json -wideports $^; write_verilog $@'

prog: factory_bootloader.bin
	iceprog $<

sudo-prog: factory_bootloader.bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f *.asc *.rpt *.bin *.log bootloader.json hardware_test.json 

.SECONDARY:
.PHONY: all prog clean
