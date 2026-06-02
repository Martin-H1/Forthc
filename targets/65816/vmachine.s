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

;
; Useful macros
;
.macro ON16MEM
        REP     #MEM16              ; accumulator = 16-bit
        .A16
.endmacro

.macro OFF16MEM
        SEP     #MEM16              ; accumulator = 8-bit
        .A8
.endmacro

;------------------------------------------------------------------------------
; PUBLIC / ENDPUBLIC - Export a subroutine as a global symbol
;
; Usage:
;   PUBLIC my_function
;       ... code ...
;   ENDPUBLIC
;------------------------------------------------------------------------------
.macro  PUBLIC function_name
	.export function_name
	.proc   function_name
	.A16
	.I16
.endmacro

.macro  ENDPUBLIC
	.endproc
.endmacro

.segment "CODE"

; ---------------------------------------------------------------------------
; MAIN — program entry point, called via JSL from the ROM monitor.
; Link vmachine.o first so MAIN lands at the start of the CODE segment.
; The Forth module exports forth_main, which is the word named by .main
; ---------------------------------------------------------------------------
.import forth_main

PUBLIC  MAIN
        VM_INIT
        JSR  forth_main
        RTL
ENDPUBLIC


; ---------------------------------------------------------------------------
; vm_star  —  ( n1 n2 -- n3 )   16×16 → 16 multiply
; ---------------------------------------------------------------------------
; 65816 has no multiply instruction; we use a shift-and-add loop.
; ---------------------------------------------------------------------------
PUBLIC  vm_star
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
ENDPUBLIC

; ---------------------------------------------------------------------------
; vm_slash  —  ( n1 n2 -- n3 )   signed 16/16 division
; ---------------------------------------------------------------------------
PUBLIC  vm_slash
        JSR  vm_divmod
        INX                         ; discard remainder
        INX
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; vm_mod  —  ( n1 n2 -- n3 )   modulo
; ---------------------------------------------------------------------------
PUBLIC  vm_mod
        JSR  vm_divmod
        LDA  2,X                    ; remainder → TOS
        INX
        INX
        STA  0,X
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; vm_slashmod  —  ( n1 n2 -- rem quot )
; ---------------------------------------------------------------------------
PUBLIC  vm_slashmod
        JMP  vm_divmod
ENDPUBLIC

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
ENDPUBLIC

; ---------------------------------------------------------------------------
; Bitwise operations
; ---------------------------------------------------------------------------
PUBLIC  vm_and
        LDA  2,X
        AND  0,X
        INX
        INX
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_or
        LDA  2,X
        ORA  0,X
        INX
        INX
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_xor
        LDA  2,X
        EOR  0,X
        INX
        INX
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_not
        LDA  0,X
        EOR  #$FFFF
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_lshift
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
ENDPUBLIC

PUBLIC  vm_rshift
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
ENDPUBLIC

; ---------------------------------------------------------------------------
; Comparison  ( n1 n2 -- flag )
; ---------------------------------------------------------------------------
PUBLIC  vm_lt
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
ENDPUBLIC

PUBLIC  vm_gt
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
ENDPUBLIC

PUBLIC  vm_zeq
        LDA  0,X
        BNE  @false
        LDA  #$FFFF
        STA  0,X
        RTS
@false: STZ  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_zlt
        LDA  0,X
        BMI  @true
        STZ  0,X
        RTS
@true:  LDA  #$FFFF
        STA  0,X
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; Stack manipulation
; ---------------------------------------------------------------------------
PUBLIC  vm_over
        LDA  2,X
        DEX
        DEX
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_tuck
        DUP                             ; TOS = b
        LDA     4,X                     ; a
        STA     NOS,X                   ; NOS = a
        LDA     TOS,X                   ; b
        STA     4,X                     ; Slot below a = b
        RTS
ENDPUBLIC

PUBLIC  vm_swap
        LDA  0,X
        LDY  2,X
        STY  0,X
        STA  2,X
        RTS
ENDPUBLIC

PUBLIC	vm_pick                         ; ( xu...x1 x0 u -- xu...x1 x0 xu )
        STX  vm_scratch0                ; scratch0 = stack base (PSP)
        LDA  TOS,X                      ; u
        INC  A                          ; u+1 (skip u itself)
        ASL  A                          ; * 2 (cell size)
        CLC
        ADC  vm_scratch0                ; X + (u+1)*2
        STA  vm_scratch0
        LDA  (vm_scratch0)              ; Fetch xu
        STA  TOS,X                      ; Replace u with xu
        RTS
ENDPUBLIC

PUBLIC  vm_rot
        LDA  4,X                    ; n1
        LDY  2,X                    ; n2
        STY  4,X
        LDY  0,X                    ; n3
        STY  2,X
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_mrot                     ; ( a b c -- c a b )
        LDY  4,X                    ; a (bottom)
        LDA  TOS,X                  ; b
        STA  4,X                    ; bottom slot = b
        LDA  NOS,X                  ; c (TOS)
        STA  TOS,X                  ; middle slot = c
        STY  NOS,X                  ; TOS = a
        RTS
ENDPUBLIC

