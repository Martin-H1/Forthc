include ../common.mk

CA65FLAGS   = -D UNROLL -I ../sdk/include
FORTHC_FLAGS = --const CELL_SIZE=2 --const CELL_BITS=16
FORTHC_PATH  = ..\__main__.py
SDK_LIB      = ../sdk/lib/vmachine.lib

all: debug

debug: obj obj/debug bin bin/debug \
	bin/debug/control.bin bin/debug/control.srec \
	bin/debug/const-expr.bin bin/debug/const-expr.srec \
	bin/debug/core-test.bin bin/debug/core-test.srec \
	bin/debug/double.bin bin/debug/double.srec \
	bin/debug/inline-test.bin bin/debug/inline-test.srec \
	bin/debug/logic.bin bin/debug/logic.srec \
	bin/debug/math.bin bin/debug/math.srec \
	bin/debug/memory.bin bin/debug/memory.srec \
	bin/debug/module.bin bin/debug/module.srec \
	bin/debug/output.bin bin/debug/output.srec \
	bin/debug/stack.bin bin/debug/stack.srec \
	bin/debug/string.bin bin/debug/string.srec

# All bins now link against SDK library instead of individual .o files
bin/debug/control.bin: obj/debug/control.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/control.map \
		obj/debug/control.o $(SDK_LIB)

bin/debug/const-expr.bin: obj/debug/const-expr.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/const-expr.map \
		obj/debug/const-expr.o $(SDK_LIB)

bin/debug/core-test.bin: obj/debug/core-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/core-test.map \
		obj/debug/core-test.o $(SDK_LIB)

bin/debug/double.bin: obj/debug/double.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/double.map \
		obj/debug/double.o $(SDK_LIB)

bin/debug/inline-test.bin: obj/debug/inline-test.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/inline-test.map \
		obj/debug/inline-test.o $(SDK_LIB)

bin/debug/logic.bin: obj/debug/logic.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/logic.map \
		obj/debug/logic.o $(SDK_LIB)

bin/debug/math.bin: obj/debug/math.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/math.map \
		obj/debug/math.o $(SDK_LIB)

bin/debug/memory.bin: obj/debug/memory.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/memory.map \
		obj/debug/memory.o $(SDK_LIB)

bin/debug/module.bin: obj/debug/module.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/module.map \
		obj/debug/module.o $(SDK_LIB)

bin/debug/output.bin: obj/debug/output.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/output.map \
		obj/debug/output.o $(SDK_LIB)

bin/debug/stack.bin: obj/debug/stack.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/stack.map \
		obj/debug/stack.o $(SDK_LIB)

bin/debug/string.bin: obj/debug/string.o $(SDK_LIB)
	$(LD65) -C debug.cfg -o $@ -m bin/debug/string.map \
		obj/debug/string.o $(SDK_LIB)

%.s : %.fs
	$(FORTHC) $<

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< \
		-binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) *.s *.inc
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)debug$(SEP)*.srec
	-$(RM) obj$(SEP)debug$(SEP)*.lst
	-$(RM) obj$(SEP)debug$(SEP)*.o
	-$(RMDIR) bin$(SEP)debug
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)debug
	-$(RMDIR) obj
