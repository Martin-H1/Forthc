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

; Ascii / UTF-8 codes for commonly used unprintable control characters.
NULL     = $00                     ; null termination character
BKSP     = $08                     ; backspace
L_FEED   = $0A                     ; line feed
C_RETURN = $0D                     ; carriage return
SPACE    = $20                     ; space
DEL      = $7F                     ; Delete

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

; Uninitialized data segment
.segment "BSS"
pstack: .res $1FF
PSP_INIT:                           ; Stack starts here and grows downward.

vm_pad: .res 36                     ; PAD buf (at least 2*cell+2 bytes per ANS)
vm_pad_end:                         ; label at end of PAD
vm_tib: .res 32                     ; terminal input buffer

vm_hld: .res 2                      ; pictured output pointer
vm_here_ptr:
        .res 2                      ; HERE pointer for bump allocator
vm_base:
        .res 2                      ; numeric base (default 10)

HERE_INIT:
        .res $1000                  ; Here starts after all other VM data.

.segment "STARTUP"
;----------------------------------------------------------------------------
; MAIN — program entry point, called via JSL from the ROM monitor. The STARTUP
; segment to guarantee placement at a known address regardless of link order.
; The Forth module exports forth_main, which is the word named by .main
;----------------------------------------------------------------------------
.import forth_main
PUBLIC  MAIN
        REP  #$30                   ; 16-bit A and X
        LDX  #PSP_INIT              ; initialise parameter stack pointer
        LDA  #HERE_INIT
        STA  vm_here_ptr
        LDA  #10
        STA  vm_base
        JSR  forth_main
        RTL
ENDPUBLIC

.segment "CODE"

PUBLIC  vm_clear
        LDX  #PSP_INIT
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; BASE ( -- addr ) returns address of base variable.
;------------------------------------------------------------------------------
PUBLIC  vm_base_addr                ; ( -- addr )  push address of BASE
        LDA  #vm_base
        DEX
        DEX
        STA  0,X
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; *  —  ( n1 n2 -- n3 )   16×16 → 16 multiply
;----------------------------------------------------------------------------
; 65816 has no multiply instruction; we use a shift-and-add loop.
;----------------------------------------------------------------------------
PUBLIC  vm_star
        LDA  TOS,X                  ; multiplicand n2 (TOS)
        INX
        INX
        STA  vm_tmp1                ; save n2
        LDA  TOS,X                  ; multiplier n1
        LDY  #0                     ; accumulator
.ifndef UNROLL
        STX  vm_sp_shadow
        LDX  #16                    ; 16 bits (loop counter, not stack ptr)
@loop:
.else
.macro SHIFTADD16
.scope
.endif
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
.ifndef UNROLL
        DEX
        BNE  @loop
        LDX  vm_sp_shadow           ; restore parameter stack pointer
.else
.endscope
.endmacro
        ; Unroll the loop for performance.
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
        SHIFTADD16
.endif
        STY  TOS,X                  ; store result at TOS
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; UM* ( u1 u2 -- ud )   unsigned 16×16 → 32-bit product
; On exit: NOS = ud_low, TOS = ud_high   (ANS Forth convention)
;
; Algorithm: shift-and-add over a 32-bit accumulator.
;   vm_tmp1     = multiplier   (16-bit, shifted right)
;   vm_tmp2     = multiplicand low  word (shifted left, carry tracked below)
;   vm_scratch1 = multiplicand high word (starts 0; receives carry from TMPB)
;   vm_scratch0 = product low  word (accumulator)
;   NOS,X slot  = product high word (accumulator, kept on stack)
;------------------------------------------------------------------------------
PUBLIC  vm_umstar
        LDA  TOS,X                  ; u2 → tm_tmp1 (multiplier)
        STA  vm_tmp1
        LDA  NOS,X                  ; u1 → vm_tmp2 (multiplicand low)
        STA  vm_tmp2
        STZ  vm_scratch1            ; multiplicand high = 0
        STZ  vm_scratch0            ; product low  = 0
        STZ  TOS,X                  ; product high = 0  (reuse TOS slot)
.ifndef UNROLL
        LDY  #16                    ; 16 iterations
@loop:
.else
        ; Put the contents of an iteration in a macro.
.macro SHIFTADD32
.scope
.endif
        LSR  vm_tmp1                ; multiplier >>= 1; old LSB → carry
        BCC  @skip                  ; bit 0 was 0, nothing to add

        ; Add 32-bit multiplicand (vm_scratch1:vm_tmp2) to prod (TOS:vm_scratch0)
        CLC
        LDA  vm_scratch0
        ADC  vm_tmp2                ; product_low  += multiplicand_low
        STA  vm_scratch0
        LDA  TOS,X
        ADC  vm_scratch1            ; product_high += multiplicand_high + c
        STA  TOS,X
@skip:
        ; Shift 32-bit multiplicand left
        ASL  vm_tmp2                ; multiplicand_low <<= 1
        ROL  vm_scratch1            ; multiplicand_high <<= 1
.ifndef UNROLL
        DEY
        BNE  @loop
