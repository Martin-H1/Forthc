include ../common.mk

CA65FLAGS    = -D UNROLL -I ../sdk/include
FORTHC_FLAGS = --const CELL_SIZE=2 --const CELL_BITS=16
FORTHC_PATH  = ..\__main__.py
SDK_LIB      = ../sdk/lib/vmachine.lib

all: release

release: obj obj/release bin bin/release \
	bin/release/basic.bin bin/release/basic.srec \
	bin/release/fibonacci.bin bin/release/fibonacci.srec \
	bin/release/hanoi.bin bin/release/hanoi.srec \
	bin/release/mandelbrot.bin bin/release/mandelbrot.srec \
	bin/release/pi.bin bin/release/pi.srec \
	bin/release/pi_machin.bin bin/release/pi_machin.srec

bin/release/%.bin: obj/release/%.o $(SDK_LIB)
	$(LD65) -C ../tests/debug.cfg -o $@ -m bin/release/$*.map $< $(SDK_LIB)

%.s : %.fs
	$(FORTHC) $<

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< \
		-binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) *.s
	-$(RM) bin$(SEP)release$(SEP)*.map
	-$(RM) bin$(SEP)release$(SEP)*.bin
	-$(RM) bin$(SEP)release$(SEP)*.srec
	-$(RM) obj$(SEP)release$(SEP)*.lst
	-$(RM) obj$(SEP)release$(SEP)*.o
	-$(RMDIR) bin$(SEP)release
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)release
	-$(RMDIR) obj
