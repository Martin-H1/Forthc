include ../../common.mk

CA65FLAGS   = -D UNROLL -I .
FORTHC_FLAGS = --const CELL_SIZE=2 --const CELL_BITS=16
FORTHC_PATH  = ..\..\__main__.py
SDK_INC      = ..\..\sdk\include
SDK_LIB      = ..\..\sdk\lib
AR65         = "%HOMEPATH%\cc65-snapshot-win32\bin\ar65.exe"

all: sdk

sdk: $(SDK_INC) $(SDK_LIB) \
     $(SDK_INC)/vmachine.inc \
     $(SDK_INC)/core.inc \
     $(SDK_INC)/pictured.inc \
     $(SDK_LIB)/vmachine.lib

# Create SDK directories
$(SDK_INC):
	mkdir $(SDK_INC)

$(SDK_LIB):
	mkdir $(SDK_LIB)

# Copy vmachine.inc to SDK include
$(SDK_INC)/vmachine.inc: vmachine.inc
	copy vmachine.inc $(SDK_INC)$(SEP)vmachine.inc

# Compile core.fs -> core.s + core.inc
core.s core.inc: core.fs
	$(FORTHC) core.fs

# Copy core.inc to SDK include
$(SDK_INC)/core.inc: core.inc
	copy core.inc $(SDK_INC)$(SEP)core.inc

# Compile pictured.fs -> pictured.s + pictured.inc
pictured.s pictured.inc: pictured.fs
	$(FORTHC) pictured.fs

# Copy pictured.inc to SDK include
$(SDK_INC)/pictured.inc: pictured.inc
	copy pictured.inc $(SDK_INC)$(SEP)pictured.inc

# Assemble object files
obj/vmachine.o: vmachine.s obj
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/vmachine.lst -o $@

obj/core.o: core.s obj
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/core.lst -o $@

obj/pictured.o: pictured.s obj
	$(CA65) --cpu 65816 $(CA65FLAGS) $< -l obj/pictured.lst -o $@

# Archive into vmachine.lib
$(SDK_LIB)/vmachine.lib: obj/vmachine.o obj/core.o obj/pictured.o
	$(AR65) a $@ $^

obj:
	mkdir obj

clean:
	-$(RM) core.s core.inc
	-$(RM) pictured.s pictured.inc
	-$(RM) obj$(SEP)*.o
	-$(RM) obj$(SEP)*.lst
	-$(RMDIR) obj
	-$(RM) $(SDK_INC)$(SEP)vmachine.inc
	-$(RM) $(SDK_INC)$(SEP)core.inc
	-$(RM) $(SDK_INC)$(SEP)pictured.inc
	-$(RM) $(SDK_LIB)$(SEP)vmachine.lib
	-$(RMDIR) ..$(SEP)..$(SEP)sdk