.else
.endscope
.endmacro
        ; Unroll the loop for performance.
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
        SHIFTADD32
.endif
        ; Place results on parameter stack:
        ;   TOS = ud_high, NOS = ud_low
        LDA  vm_scratch0
        STA  NOS,X                  ; NOS = low
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; UM/MOD ( ud u -- ur uq ) unsigned 32/16 -> 16 remainder, 16 quotient
; UNDEFINED if quotient overflows 16 bits (i.e. ud_high >= u)
; Entry stack: ( ud_low ud_high divisor -- )
;   TOS,X  = divisor  (u)
;   NOS,X  = ud_high  (high cell of 32-bit dividend)
;   PSP2,X = ud_low   (low cell of 32-bit dividend)
;
; Exit stack: ( remainder quotient )
;   TOS,X = quotient
;   NOS,X = remainder
; https://forth-standard.org/standard/core/UMDivMOD
;------------------------------------------------------------------------------
PUBLIC  vm_umslashmod
        LDA  TOS,X                  ; load divisor
        DROP
        STA  vm_tmp1                ; vm_tmp1 = divisor
        ; Now: TOS,X = ud_high (remainder register)
        ;      NOS,X = ud_low  (quotient register)
.ifndef UNROLL
        LDY  #16                    ; 16 iterations
@loop:
.else
.macro SHIFTSUB32
.scope
.endif
        ASL  NOS,X                  ; quotient  <<= 1; old bit15 → carry
        ROL  TOS,X                  ; remainder <<= 1; carry → bit0
        LDA  TOS,X                  ; current remainder
        SEC
        SBC  vm_tmp1                ; remainder - divisor
        BCC  @restore               ; borrow → remainder < divisor, skip
        STA  TOS,X                  ; update remainder
        INC  NOS,X                  ; set quotient LSB
@restore:
.ifndef UNROLL
        DEY
        BNE  @loop
.else
.endscope
.endmacro
        ; Unroll the loop for performance.
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
        SHIFTSUB32
.endif
        ; TOS,X = remainder, NOS,X = quotient
        ; swap to ANS order TOS=quotient NOS=remainder
        LDA  TOS,X
        STA  vm_scratch0
        LDA  NOS,X
        STA  TOS,X
        LDA  vm_scratch0
        STA  NOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; SM/REM ( d1 n1 -- n2 n3 ) Divide d1 by n1, giving the symmetric quotient n3
; and the remainder n2. Input and output stack arguments are signed. An
; ambiguous condition exists if n1 is zero or if the quotient lies outside
; the range of a single-cell signed integer.
; https://forth-standard.org/standard/core/SMDivREM
;------------------------------------------------------------------------------
PUBLIC  vm_smrem
        SMREM_N     = 1             ; saved divisor (n)
        SMREM_DHIGH = 3             ; saved d-high
        SMREM_SIGN  = 5             ; saved sign indicator (d-high XOR n)

        ; Save sign indicator, d-high, and n
        LDA  NOS,X                  ; d-high
        EOR  TOS,X                  ; XOR with n for sign indicator
        PHA                         ; SMREM_SIGN
        LDA  NOS,X                  ; d-high
        PHA                         ; SMREM_DHIGH
        LDA  TOS,X                  ; n
        PHA                         ; SMREM_N

        ; Take absolute value of n
        LDA  TOS,X
        BPL  @n_pos
        EOR  #UINT_MAX
        INC  A
        STA  TOS,X
@n_pos:
        ; Take absolute value of 32-bit dividend
        LDA  NOS,X                  ; d-high
        BPL  @d_pos
        LDA  PSP2,X                 ; d-low
        EOR  #UINT_MAX              ; invert
        CLC
        ADC  #1                     ; +1, carry set if result = 0
        STA  PSP2,X
        LDA  NOS,X                  ; d-high
        EOR  #UINT_MAX              ; invert
        ADC  #0                     ; add carry
        STA  NOS,X
@d_pos:
        JSR  vm_umslashmod          ; ( rem quot )

        ; Apply sign to quotient: sign(d-high XOR n)
        LDA  SMREM_SIGN,S
        BPL  @quot_pos
        LDA  TOS,X
        BEQ  @quot_pos
        EOR  #UINT_MAX
        INC  A
        STA  TOS,X
@quot_pos:
        ; Apply sign to remainder: sign of original d-high
        LDA  SMREM_DHIGH,S
        BPL  @rem_pos
        LDA  NOS,X
        BEQ  @rem_pos
        EOR  #UINT_MAX
        INC  A
        STA  NOS,X
@rem_pos:
        PLA                         ; drop SMREM_N
        PLA                         ; drop SMREM_DHIGH
        PLA                         ; drop SMREM_SIGN
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; FM/MOD ( d1 n1 -- n2 n3 ) Divide d1 by n1, giving the floored quotient n3 and
; the remainder n2. Input and output stack arguments are signed. An ambiguous
; condition exists if n1 is zero or if the quotient lies outside the range of
; a single-cell signed integer.
; https://forth-standard.org/standard/core/FMDivMOD
;------------------------------------------------------------------------------
PUBLIC  vm_fmmod
        LDA  NOS,X                  ; d-high
        EOR  TOS,X                  ; sign indicator
        PHA                         ; save sign indicator
        LDA  TOS,X                  ; n
        PHA                         ; save n
        JSR  vm_smrem               ; ( rem quot )
        ; Floor correction
        LDA  3,S                    ; sign indicator
        BPL  @done                  ; same signs → no correction
        LDA  NOS,X                  ; remainder
        BEQ  @done                  ; zero → no correction
        DEC  TOS,X                  ; quot -= 1
        LDA  NOS,X
        CLC
        ADC  1,S                    ; rem += n
        STA  NOS,X
