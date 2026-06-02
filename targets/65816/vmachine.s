; =============================================================================
; vmachine.s  —  65816 runtime routines
;
; These implement the more complex VM operations that cannot be expressed
; as short inline macros.  They are called via JSR and return with RTS.
;
; Conventions:
;   X  = parameter stack pointer (TOS at 0,X)
;   All routines preserve X unless they explicitly push/pop stack items.
;   16-bit A and X throughout (REP #$30 assumed at entry).
; =============================================================================

; Sentinel: tells vmachine.inc to skip the .import block for these symbols,
; because we are defining (and exporting) them here.
__vmachine_s__ = 1

.p816
.smart  off
.A16
.I16
.include "vmachine.inc"

; Accumulator width helpers
MEM16   = $20                       ; accumulator width bit
IND16   = $10                       ; index register width bit

.macro ON16MEM
        REP     #MEM16              ; accumulator = 16-bit
        .A16
.endmacro

.macro OFF16MEM
        SEP     #MEM16              ; accumulator = 8-bit
        .A8
.endmacro

.segment "CODE"

; ---------------------------------------------------------------------------
; MAIN — program entry point, called via JSL from the ROM monitor.
; Link vmachine.o first so MAIN lands at the start of the CODE segment.
; The Forth module exports forth_main, which is the word named by .main
; ---------------------------------------------------------------------------
.import forth_main

.export MAIN
.proc   MAIN
        VM_INIT
        JSR  forth_main
        RTL
.endproc


; ---------------------------------------------------------------------------
; vm_star  —  ( n1 n2 -- n3 )   16×16 → 16 multiply
; ---------------------------------------------------------------------------
; 65816 has no multiply instruction; we use a shift-and-add loop.
; ---------------------------------------------------------------------------
.export vm_star
.proc   vm_star
        LDA  0,X                    ; multiplicand n2 (TOS)
        INX
        INX
        STA  vm_tmp1                ; save n2
        LDA  0,X                    ; multiplier n1
        LDY  #0                     ; accumulator
        STX  vm_sp_shadow
        LDX  #16                    ; 16 bits (loop counter, not stack ptr)
@loop:
        LSR  A                      ; shift multiplier right
        BCC  @skip
        PHA
        TYA
        CLC
        ADC  vm_tmp1                ; add multiplicand to accumulator
        TAY
        PLA
@skip:
        ASL  vm_tmp1                ; shift multiplicand left
        DEX
        BNE  @loop
        LDX  vm_sp_shadow           ; restore parameter stack pointer
        STY  0,X                    ; store result at TOS
        RTS
.endproc

; ---------------------------------------------------------------------------
; vm_slash  —  ( n1 n2 -- n3 )   signed 16/16 division
; ---------------------------------------------------------------------------
.export vm_slash
.proc   vm_slash
        JSR  vm_divmod
        INX                         ; discard remainder
        INX
        RTS
.endproc

; ---------------------------------------------------------------------------
; vm_mod  —  ( n1 n2 -- n3 )   modulo
; ---------------------------------------------------------------------------
.export vm_mod
.proc   vm_mod
        JSR  vm_divmod
        LDA  2,X                    ; remainder → TOS
        INX
        INX
        STA  0,X
        RTS
.endproc

; ---------------------------------------------------------------------------
; vm_slashmod  —  ( n1 n2 -- rem quot )
; ---------------------------------------------------------------------------
.export vm_slashmod
.proc   vm_slashmod
        JMP  vm_divmod
.endproc

; ---------------------------------------------------------------------------
; vm_divmod  — internal: ( n1 n2 -- rem quot )
; Uses repeated subtraction (replace with hardware-accelerated version
; for production use).
; ---------------------------------------------------------------------------
.proc   vm_divmod
        LDA  0,X                    ; divisor
        BNE  @ok
        STZ  0,X                    ; division by zero — push 0 0
        STZ  2,X
        RTS
@ok:
        LDA  2,X                    ; dividend n1
        LDY  #0                     ; quotient
@loop:
        CMP  0,X                    ; dividend >= divisor?
        BCC  @done
        SEC
        SBC  0,X                    ; dividend -= divisor
        INY
        BRA  @loop
@done:
        STA  2,X                    ; remainder (NOS)
        TYA
        STA  0,X                    ; quotient (TOS)
        RTS
.endproc

; ---------------------------------------------------------------------------
; Bitwise operations
; ---------------------------------------------------------------------------
.export vm_and
.proc   vm_and
        LDA  2,X
        AND  0,X
        INX
        INX
        STA  0,X
        RTS
.endproc

.export vm_or
.proc   vm_or
        LDA  2,X
        ORA  0,X
        INX
        INX
        STA  0,X
        RTS
.endproc

.export vm_xor
.proc   vm_xor
        LDA  2,X
        EOR  0,X
        INX
        INX
        STA  0,X
        RTS
.endproc

.export vm_not
.proc   vm_not
        LDA  0,X
        EOR  #$FFFF
        STA  0,X
        RTS
.endproc

.export vm_lshift
.proc   vm_lshift
        LDA  2,X                    ; value
        LDY  0,X                    ; shift count
        INX
        INX
@loop:
        CPY  #0
        BEQ  @done
        ASL  A
        DEY
        BRA  @loop
@done:
        STA  0,X
        RTS
.endproc

.export vm_rshift
.proc   vm_rshift
        LDA  2,X
        LDY  0,X
        INX
        INX
@loop:
        CPY  #0
        BEQ  @done
        LSR  A
        DEY
        BRA  @loop
@done:
        STA  0,X
        RTS
.endproc

; ---------------------------------------------------------------------------
; Comparison  ( n1 n2 -- flag )
; ---------------------------------------------------------------------------
.export vm_lt
.proc   vm_lt
        LDA  2,X
        CMP  0,X
        INX
        INX
        BCC  @true
        LDA  #0
        STA  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS
.endproc

.export vm_gt
.proc   vm_gt
        LDA  0,X
        CMP  2,X
        INX
        INX
        BCC  @true
        LDA  #0
        STA  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS
.endproc

.export vm_zeq
.proc   vm_zeq
        LDA  0,X
        BNE  @false
        LDA  #$FFFF
        STA  0,X
        RTS
@false: STZ  0,X
        RTS
.endproc

.export vm_zlt
.proc   vm_zlt
        LDA  0,X
        BMI  @true
        STZ  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS
.endproc

; ---------------------------------------------------------------------------
; Stack manipulation
; ---------------------------------------------------------------------------
.export vm_over
.proc   vm_over
        LDA  2,X
        DEX
        DEX
        STA  0,X
        RTS
.endproc

.export vm_tuck
.proc   vm_tuck
	DUP				; TOS = b
	LDA	4,X			; a
	STA	NOS,X			; NOS = a
	LDA	TOS,X			; b
	STA	4,X			; Slot below a = b
.endproc

.export vm_swap
.proc   vm_swap
        LDA  0,X
        LDY  2,X
        STY  0,X
        STA  2,X
        RTS
.endproc

.export vm_rot
.proc   vm_rot                      ; ( n1 n2 n3 -- n2 n3 n1 )
        LDA  4,X                    ; n1
        LDY  2,X                    ; n2
        STY  4,X
        LDY  0,X                    ; n3
        STY  2,X
        STA  0,X
        RTS
.endproc

; vm_stod - sign extend a word to a long.
.export vm_stod
.proc   vm_stod
        DEX
        DEX
        LDA     NOS,X           ; n
        BPL     @positive
        LDA     #MINUS_ONE      ; negative -> high cell = -1
        STA     TOS,X
        RTS
@positive:
        STZ     TOS,X           ; positive -> high cell = 0
        RTS
.endproc

.export vm_2dup
.proc   vm_2dup                     ; ( n1 n2 -- n1 n2 n1 n2 )
        LDA  2,X
        LDY  0,X
        DEX
        DEX
        DEX
        DEX
        STA  2,X
        STY  0,X
        RTS
.endproc

.export vm_2drop
.proc   vm_2drop
        INX
        INX
        INX
        INX
        RTS
.endproc

; ---------------------------------------------------------------------------
; DO-LOOP support
; vm_do_loop_step: increment top-of-return-stack index, compare to limit.
; Pushes $FFFF (done) or $0000 (continue) onto the parameter stack.
; ---------------------------------------------------------------------------
.export vm_do_loop_step
.proc   vm_do_loop_step
        TSX
        LDA  $0103,X                ; index (hardware stack at $0100+)
        INC  A
        STA  $0103,X                ; store incremented index
        CMP  $0105,X                ; compare to limit
        BNE  @continue
        LDX  vm_sp_shadow           ; restore P-stack pointer
        LDA  #$FFFF                 ; done: push true
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
@continue:
        LDX  vm_sp_shadow
        LDA  #0                     ; not done: push false
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
.endproc

; ---------------------------------------------------------------------------
; I  — ( -- n )  copy loop index to parameter stack
; ---------------------------------------------------------------------------
.export vm_i
.proc   vm_i
        TSX
        LDA  $0103,X                ; index from return stack
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
.endproc

; ---------------------------------------------------------------------------
; J  — ( -- n )  outer loop index
; ---------------------------------------------------------------------------
.export vm_j
.proc   vm_j
        TSX
        LDA  $0109,X                ; outer index (2 frames deep)
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
.endproc

; ---------------------------------------------------------------------------
; I/O primitives  (platform-specific — stub implementations shown)
; Replace platform_putc / platform_getc with real hardware I/O.
; ---------------------------------------------------------------------------

.export vm_emit
.proc   vm_emit                     ; ( c -- )  output character
        LDA  0,X
        INX
        INX
        STX  vm_sp_shadow
        JSR  platform_putc
        LDX  vm_sp_shadow
        RTS
.endproc

.export vm_key
.proc   vm_key                      ; ( -- c )  read character
        STX  vm_sp_shadow
        JSR  platform_getc
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        RTS
.endproc

.export vm_cputs
.proc   vm_cputs                    ; ( addr -- )  print null-terminated string
        LDA  0,X
        INX
        INX
        TAY                         ; Y = address
        OFF16MEM                    ; 8-bit A for byte fetches
@loop:
        LDA  0,Y
        BEQ  @done
        STX  vm_sp_shadow
        JSR  platform_putc
        LDX  vm_sp_shadow
        INY
        BRA  @loop
@done:
        ON16MEM                     ; restore 16-bit A
        RTS
.endproc

.export vm_type
.proc   vm_type                     ; ( addr u -- )  output u characters
        LDY  0,X                    ; count
        INX
        INX
        LDA  0,X                    ; addr
        INX
        INX
        PHX                         ; save P-stack pointer
        PHA                         ; save addr
        TYX                         ; X = count
        LDY  #0                     ; Y = string index
        OFF16MEM                    ; 8-bit A for byte fetches
@loop:
        CPX  #0
        BEQ  @done
        LDA  (1,S),Y                ; fetch byte from addr on stack
        JSR  platform_putc
        INY                         ; advance string index
        DEX                         ; decrement count
        BRA  @loop
@done:
        ON16MEM                     ; restore 16-bit A
        PLA                         ; restore addr (discard)
        PLX                         ; restore P-stack pointer
        RTS
.endproc

.export vm_cr
.proc   vm_cr
        LDA  #$0D
        JSR  platform_putc
        LDA  #$0A
        JMP  platform_putc
.endproc

.export vm_space
.proc   vm_space
        LDA  #$20
        JMP  platform_putc
.endproc

.export vm_spaces
.proc   vm_spaces                   ; ( n -- )
        LDA  0,X
        INX
        INX
        TAY
@loop:
        CPY  #0
        BEQ  @done
        STX  vm_sp_shadow
        LDA  #$20
        JSR  platform_putc
        LDX  vm_sp_shadow
        DEY
        BRA  @loop
@done:
        RTS
.endproc

.export vm_dot
.proc   vm_dot                      ; ( n -- )  print signed decimal
        LDA  0,X
        CMP  #0
        BPL  vm_udot
        ; Negative: negate value, then print minus sign
        EOR  #UINT_MAX
        INC  A
        STA  0,X
        LDA  #'-'
        JSR  platform_putc
.endproc

; vm_udot - prints a 16 bit unsigned number to the console.
.export vm_udot
.proc   vm_udot                     ; ( u -- )  print unsigned decimal
        ; Print TOS as unsigned decimal via repeated division
        ; Digits pushed onto hardware stack in reverse, then printed
        NUM_MSB = 4             ; Offsets to locals
        NUM_LSB = 3
        BCD     = 2
        BASE    = 1

        PHD                     ; save direct page register
        TOR                     ; Establish working area
        LDY  #10                ; Assume 10 until we add base support.
        PHY                     ; BASE (10 or 16)
        TSC                     ; Xfer RSP to direct page reg
        TCD                     ; stack local space is now direct page.

        OFF16MEM                ; Switch to byte mode.

        LDA  #0                 ; null delimiter for print loop
        PHA
@while:                         ; divide TOS by base
        STZ  BCD                ; clr BCD
        LDY  #16                ; {>} = loop counter
@foreachbit:
        ASL  NUM_LSB            ; TOS is gradually replaced
        ROL  NUM_MSB            ; with the quotient
        ROL  BCD                ; BCD result is gradually replaced
        LDA  BCD                ; with the remainder
        SEC
        SBC  BASE               ; partial BCD >= base ?
        BCC  @else
        STA  BCD                ; yes: update the partial result
        INC  NUM_LSB            ; set low bit in partial quotient
@else:
        DEY
        BNE  @foreachbit        ; loop 16 times
        LDA  BCD
        CMP  #10
        BCC  @decdigit
        ADC  #6                 ; 'A'-10-1+carry
@decdigit:
        ADC  #'0'               ; convert BCD result to ASCII
        PHA                     ; stack digits in ascending
        LDA  NUM_LSB            ; order ('0' for zero)
        ORA  NUM_MSB
        BNE  @while             ; } until TOS is 0
