include ../common.mk

CA65FLAGS   = -D UNROLL -I ../sdk/include
FORTHC_FLAGS = --const CELL_SIZE=2 --const CELL_BITS=16
FORTHC_PATH  = ..\__main__.py
SDK_LIB      = ../sdk/lib/vmachine.lib

all: release

release: obj obj/release bin bin/release \
	bin/release/accept-test.bin bin/release/accept-test.srec \
	bin/release/bignum-test.bin bin/release/bignum-test.srec \
	bin/release/control.bin bin/release/control.srec \
	bin/release/const-expr.bin bin/release/const-expr.srec \
	bin/release/core-test.bin bin/release/core-test.srec \
	bin/release/double.bin bin/release/double.srec \
	bin/release/inline-test.bin bin/release/inline-test.srec \
	bin/release/logic.bin bin/release/logic.srec \
	bin/release/math.bin bin/release/math.srec \
	bin/release/memory.bin bin/release/memory.srec \
	bin/release/module.bin bin/release/module.srec \
	bin/release/output.bin bin/release/output.srec \
	bin/release/stack.bin bin/release/stack.srec \
	bin/release/string.bin bin/release/string.srec

# All bins now link against SDK library instead of individual .o files
bin/release/accept-test.bin: obj/release/accept-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/accept-test.map \
		obj/release/accept-test.o $(SDK_LIB)

bin/release/bignum-test.bin: obj/release/bignum-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/bignum-test.map \
		obj/release/bignum-test.o $(SDK_LIB)

bin/release/control.bin: obj/release/control.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/control.map \
		obj/release/control.o $(SDK_LIB)

bin/release/const-expr.bin: obj/release/const-expr.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/const-expr.map \
		obj/release/const-expr.o $(SDK_LIB)

bin/release/core-test.bin: obj/release/core-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/core-test.map \
		obj/release/core-test.o $(SDK_LIB)

bin/release/double.bin: obj/release/double.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/double.map \
		obj/release/double.o $(SDK_LIB)

bin/release/inline-test.bin: obj/release/inline-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/inline-test.map \
		obj/release/inline-test.o $(SDK_LIB)

bin/release/logic.bin: obj/release/logic.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/logic.map \
		obj/release/logic.o $(SDK_LIB)

bin/release/math.bin: obj/release/math.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/math.map \
		obj/release/math.o $(SDK_LIB)

bin/release/memory.bin: obj/release/memory.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/memory.map \
		obj/release/memory.o $(SDK_LIB)

bin/release/module.bin: obj/release/module.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/module.map \
		obj/release/module.o $(SDK_LIB)

bin/release/output.bin: obj/release/output.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/output.map \
		obj/release/output.o $(SDK_LIB)

bin/release/stack.bin: obj/release/stack.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/stack.map \
		obj/release/stack.o $(SDK_LIB)

bin/release/string.bin: obj/release/string.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/release/string.map \
		obj/release/string.o $(SDK_LIB)

%.s : %.fs
	$(FORTHC) $<

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< \
		-binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) *.s *.inc
	-$(RM) bin$(SEP)release$(SEP)*.map
	-$(RM) bin$(SEP)release$(SEP)*.bin
	-$(RM) bin$(SEP)release$(SEP)*.srec
	-$(RM) obj$(SEP)release$(SEP)*.lst
	-$(RM) obj$(SEP)release$(SEP)*.o
	-$(RMDIR) bin$(SEP)release
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)release
	-$(RMDIR) obj
