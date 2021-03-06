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

H_VER = 3_1_2
PROJ = loctag_$(H_VER)_firmware

PIN_DEF = pins_$(H_VER).pcf
DEVICE = up5k
PKG = sg48
SEED ?= 20210106

all: $(PROJ).bin

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

$(PROJ).bin: bootloader.bin loctag_test.bin
	icemulti -v -o $(PROJ).bin -a16 -p0 bootloader.bin loctag_test.bin

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

%_syn.v: %.json
	yosys -p 'read_json -wideports $^; write_verilog $@'

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f *.asc *.rpt *.bin *.log bootloader.json loctag_test.json 

.SECONDARY:
.PHONY: all prog clean