@done:
        PLA                         ; drop n
        PLA                         ; drop sign indicator
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; vm_mulsl_power2 ( n1 n2 shift -- n1*n2>>shift )
; Specialized */ for power-of-two divisors.
;------------------------------------------------------------------------------
PUBLIC vm_mulsl_power2
        ; stack: ( n1 n2 shift )
        ; determine sign of result from n1 XOR n2
        LDA  NOS,X              ; n2
        EOR  PSP2,X             ; n1 XOR n2 — sign bit = sign of result
        PHA                     ; save sign on hardware stack
        LDA  TOS,X              ; shift count
        DROP                    ; remove shift from parameter stack
        PHA                     ; save shift count on hardware stack
        ; stack now: ( n1 n2 )
        ; abs(n1)
        LDA  NOS,X
        BPL  @n1pos
        EOR  #$FFFF
        INC  A
@n1pos: STA  NOS,X
        ; abs(n2)
        LDA  TOS,X
        BPL  @n2pos
        EOR  #$FFFF
        INC  A
@n2pos: STA  TOS,X
        ; unsigned multiply — leaves ( ud_lo ud_hi ) on stack
        JSR  vm_umstar
        ; retrieve shift count
        PLA
        TAY
        BEQ  @no_shift
@shift: LDA  TOS,X
        CMP  #$8000
        ROR  TOS,X
        ROR  NOS,X
        DEY
        BNE  @shift
@no_shift:
        ; retrieve sign
        PLA
        BPL  @positive
        ; negate 32-bit result
        LDA  NOS,X
        EOR  #$FFFF
        INC  A
        STA  NOS,X
        LDA  TOS,X
        EOR  #$FFFF
        ADC  #0
        STA  TOS,X
@positive:
        DROP                    ; discard ud_hi, ud_lo becomes TOS
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; Bitwise operations
;----------------------------------------------------------------------------

;------------------------------------------------------------------------------
; AND ( a b -- a&b )
;------------------------------------------------------------------------------
PUBLIC  vm_and
        LDA  NOS,X
        AND  TOS,X
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; OR ( a b -- a|b )
;------------------------------------------------------------------------------
PUBLIC  vm_or
        LDA  NOS,X
        ORA  TOS,X
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; XOR ( a b -- a^b )
;------------------------------------------------------------------------------
PUBLIC  vm_xor
        LDA  NOS,X
        EOR  TOS,X
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; LSHIFT ( a u -- a<<u )
;------------------------------------------------------------------------------
PUBLIC  vm_lshift
        LDA  NOS,X                  ; a value
        LDY  TOS,X                  ; u shift count
        DROP
@loop:
        CPY  #0
        BEQ  @done
        ASL  A
        DEY
        BRA  @loop
@done:
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; RSHIFT ( a u -- a>>u ) logical shift right
;------------------------------------------------------------------------------
PUBLIC  vm_rshift
        LDA  NOS,X                  ; a
        LDY  TOS,X                  ; u
        DROP
@loop:
        CPY  #0
        BEQ  @done
        LSR  A
        DEY
        BRA  @loop
@done:
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; = ( a b -- flag ) equality
;------------------------------------------------------------------------------
PUBLIC  vm_eq
        LDA  TOS,X
        CMP  NOS,X                  ; sets Z flag, no overflow possible for =
        BEQ  @true
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; <> ( a b -- flag ) inequality
;------------------------------------------------------------------------------
PUBLIC  vm_neq
        LDA  TOS,X
        CMP  NOS,X
        BNE  @true
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; < ( a b -- flag ) signed
;------------------------------------------------------------------------------
PUBLIC  vm_lt
        LDA  NOS,X                  ; a
        SEC
        SBC  TOS,X                  ; a - b
        BVS  @overflow              ; Overflow-aware signed compare
        BMI  @true                  ; result negative and no overflow = a<b
        LDA  #FORTH_FALSE           ; Set TOS to false
        BRA  @return
@overflow:
        BPL  @true                  ; overflow + positive result = a<b
@false: LDA  #FORTH_FALSE           ; Set TOS to false
        BRA  @return
@true:  LDA  #FORTH_TRUE            ; Set TOS to true
@return:
        DROP                        ; Drop b
        STA  TOS,X                  ; Set TOS to result
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; > ( a b -- flag ) signed
;------------------------------------------------------------------------------
PUBLIC  vm_gt
        LDA  TOS,X                  ; b
        SEC
        SBC  NOS,X                  ; b - a (reversed for >)
        BVS  @overflow              ; Overflow-aware signed compare
        BMI  @true                  ; like the previous function
        LDA  #FORTH_FALSE           ; Set TOS to false
        BRA  @return