@print:
        PLA
@loop:
        JSR  platform_putc      ; print digits in descending order
        PLA                     ; until null delimiter is encountered
        BNE  @loop
        ON16MEM                 ; exit byte mode
        PLY                     ; clean up working area
        PLA
        PLD
        RTS
.endproc

.export vm_dots
.proc   vm_dots                 ; prints parameter stack contents.
        PHX                     ; Save PSP
        JSR  calc_depth
        BEQ  @ds_done           ; no items on stack, we're done.
        DEX
        DEX
        STA  0,X
        LDA  #'<'               ; print "<depth> "
        JSR  platform_putc
        JSR  vm_dot
        LDA  #'>'
        JSR  platform_putc
        LDA  #' '
        JSR  platform_putc
        LDX  #PSTACK_INIT
@print_loop:
        TXA                     ; Print stack items bottom to top.
        CMP  1,S
        BEQ  @ds_done
        DEX
        DEX
        JSR  vm_dot
        DEX
        DEX
        LDA  #' '
        JSR  platform_putc
        BRA  @print_loop
@ds_done:
        PLX                     ; Restore PSP
        RTS

calc_depth:
        TXA
        EOR  #UINT_MAX          ; Two's complement
        INC  A
        CLC
        ADC  #PSTACK_INIT       ; PSP_INIT - result / 2
        CMP  #INT_MIN           ; if bit 15 is set, carry = 1
        ROR  A                  ; Divide by 2 (cells)
        RTS
