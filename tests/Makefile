include ../common.mk

CA65FLAGS = -D UNROLL -I ../targets/65816

FORTHC_FLAGS = --const CELL_SIZE=2 --const CELL_BITS=16

FORTHC_PATH = ..\__main__.py

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
	bin/debug/stack.bin bin/debug/string.srec

../targets/65816/pictured.s: ../targets/65816/pictured.fs
	$(FORTHC) $<

obj/debug/pictured.o: ../targets/65816/pictured.s
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/debug/pictured.lst -o $@

../targets/65816/core.s: ../targets/65816/core.fs
	$(FORTHC) $<

obj/debug/core.o: ../targets/65816/core.s
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/debug/pictured.lst -o $@

obj/debug/vmachine.o: ../targets/65816/vmachine.s
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l $*.lst -o $@

bin/debug/control.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/control.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/control.bin -m bin/debug/control.map $^

bin/debug/const-expr.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/pictured.o obj/debug/const-expr.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/const-expr.bin -m bin/debug/const-expr.map $^

bin/debug/core-test.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/pictured.o obj/debug/core-test.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/core-test.bin -m bin/debug/core-test.map $^

bin/debug/double.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/double.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/double.bin -m bin/debug/double.map $^

bin/debug/inline-test.bin: obj/debug/vmachine.o obj/debug/inline-test.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/inline-test.bin -m bin/debug/inline-test.map $^

bin/debug/logic.bin: obj/debug/vmachine.o obj/debug/logic.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/logic.bin -m bin/debug/logic.map $^

bin/debug/math.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/math.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/math.bin -m bin/debug/math.map $^

bin/debug/memory.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/memory.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/memory.bin -m bin/debug/memory.map $^

bin/debug/module.bin: obj/debug/vmachine.o obj/debug/module.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/module.bin -m bin/debug/module.map $^

bin/debug/output.bin: obj/debug/vmachine.o obj/debug/pictured.o obj/debug/core.o obj/debug/output.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/output.bin -m bin/debug/output.map $^

bin/debug/stack.bin: obj/debug/vmachine.o obj/debug/core.o obj/debug/stack.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/stack.bin -m bin/debug/stack.map $^

bin/debug/string.bin: obj/debug/vmachine.o obj/debug/string.o
	$(LD65) -C ../targets/65816/debug.cfg -o bin/debug/string.bin -m bin/debug/string.map $^

%.s : %.fs
	$(FORTHC) $<

%.srec : %.bin
	$(SREC_CAT) -address-length=3 -execution_start_address 0x004000 $< -binary -offset 0x4000 -O -Motorola -DISable Header > $@

clean:
	-$(RM) *.s
	-$(RM) module.inc
	-$(RM) ..$(SEP)targets$(SEP)65816$(SEP)core.inc
	-$(RM) ..$(SEP)targets$(SEP)65816$(SEP)core.s
	-$(RM) ..$(SEP)targets$(SEP)65816$(SEP)pictured.inc
	-$(RM) ..$(SEP)targets$(SEP)65816$(SEP)pictured.s
	-$(RM) bin$(SEP)debug$(SEP)*.map
	-$(RM) bin$(SEP)debug$(SEP)*.bin
	-$(RM) bin$(SEP)debug$(SEP)*.srec
	-$(RM) obj$(SEP)debug$(SEP)*.lst
	-$(RM) obj$(SEP)debug$(SEP)*.o
	-$(RMDIR) bin$(SEP)debug
	-$(RMDIR) bin
	-$(RMDIR) obj$(SEP)debug
	-$(RMDIR) obj