@overflow:
        BPL  @true
@false: LDA  #FORTH_FALSE           ; Set TOS to false
        BRA  @return
@true:  LDA  #FORTH_TRUE            ; Set TOS to true
@return:
        DROP                        ; Drop b
        STA  TOS,X                  ; Set TOS to result
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; U< ( u1 u2 -- flag ) unsigned less than
;------------------------------------------------------------------------------
PUBLIC  vm_ult
        LDA  NOS,X                  ; u1
        CMP  TOS,X                  ; u1 - u2 (unsigned)
        BCC  @true                  ; Carry clear = u1 < u2
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; U> ( u1 u2 -- flag ) unsigned greater than
;------------------------------------------------------------------------------
PUBLIC  vm_ugt
        LDA  TOS,X                  ; u2
        CMP  NOS,X                  ; u2 - u1 (unsigned)
        BCC  @true
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; U<= ( u1 u2 -- flag ) unsigned less-than-or-equal
;------------------------------------------------------------------------------
PUBLIC  vm_ule
        LDA  NOS,X                  ; u1
        CMP  TOS,X                  ; sets carry and Z
        BEQ  @true                  ; equal counts as <=
        BCC  @true                  ; u1 < u2
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; U>= ( u1 u2 -- flag ) unsigned greater-than-or-equal
;------------------------------------------------------------------------------
PUBLIC  vm_uge
        LDA  NOS,X                  ; u1
        CMP  TOS,X                  ; sets carry
        BCS  @true                  ; carry set means u1 >= u2
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 0= ( a -- flag )
;------------------------------------------------------------------------------
PUBLIC  vm_zeq
        LDA  TOS,X
        BNE  @false
        LDA  #FORTH_TRUE
        STA  TOS,X
        RTS
@false: STZ  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 0<> ( a -- flag )
;------------------------------------------------------------------------------
PUBLIC  vm_zne
        LDA     TOS,X
        BEQ     @return
        LDA     #FORTH_TRUE
@return:STA     TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 0< ( a -- flag )
;------------------------------------------------------------------------------
PUBLIC  vm_zlt
        LDA  TOS,X
        BMI  @true
        STZ  TOS,X
        RTS
@true:  LDA  #$FFFF
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 0> ( a -- flag )
;------------------------------------------------------------------------------
PUBLIC  vm_zgt
        LDA  TOS,X
        BEQ  @false
        BPL  @true
@false: LDA  #FORTH_FALSE
        STA  TOS,X
        RTS
@true:  LDA  #FORTH_TRUE
        STA  TOS,X
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; Stack manipulation
;----------------------------------------------------------------------------
PUBLIC  vm_over
        LDA  NOS,X
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; TUCK ( a b -- b a b )
;------------------------------------------------------------------------------
PUBLIC  vm_tuck
        DUP                         ; TOS = b
        LDA  PSP2,X                 ; a
        STA  NOS,X                  ; NOS = a
        LDA  TOS,X                  ; b
        STA  PSP2,X                 ; Slot below a = b
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; SWAP ( a b -- b a )
;------------------------------------------------------------------------------
PUBLIC  vm_swap
        LDA  TOS,X
        LDY  NOS,X
        STY  TOS,X
        STA  NOS,X
        RTS
ENDPUBLIC

PUBLIC  vm_pick                     ; ( xu...x1 x0 u -- xu...x1 x0 xu )
        STX  vm_scratch0            ; scratch0 = stack base (PSP)
        LDA  TOS,X                  ; u
        INC  A                      ; u+1 (skip u itself)
        ASL  A                      ; * 2 (cell size)
        CLC
        ADC  vm_scratch0            ; X + (u+1)*2
        STA  vm_scratch0
        LDA  (vm_scratch0)          ; Fetch xu
        STA  TOS,X                  ; Replace u with xu
        RTS
ENDPUBLIC

PUBLIC  vm_rot
        LDA  PSP2,X                 ; n1
        LDY  NOS,X                  ; n2
        STY  PSP2,X
        LDY  TOS,X                  ; n3
        STY  NOS,X
        STA  TOS,X
        RTS
ENDPUBLIC

PUBLIC  vm_mrot                     ; ( a b c -- c a b )
        LDY  PSP2,X                 ; a (bottom)
        LDA  TOS,X                  ; b
        STA  PSP2,X                 ; bottom slot = b
        LDA  NOS,X                  ; c (TOS)
        STA  TOS,X                  ; middle slot = c
        STY  NOS,X                  ; TOS = a
        RTS
ENDPUBLIC

PUBLIC  vm_roll                     ; ROLL ( xu xu-1 ... x0 u -- xu-1 ... x0 xu)
        LDA  TOS,X
        DROP
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