.endproc

; ---------------------------------------------------------------------------
; Memory operations
; ---------------------------------------------------------------------------
.export vm_allot
.proc   vm_allot                    ; ( n -- )  advance HERE by n bytes
        LDA  0,X
        INX
        INX
        CLC
        ADC  vm_here_ptr
        STA  vm_here_ptr
        RTS
.endproc

.export vm_cells
.proc   vm_cells                    ; ( n -- n*2 )  multiply by cell size
        LDA  0,X
        ASL  A
        STA  0,X
        RTS
.endproc

.export vm_cellplus
.proc   vm_cellplus                 ; ( addr -- addr+2 )
        LDA  0,X
        INC  A
        INC  A
        STA  0,X
        RTS
.endproc

.export vm_here
.proc   vm_here                     ; ( -- addr )
        DEX
        DEX
        LDA  vm_here_ptr
        STA  0,X
        RTS
.endproc

.export vm_count
.proc   vm_count                    ; ( addr -- addr+1 len )  counted string
        LDA  0,X                    ; addr
        TAY
        SEP  #$20
        LDA  0,Y                    ; length byte (8-bit)
        REP  #$20
        LDA  0,X
        INY
        STY  0,X                    ; addr+1 (NOS)
        DEX
        DEX
        ; A holds length byte, but junk in high byte.
        AND  #$00FF                 ; mask off junk.
        STA  0,X                    ; len (TOS)
        RTS