PUBLIC  vm_roll                     ; ROLL ( xu xu-1 ... x0 u -- xu-1 ... x0 xu)
        LDA  TOS,X
        INX
        INX
        CMP  #0                     ; n=0, nothing to do
        BEQ  @return
        ASL  A                      ; n*2 (byte to word offset)
        STA  vm_scratch0            ; save n*2

        ; Fetch x_n
        TXA
        CLC
        ADC  vm_scratch0
        STA  vm_scratch1            ; scratch1 = addr of x_n
        LDA  (vm_scratch1)          ; fetch x_n
        PHA                         ; save on return stack

        ; Shift x_0..x_n-1 up by one cell
@shift_loop:
        LDA  vm_scratch1
        SEC
        SBC  #CELL_SIZE
        STA  vm_scratch1            ; point to next lower item
        LDA  (vm_scratch1)          ; fetch it
        LDY  #CELL_SIZE
        STA  (vm_scratch1),Y        ; store one cell higher
        TXA
        CMP  vm_scratch1            ; reached PSP (x_0 position)?
        BNE  @shift_loop

        PLA                         ; restore x_n
        STA  TOS,X                  ; store at TOS (x_0 position)
@return:
        RTS
ENDPUBLIC

; vm_stod - sign extend a word to a long.
PUBLIC  vm_stod
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
ENDPUBLIC

PUBLIC  vm_2dup
        LDA  2,X
        LDY  0,X
        DEX
        DEX
        DEX
        DEX
        STA  2,X
        STY  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_2drop
        INX
        INX
        INX
        INX
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; DO-LOOP support
; vm_do_loop_step: increment top-of-return-stack index, compare to limit.
; Pushes $FFFF (done) or $0000 (continue) onto the parameter stack.
; ---------------------------------------------------------------------------
PUBLIC  vm_do_loop_step
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
ENDPUBLIC

; ---------------------------------------------------------------------------
; I  — ( -- n )  copy loop index to parameter stack
; ---------------------------------------------------------------------------
PUBLIC  vm_i
        TSX
        LDA  $0103,X                ; index from return stack
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; J  — ( -- n )  outer loop index
; ---------------------------------------------------------------------------
PUBLIC  vm_j
        TSX
        LDA  $0109,X                ; outer index (2 frames deep)
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        STX  vm_sp_shadow
        RTS
ENDPUBLIC

; ---------------------------------------------------------------------------
; I/O primitives  (platform-specific — stub implementations shown)
; Replace platform_putc / platform_getc with real hardware I/O.
; ---------------------------------------------------------------------------

PUBLIC  vm_emit
        LDA  0,X
        INX
        INX
        STX  vm_sp_shadow
        JSR  platform_putc
        LDX  vm_sp_shadow
        RTS
ENDPUBLIC

PUBLIC  vm_key
        STX  vm_sp_shadow
        JSR  platform_getc
        LDX  vm_sp_shadow
        DEX
        DEX
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_cputs
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
ENDPUBLIC

PUBLIC  vm_type
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
ENDPUBLIC

PUBLIC  vm_cr
        LDA  #$0D
        JSR  platform_putc
        LDA  #$0A
        JMP  platform_putc
ENDPUBLIC

PUBLIC  vm_space
        LDA  #$20
        JMP  platform_putc
ENDPUBLIC

PUBLIC  vm_spaces
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
ENDPUBLIC

PUBLIC  vm_dot
        LDA  0,X
        CMP  #0
        BPL  vm_udot
        ; Negative: negate value, then print minus sign
        EOR  #UINT_MAX
        INC  A
        STA  0,X
        LDA  #'-'
        JSR  platform_putc
ENDPUBLIC

; vm_udot - prints a 16 bit unsigned number to the console.
PUBLIC  vm_udot
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
ENDPUBLIC

PUBLIC  vm_dots
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
ENDPUBLIC

; ---------------------------------------------------------------------------
; Memory operations
; ---------------------------------------------------------------------------
PUBLIC  vm_allot
        LDA  0,X
        INX
        INX
        CLC
        ADC  vm_here_ptr
        STA  vm_here_ptr
        RTS
ENDPUBLIC

PUBLIC  vm_cells
        LDA  0,X
        ASL  A
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_cellplus
        LDA  0,X
        INC  A
        INC  A
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_here
        DEX
        DEX
        LDA  vm_here_ptr
        STA  0,X
        RTS
ENDPUBLIC

PUBLIC  vm_count
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
ENDPUBLIC

PUBLIC  vm_move
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
ENDPUBLIC

PUBLIC  vm_fill
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
ENDPUBLIC

; ---------------------------------------------------------------------------
; Zero-page / RAM variables used by the runtime
; ---------------------------------------------------------------------------
.segment "ZEROPAGE"
vm_sp_shadow:   .res 2              ; shadow of X (P-stack pointer)
vm_here_ptr:    .res 2              ; HERE pointer for bump allocator
vm_scratch0:    .res 2              ; general purpose scratch
vm_scratch1:    .res 2              ; general purpose scratch
vm_tmp1:        .res 2              ; scratch
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