;------------------------------------------------------------------------------
; 2@ ( a-addr -- x1 x2 ) Fetch the cell pair x1 x2 stored at a-addr. x2 is
; stored at a-addr and x1 at the next consecutive cell. It is equivalent to
; the sequence DUP CELL+ @ SWAP @.
; https://forth-standard.org/standard/core/TwoFetch
;------------------------------------------------------------------------------
PUBLIC  vm_2fetch
        LDY  TOS,X                  ; peek addr → Y
        LDA  CELL_SIZE,Y            ; high cell of d
        STA  TOS,X
        LDA  0,Y                    ; low cell of d
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 2! ( x1 x2 a-addr -- ) Store the cell pair x1 x2 at a-addr, with x2 at
; a-addr and x1 at the next consecutive cell. It is equivalent to the sequence
; SWAP OVER ! CELL+ !.
; https://forth-standard.org/standard/core/TwoStore
;------------------------------------------------------------------------------
PUBLIC  vm_2store
        LDY  TOS,X                  ; peek addr → Y
        LDA  NOS,X                  ; low cell of d
        STA  0,Y                    ; store at addr
        LDA  PSP2,X                 ; high cell of d
        STA  CELL_SIZE,Y            ; store at addr+2
        CLC
        TXA
        ADC  #3*CELL_SIZE           ; drop 3 cells
        TAX
        RTS
ENDPUBLIC

PUBLIC  vm_2dup
        LDA  NOS,X
        LDY  TOS,X
        DEX
        DEX
        DEX
        DEX
        STA  NOS,X
        STY  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 2SWAP ( a b c d -- c d a b )
;------------------------------------------------------------------------------
PUBLIC  vm_2swap
        LDY  TOS,X                  ; d
        LDA  NOS,X                  ; c
        STA  vm_scratch1
        LDA  PSP2,X                 ; b
        STA  TOS,X
        LDA  PSP3,X                 ; a
        STA  NOS,X
        STY  PSP2,X                 ; d
        LDA  vm_scratch1            ; c
        STA  PSP3,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; 2OVER ( a b c d -- a b c d a b )
;------------------------------------------------------------------------------
PUBLIC  vm_2over
        LDA  PSP3,X                 ; a
        DEX
        DEX
        STA  TOS,X                  ; Push a (NOS)
        LDA  PSP3,X                 ; b
        DEX
        DEX
        STA  TOS,X                  ; Push b
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; D+ ( d1_lo d1_hi d2_lo d2_hi -- d3_lo d3_hi )
; 32-bit addition with carry from low to high cell.
; Stack: TOS=d2_hi, NOS=d2_lo, NOS2=d1_hi, NOS3=d1_lo
;------------------------------------------------------------------------------
PUBLIC  vm_dplus
        CLC
        LDA  PSP3,X                 ; d1_lo
        ADC  NOS,X                  ; + d2_lo
        STA  PSP3,X                 ; result_lo
        LDA  PSP2,X                 ; d1_hi
        ADC  TOS,X                  ; + d2_hi + carry
        STA  PSP2,X                 ; result_hi
        DROP
        DROP                        ; drop d2 cells
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; D- ( d1_lo d1_hi d2_lo d2_hi -- d3_lo d3_hi )
; 32-bit subtraction with borrow from low to high cell.
;------------------------------------------------------------------------------
PUBLIC  vm_dminus
        SEC
        LDA  PSP3,X                 ; d1_lo
        SBC  NOS,X                  ; - d2_lo
        STA  PSP3,X                 ; result_lo
        LDA  PSP2,X                 ; d1_hi
        SBC  TOS,X                  ; - d2_hi - borrow
        STA  PSP2,X                 ; result_hi
        DROP
        DROP                        ; drop d2 cells
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; DABS ( d -- ud ) double absolute value
;------------------------------------------------------------------------------
PUBLIC  vm_dabs
        LDA  TOS,X            	    ; d_hi
        BPL  @done                  ; done if already positive.
        JSR  vm_dnegate             ; ( ud_lo ud_hi ) negate if negative
@done:  RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; DNEGATE ( d -- -d ) negate the double cell in ANS order on stack.
; https://forth-standard.org/standard/double/DNEGATE
;------------------------------------------------------------------------------
PUBLIC  vm_dnegate
        LDA  TOS,X                  ; high cell
        EOR  #UINT_MAX              ; invert
        STA  TOS,X
        LDA  NOS,X                  ; low cell
        EOR  #UINT_MAX              ; invert
        INC  A                      ; +1
        STA  NOS,X
        BNE  @done                  ; no carry
        INC  TOS,X                  ; propagate carry to high cell
@done:  RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; D= ( d1_lo d1_hi d2_lo d2_hi -- flag )
; True if both cells equal.
;------------------------------------------------------------------------------
PUBLIC  vm_deq
        LDA  PSP3,X                 ; d1_lo
        CMP  NOS,X                  ; d2_lo
        BNE  @false
        LDA  PSP2,X                 ; d1_hi
        CMP  TOS,X                  ; d2_hi
        BNE  @false
        LDA  #FORTH_TRUE
        BRA  @return
@false:
        LDA  #FORTH_FALSE