.endproc

.export vm_move
.proc   vm_move                     ; ( src dst u -- )  copy u bytes
        SRCPTR = 1
        DSTPTR = 3
        LDY  0,X                    ; u
        INX
        INX
        LDA  0,X                    ; dst
        INX
        INX
        PHA
        LDA  0,X                    ; src
        INX
        INX
        PHA
        DEY                         ; Change count to an index
@loop:
        CPY  #0
        BMI  @done                  ; loop terminates at -1 to copy 0 byte.
        OFF16MEM
        LDA     (SRCPTR,S),Y
        STA     (DSTPTR,S),Y
        ON16MEM
        INX
        INC  vm_tmp2
        DEY
        BRA  @loop
@done:
        PLA                         ; Drop stack locals
        PLA
        RTS
.endproc

.export vm_fill
.proc   vm_fill                     ; ( addr u b -- )  fill u bytes with b
        LOC_DSTPTR = 1
        LOC_BYTE = 3
        LDA  0,X                    ; pop fill byte to LOC_BYTE
        INX
        INX
        PHA
        LDY  0,X                    ; pop u (byte count) to Y
        INX
        INX
        LDA  0,X                    ; pop addr to LOC_DTSPTR
        INX
        INX
        PHA
        TYA                         ; Test for zero count = no-op
        BEQ  @done
        DEY                         ; Change count to an index