@return:
	DROP                        ; drop 3 cells
        DROP
        DROP
        STA  TOS,X                  ; Put flag in 4th cell
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; DU< ( ud1_lo ud1_hi ud2_lo ud2_hi -- flag )
; Unsigned 32-bit less than.
;------------------------------------------------------------------------------
PUBLIC  vm_dult
        ; Compare high cells first
        LDA  PSP2,X                 ; ud1_hi
        CMP  TOS,X                  ; ud2_hi
        BCC  @true                  ; ud1_hi < ud2_hi unsigned
        BNE  @false                 ; ud1_hi > ud2_hi
        ; High cells equal, compare low cells
        LDA  PSP3,X                 ; ud1_lo
        CMP  NOS,X                  ; ud2_lo
        BCC  @true
@false:
        LDA  #FORTH_FALSE
        BRA  @return
@true:  LDA  #FORTH_TRUE
@return:
        DROP                        ; drop 3 cells
        DROP
        DROP
        STA  TOS,X                  ; Put flag in 4th cell
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; D< ( d1_lo d1_hi d2_lo d2_hi -- flag )
; Signed 32-bit less than. Compare high cells with overflow-aware signed
; compare; only if high cells are equal fall through to unsigned low cell
; compare.
;------------------------------------------------------------------------------
PUBLIC  vm_dlt
        ; Compare high cells (signed)
        LDA  PSP2,X                 ; d1_hi
        SEC
        SBC  TOS,X                  ; d1_hi - d2_hi
        BEQ  @equal_hi              ; high cells equal, check low
        BVS  @overflow
        BMI  @true                  ; negative, no overflow -> d1 < d2
        BRA  @false
@overflow:
        BPL  @true                  ; overflow + positive -> d1 < d2
        BRA  @false
@equal_hi:
        ; High cells equal: unsigned compare of low cells
        LDA  PSP3,X                 ; d1_lo
        CMP  NOS,X                  ; d2_lo
        BCC  @true
@false:
        LDA  #FORTH_FALSE
        BRA  @return
@true:
        LDA  #FORTH_TRUE
@return:
        DROP                        ; drop 3 cells
        DROP
        DROP
        STA  TOS,X                  ; Put flag in 4th cell
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; EXECUTE ( xt -- ) execute word by execution token
;------------------------------------------------------------------------------
PUBLIC  vm_execute
        LDA  TOS,X                  ; xt = code pointer
        STA  vm_scratch0            ; place in scratch pointer.
        JMP  (vm_scratch0)          ; Jump (RTS will return to our caller.)
ENDPUBLIC

;----------------------------------------------------------------------------
; DO-LOOP support
; vm_do_loop_step: increment top-of-return-stack index, compare to limit.
; Pushes $FFFF (done) or $0000 (continue) onto the parameter stack.
;----------------------------------------------------------------------------
PUBLIC  vm_do_loop_step
        LDA  3,S                    ; index (hardware stack at $0100+)
        INC  A
        STA  3,S                    ; store incremented index
        CMP  5,S                    ; compare to limit
        BNE  @continue
        LDA  #$FFFF                 ; done: push true
        BRA  @return
@continue:
        LDA  #0                     ; not done: push false
@return:
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; vm_plus_loop_step ( step -- flag )
; Adds step to the loop index on the return stack.
; Returns FORTH_TRUE if loop should continue, FORTH_FALSE if done.
;------------------------------------------------------------------------------
PUBLIC  vm_plus_loop_step
        LDA  TOS,X                  ; step
        DROP                        ; consume step from parameter stack
        CLC
        ADC  3,S                    ; index += step
        STA  3,S                    ; store updated index
        ; signed comparison: index < limit
        SEC
        SBC  5,S                    ; index - limit
        BVS  @overflow              ; overflow-aware signed compare
        BMI  @continue              ; result negative = index < limit
        LDA  #$FFFF                 ; done
        BRA  @return
@overflow:
        BPL  @continue              ; overflow + positive = index < limit
        LDA  #$FFFF                 ; done
        BRA  @return
@continue:
        LDA  #0                     ; not done
@return:
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; J  — ( -- n )  outer loop index
;----------------------------------------------------------------------------
PUBLIC  vm_j
        LDA  9,S                    ; outer index (2 frames deep)
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; I/O primitives  (platform-specific — stub implementations shown)
; Replace platform_putc / platform_getc with real hardware I/O.
;----------------------------------------------------------------------------

PUBLIC  vm_emit
        LDA  TOS,X
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
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; ACCEPT ( addr maxlen -- actual )
; Read a line from the UART into the buffer at addr, up to maxlen characters.
; Returns actual character count (not including the terminating CR).
;
; Supported control characters:
;   CR  ($0D) - end of input
;   BS  ($08) - backspace: erase last character if any
;   DEL ($7F) - same as BS
;   All other characters stored if buffer not full, echoed to terminal.
;------------------------------------------------------------------------------
PUBLIC  vm_accept
        ; Stack frame locals (DP points here after TCD):
        LOC_MAXLEN  = 1             ; maximum character count
        LOC_BUF     = 3             ; buffer base address
        LOC_COUNT   = 5             ; current character count
        LOC_CHAR    = 7             ; last received character
        LOC_SIZE    = LOC_CHAR + 1  ; = 8 bytes reserved
        ;   (saved IP  = 9,  pushed by PHY before frame reserved)
        ;   (saved DP  = 11, pushed by PHD before PHY)

        PHD                         ; Save DP
        TSC                         ; Reserve stack frame
        SEC
        SBC  #LOC_SIZE
        TCS
        TCD                         ; DP -> stack frame

        ; Pop arguments from parameter stack using absolute addressing
        LDA  a:TOS,X                ; maxlen
        STA  LOC_MAXLEN
        LDA  a:NOS,X                ; addr
        STA  LOC_BUF
        ; Drop both cells from parameter stack
        TXA
        CLC
        ADC  #4
        TAX

        STZ  LOC_COUNT              ; char count = 0

        ;--------------------------------------------------------------
        ; Main character receive loop
        ;--------------------------------------------------------------
@getchar:
        JSR  platform_getc          ; Blocking receive; char returned in A
        STA  LOC_CHAR               ; Save received character

        CMP  #C_RETURN              ; CR -> end of line
        BEQ  @done

        CMP  #BKSP                  ; BS -> backspace
        BEQ  @backspace
        CMP  #DEL                   ; DEL -> backspace
        BEQ  @backspace

        ; Normal character: store if buffer not full
        LDA  LOC_COUNT
        CMP  LOC_MAXLEN             ; count >= maxlen?
        BCS  @getchar               ; Buffer full, discard char

        ; Store character in buffer at BUF[count]
        ; Use Y as byte index; IP already saved in frame
        LDY  LOC_COUNT
        OFF16MEM
        LDA  LOC_CHAR
        STA  (LOC_BUF),Y            ; BUF[count] = char
        ON16MEM

        JSR  platform_putc          ; Echo character

        INC  LOC_COUNT
        BRA  @getchar

        ;--------------------------------------------------------------
        ; Backspace: erase last character if any
        ;--------------------------------------------------------------
@backspace:
        TAY
        BEQ  @getchar               ; Nothing to delete
        DEC  LOC_COUNT
        LDA  #BKSP
        JSR  platform_putc
        LDA  #SPACE                 ; Space (erase on terminal)
        JSR  platform_putc
        LDA  #BKSP                  ; BS again (reposition cursor)
        JSR  platform_putc
        BRA  @getchar

        ;--------------------------------------------------------------
        ; CR received: echo CR+LF, push count, tear down and return
        ;--------------------------------------------------------------
@done:  JSR  vm_cr

@return:
        LDA  LOC_COUNT              ; actual character count = result
        DEX                         ; Push result onto parameter stack
        DEX
        STA  a:TOS,X

        ; Tear down frame, restore IP and DP
        TSC
        CLC
        ADC  #LOC_SIZE
        TCS
        PLD                         ; Restore DP
        RTS
ENDPUBLIC

PUBLIC  vm_cputs
        LDA  TOS,X
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
        LDY  TOS,X                  ; count
        INX
        INX
        LDA  TOS,X                  ; addr
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
        LDA  #C_RETURN
        JSR  platform_putc
        LDA  #L_FEED
        JMP  platform_putc
ENDPUBLIC

PUBLIC  vm_space
        LDA  #$20
        JMP  platform_putc
ENDPUBLIC

PUBLIC  vm_spaces
        LDA  TOS,X
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

; vm_dot - prints a 16 bit signed number to the console.
PUBLIC  vm_dot
        JSR  print_sdec
        LDA  #' '
        JSR  platform_putc
        RTS
ENDPUBLIC

; vm_udot - prints a 16 bit unsigned number to the console.
PUBLIC  vm_udot
        JSR  print_udec
        LDA  #' '
        JSR  platform_putc
        RTS
ENDPUBLIC

.proc   print_sdec
        LDA  TOS,X
        CMP  #0
        BPL  vm_udot
        ; Negative: negate value, then print minus sign
        EOR  #UINT_MAX
        INC  A
        STA  TOS,X
        LDA  #'-'
        JSR  platform_putc
.endproc
.proc   print_udec
        ; Print TOS as unsigned decimal via repeated division
        ; Digits pushed onto hardware stack in reverse, then printed
        NUM_MSB = 4             ; Offsets to locals
        NUM_LSB = 3
        BCD     = 2
        BASE    = 1

        PHD                     ; save direct page register
        TOR                     ; Establish working area
        LDY  vm_base            ; current numeric base
        PHY                     ; BASE
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

;------------------------------------------------------------------------------
; vm_dothex ( n -- ) - prints a 16 bit hex number to the console.
;------------------------------------------------------------------------------
PUBLIC  vm_dothex
        LDA  TOS,X
        XBA
        JSR  putahex
        LDA  TOS,X
        JSR  putahex
        LDA  #' '
        JSR  platform_putc
        DROP
        RTS

putahex:
        PHA
        LSR
        LSR
        LSR
        LSR
        JSR  @print_nybble
        PLA
        JSR  @print_nybble
        RTS

@print_nybble:
        AND  #$000F
        SED
        CLC
        ADC  #$9990                     ; Produce $90-$99 or $00-$05
        ADC  #$9940                     ; Produce $30-$39 or $41-$46
        CLD
        JMP  platform_putc