@loop:
        OFF16MEM
        LDA  LOC_BYTE,S
        STA  (LOC_DSTPTR,S),Y
        ON16MEM
        DEY
        BPL  @loop
@done:  PLA                         ; Drop stack locals
        PLA
        RTS
.endproc

; ---------------------------------------------------------------------------
; Zero-page / RAM variables used by the runtime
; ---------------------------------------------------------------------------
.segment "ZEROPAGE"
.export vm_sp_shadow
vm_sp_shadow:   .res 2              ; shadow of X (P-stack pointer)
.export vm_here_ptr
vm_here_ptr:    .res 2              ; HERE pointer
.export vm_tmp1
vm_tmp1:        .res 2              ; scratch
.export vm_tmp2
vm_tmp2:        .res 2              ; scratch

; ---------------------------------------------------------------------------
; Platform I/O — serial port 3 via ROM monitor vectors
; ---------------------------------------------------------------------------
.segment "CODE"

; ROM monitor entry points
GET_BYTE_FROM_PC    = $E033         ; read next byte from serial port 3
                                    ; returns carry clear on success, A = byte
SEND_BYTE_TO_PC     = $E063         ; write byte in A to serial port 3
                                    ; returns carry clear on success


platform_putc:                      ; ( A = char ) — output to serial port 3
@loop:  JSL  SEND_BYTE_TO_PC        ; retry until buffer is ready
        BCS  @loop
        RTS

platform_getc:                      ; ( -> A = char ) — input from serial port 3
        OFF16MEM
@loop:  JSL  GET_BYTE_FROM_PC       ; wait until a byte is available
        BCS  @loop
        ON16MEM
        AND  #$00FF                 ; zero-extend to 16 bits
        RTS