ENDPUBLIC

;------------------------------------------------------------------------------
; DEPTH ( -- n ) number of items on parameter stack
;------------------------------------------------------------------------------
PUBLIC  vm_depth
        JSR  calc_depth
        DEX
        DEX
        STA  TOS,X
        RTS

calc_depth:
        TXA
        EOR  #UINT_MAX          ; Two's complement
        INC  A
        CLC
        ADC  #PSP_INIT          ; PSP_INIT - result / 2
        CMP  #INT_MIN           ; if bit 15 is set, carry = 1
        ROR  A                  ; Divide by 2 (cells)
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; vm_dots ( -- ) prints the items on parameter stack
;------------------------------------------------------------------------------
PUBLIC  vm_dots
        PHX                     ; Save PSP
        JSR  vm_depth::calc_depth
        BEQ  @ds_done           ; no items on stack, we're done.
        DEX
        DEX
        STA  TOS,X
        LDA  #'<'               ; print "<depth> "
        JSR  platform_putc
        JSR  print_udec
        LDA  #'>'
        JSR  platform_putc
        LDA  #' '
        JSR  platform_putc
        LDX  #PSP_INIT
@print_loop:
        TXA                     ; Print stack items bottom to top.
        CMP  1,S
        BEQ  @ds_done
        DEX
        DEX
        JSR  vm_dot
        DEX
        DEX
        BRA  @print_loop
@ds_done:
        PLX                     ; Restore PSP
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; Memory operations
;----------------------------------------------------------------------------

;------------------------------------------------------------------------------
; ALLOT ( n -- ) advance bump allocator pointer by n bytes
;------------------------------------------------------------------------------
PUBLIC  vm_allot
        LDA  TOS,X
        DROP
        CLC
        ADC  vm_here_ptr
        STA  vm_here_ptr
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; HERE ( -- addr ) current bump allocator pointer
;------------------------------------------------------------------------------
PUBLIC  vm_here
        DEX
        DEX
        LDA  vm_here_ptr
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; , ( val -- ) compile cell into memory
;------------------------------------------------------------------------------
PUBLIC  vm_comma
        LDA  vm_here_ptr
        TAY
        CLC                     ; DP += CELL_SIZE
        ADC  #CELL_SIZE
        STA  vm_here_ptr        ; Write updated pointer back
        LDA  TOS,X              ; Pop val off parameter stack
        DROP
        STA  0,Y                ; Store val at DP
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; c, ( byte -- ) compile byte into dictionary
;------------------------------------------------------------------------------
PUBLIC  vm_ccomma
        LDA  vm_here_ptr
        TAY
        INC  A                  ; DP += 1
        STA  vm_here_ptr        ; Write updated DP back
        LDA  TOS,X              ; Pop byte off parameter stack
        DROP
        OFF16MEM
        STA  0,Y                ; Store byte at DP pointer
        ON16MEM
        RTS
ENDPUBLIC

PUBLIC  vm_count
        LDY  TOS,X                  ; addr
        SEP  #$20
        LDA  0,Y                    ; length byte (8-bit)
        REP  #$20
        INY
        STY  TOS,X                  ; addr+1 (NOS)
        DEX
        DEX
        ; A holds length byte, but junk in high byte.
        AND  #$00FF                 ; mask off junk.
        STA  TOS,X                  ; len (TOS)
        RTS
ENDPUBLIC

PUBLIC  vm_move
        SRCPTR = 1
        DSTPTR = 3
        LDY  TOS,X                  ; u
        INX
        INX
        LDA  TOS,X                  ; dst
        INX
        INX
        PHA
        LDA  TOS,X                  ; src
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
        LDA  TOS,X                  ; pop fill byte to LOC_BYTE
        INX
        INX
        PHA
        LDY  TOS,X                  ; pop u (byte count) to Y
        INX
        INX
        LDA  TOS,X                  ; pop addr to LOC_DTSPTR
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

;------------------------------------------------------------------------------
; vm_hld_addr ( -- addr )  push address of HLD variable
;------------------------------------------------------------------------------
PUBLIC  vm_hld_addr
        LDA  #vm_hld
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;------------------------------------------------------------------------------
; vm_pad_end_addr ( -- addr )  push address of PAD_END
;------------------------------------------------------------------------------
PUBLIC  vm_pad_end_addr
        LDA  #vm_pad_end
        DEX
        DEX
        STA  TOS,X
        RTS
ENDPUBLIC

;----------------------------------------------------------------------------
; Zero-page / RAM variables used by the runtime
;----------------------------------------------------------------------------
.segment "ZEROPAGE"
vm_sp_shadow:   .res 2              ; shadow of X (P-stack pointer)
vm_scratch0:    .res 2              ; general purpose scratch
vm_scratch1:    .res 2              ; general purpose scratch
vm_tmp1:        .res 2              ; scratch
vm_tmp2:        .res 2              ; scratch

;----------------------------------------------------------------------------
; Platform I/O — serial port 3 via ROM monitor vectors
;----------------------------------------------------------------------------
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
