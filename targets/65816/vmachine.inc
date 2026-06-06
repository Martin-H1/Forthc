; =============================================================================
; vmachine.inc  —  65816 target
; Virtual machine macros: translate VM instructions to 65816 native code.
;
; Stack model:
;   Parameter stack (P-stack) grows DOWN in page zero, indexed by X.
;   X points to the TOP of stack (TOS).
;   Cell size is 2 bytes (16-bit).
;   Calling convention: subroutine-threaded (CALL → JSR, EXIT → RTS).
;
;   Memory layout (example, adjust with .org):
;       $0000-$00FF  zero page: scratch register variables
;       $0100-$01FF  hardware stack (return stack, used by JSR/RTS)
;       $0200-$02FF  parameter stack
;       $0200+       code and data
;
; Usage:
;   Generated code and vmachine.s both .include this file.
;   vmachine.s defines __vmachine_s__ = 1 before including, so the
;   .import directives below are skipped there (the symbols are defined,
;   not imported).  Every other translation unit gets the .imports.
;
; Register usage:
;   A  — scratch / TOS staging
;   X  — parameter stack pointer (points to current TOS)
;   Y  — scratch
; =============================================================================

.p816
.smart  off
.A16
.I16

; Common constants

; ANS Forth boolean values
FORTH_TRUE      = $FFFF
FORTH_FALSE     = $0000

CELL_SIZE       = 2

; Integer constants (based on C's limits.h)
INT_MIN         = $8000
INT_MAX         = $7FFF
MINUS_ONE       = $FFFF
UINT_MAX        = $FFFF

; Parameter stack offsets (relative to X = PSP)
TOS             = 0
NOS             = CELL_SIZE
PSP2            = CELL_SIZE * 2
PSP3            = CELL_SIZE * 3
PSP4            = CELL_SIZE * 4
PSP5            = CELL_SIZE * 5

; ---------------------------------------------------------------------------
; Conditionally import virtual machine runtime functions.
; Skipped when assembling vmachine.s itself (which exports them).
; ---------------------------------------------------------------------------
.ifndef __vmachine_s__
        .import vm_base_addr
        .import vm_clear
        .import vm_star
        .import vm_umstar
        .import vm_umslashmod
        .import vm_slashmod
        .import vm_slash
        .import vm_mod
        .import vm_smrem
        .import vm_fmmod
        .import vm_and
        .import vm_or
        .import vm_xor
        .import vm_lshift
        .import vm_rshift
        .import vm_lt
        .import vm_gt
        .import vm_eq
        .import vm_neq
        .import vm_ult
        .import vm_ugt
        .import vm_ule
        .import vm_uge
        .import vm_zeq
        .import vm_zne
        .import vm_zlt
        .import vm_zgt
        .import vm_over
        .import vm_swap
        .import vm_tuck
        .import vm_pick
        .import vm_rot
        .import vm_mrot
        .import vm_roll
        .import vm_stod
        .import vm_2fetch
        .import vm_2store
        .import vm_2dup
        .import vm_2drop
        .import vm_2swap
        .import vm_2over
        .import vm_2rot
        .import vm_stod
        .import vm_dplus
        .import vm_dminus
        .import vm_dabs
        .import vm_d2star
        .import vm_d2slash
        .import vm_dtos
        .import vm_dnegate
        .import vm_deq
        .import vm_dzeq
        .import vm_dzlt
        .import vm_dult
        .import vm_dlt
        .import vm_dmax
        .import vm_dmin
        .import vm_ddot
        .import vm_do_loop_step
        .import vm_plus_loop_step
        .import vm_j
        .import vm_emit
        .import vm_key
        .import vm_cputs
        .import vm_type
        .import vm_cr
        .import vm_space
        .import vm_spaces
        .import vm_dot
        .import vm_udot
        .import vm_depth
        .import vm_dots
        .import vm_allot
        .import vm_cells
        .import vm_cellplus
        .import vm_here
        .import vm_count
        .import vm_move
        .import vm_fill
        .import vm_sp_shadow
        .import vm_here_ptr
        .import vm_hld_addr
        .import vm_pad_end_addr
        .import vm_tmp1
        .import vm_tmp2
.endif

; ---------------------------------------------------------------------------
; LIT  — push a literal value onto the parameter stack
; ---------------------------------------------------------------------------
.macro  LIT  val
        LDA  #val
        DEX                         ; X -= 2  (16-bit decrement)
        DEX
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; EXIT  — return from word (subroutine return)
; ---------------------------------------------------------------------------
.macro  EXIT
        RTS
.endmacro

; ---------------------------------------------------------------------------
; CALL  — call a word (subroutine call)
; ---------------------------------------------------------------------------
.macro  CALL  addr
        JSR  addr
.endmacro

; ---------------------------------------------------------------------------
; FETCH  @  — ( addr -- n )   fetch cell at addr
; ---------------------------------------------------------------------------
.macro  FETCH
        LDY  TOS,X                  ; Y = addr (TOS)
        LDA  0,Y                    ; A = value at addr
        STA  TOS,X                  ; replace TOS
.endmacro

; ---------------------------------------------------------------------------
; STORE  !  — ( n addr -- )   store n at addr
; ---------------------------------------------------------------------------
.macro  STORE
        LDY  TOS,X                  ; Y = addr (TOS)
        DROP                        ; pop addr
        LDA  TOS,X                  ; A = n (new TOS)
        STA  0,Y                    ; store
        DROP                        ; pop n
.endmacro

; ---------------------------------------------------------------------------
; BFETCH  C@  — ( addr -- b )
; ---------------------------------------------------------------------------
.macro  BFETCH
        LDY  TOS,X
        LDA  #0
        SEP  #$20                   ; 8-bit A
        LDA  0,Y
        REP  #$20                   ; 16-bit A
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; BSTORE  C!  — ( b addr -- )
; ---------------------------------------------------------------------------
.macro  BSTORE
        LDY  TOS,X                  ; addr
        DROP
        SEP  #$20
        LDA  TOS,X                  ; b (low byte)
        STA  0,Y
        REP  #$20
        DROP
.endmacro

; ---------------------------------------------------------------------------
; TOR  >R  — ( n -- ) [R: -- n]
; ---------------------------------------------------------------------------
.macro  TOR
        LDA  TOS,X
        DROP
        PHA                         ; push A onto hardware (return) stack
.endmacro

; ---------------------------------------------------------------------------
; RFROM  R>  — ( -- n ) [R: n -- ]
; ---------------------------------------------------------------------------
.macro  RFROM
        PLA
        DEX
        DEX
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; RTOS R@  — ( -- n ) [R: n -- n ]
; ---------------------------------------------------------------------------
.macro  RTOS
        LDA  1,S                    ; TOS from return stack
        DEX
        DEX
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; TWOTOR  >R  — ( x1 x2 -- ) [R: -- x1 x2] equivalent to SWAP >R >R.
; ---------------------------------------------------------------------------
.macro  TWOTOR
        LDA  NOS,X                  ; x1 (NOS)
        PHA                         ; push x1 first
        LDA  TOS,X                  ; x2 (TOS)
        PHA                         ; push x2 on top
        DROP
        DROP
.endmacro

; ---------------------------------------------------------------------------
; TWORFROM  R>  — ( -- x1 x2 ) [R: x1 x2 -- ]
; ---------------------------------------------------------------------------
.macro  TWORFROM
        DEX
        DEX
        DEX
        DEX
        PLA                         ; x2 (TOS of return stack)
        STA  TOS,X                  ; x2 (TOS)
        PLA                         ; x1
        STA  NOS,X                  ; x1 (NOS)
.endmacro

; ---------------------------------------------------------------------------
; DUP  — ( n -- n n )
; ---------------------------------------------------------------------------
.macro  DUP
        LDA  TOS,X
        DEX
        DEX
        STA  TOS,X
.endmacro

;------------------------------------------------------------------------------
; QDUP - Conditionally Duplicates the TOS ( x -- 0 | x x )
;------------------------------------------------------------------------------
.macro  QDUP
        LDA  TOS,X
        .local @skip
        BEQ  @skip
        DEX
        DEX
        STA  TOS,X
@skip:
.endmacro

; ---------------------------------------------------------------------------
; DROP  — ( n -- )
; ---------------------------------------------------------------------------
.macro  DROP
        INX
        INX
.endmacro

; ---------------------------------------------------------------------------
; NIP  — ( n1 n2 -- n2 )
; ---------------------------------------------------------------------------
.macro  NIP
        LDA  TOS,X                  ; n2
        STA  NOS,X                  ; overwrite n1
        DROP
.endmacro

; ---------------------------------------------------------------------------
; ABS  — ( n  -- |n| )
; ---------------------------------------------------------------------------
.macro  ABS
        LDA  TOS,X
        .local @done
        BPL  @done
        EOR  #UINT_MAX
        INC  A
        STA  TOS,X
@done:
.endmacro

; ---------------------------------------------------------------------------
; INVERT  — ( n  -- ~n )
; ---------------------------------------------------------------------------
.macro  INVERT
        LDA  TOS,X
        EOR  #$FFFF
        STA  TOS,X
@done:
.endmacro

; ---------------------------------------------------------------------------
; 1+  — ( n -- n+1 )
; ---------------------------------------------------------------------------
.macro  ONEPLUS
        INC  TOS,X
.endmacro


; ---------------------------------------------------------------------------
; 1- — ( n -- n-1 )
; ---------------------------------------------------------------------------
.macro  ONEMINUS
        DEC  TOS,X
.endmacro

;------------------------------------------------------------------------------
; 2* ( n -- n*2 )
;------------------------------------------------------------------------------
.macro  TWOSTAR
        ASL  TOS,X
.endmacro

;------------------------------------------------------------------------------
; 2/ ( n -- n/2 ) arithmetic shift right
;------------------------------------------------------------------------------
.macro  TWOSLASH
        LDA  TOS,X                  ; Arithmetic shift right: preserve sign bit
        CMP  #INT_MIN               ; Set carry if negative
        ROR  A                      ; Shift right, sign bit from carry
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; ADD  +  — ( n1 n2 -- n3 )
; ---------------------------------------------------------------------------
.macro  ADD
        LDA  NOS,X                  ; n1
        CLC
        ADC  TOS,X                  ; + n2
        DROP
        STA  TOS,X                  ; result
.endmacro

; ---------------------------------------------------------------------------
; SUB  -  — ( n1 n2 -- n3 )
; ---------------------------------------------------------------------------
.macro  SUB
        LDA  NOS,X                  ; n1
        SEC
        SBC  TOS,X                  ; - n2
        DROP
        STA  TOS,X
.endmacro

; ---------------------------------------------------------------------------
; STAR  *  — ( n1 n2 -- n3 )  (calls runtime)
; This is left as a CALL because 65816 has no MUL instruction.
; ---------------------------------------------------------------------------
.macro  STAR
        JSR  vm_star
.endmacro

; ---------------------------------------------------------------------------
; EQ  =  — ( n1 n2 -- flag )   flag = $FFFF if equal, 0 otherwise
; ---------------------------------------------------------------------------
.macro  EQ
        JSR  vm_eq
.endmacro

; ---------------------------------------------------------------------------
; BRANCH  — ( -- )  unconditional branch
; ---------------------------------------------------------------------------
.macro  BRANCH  addr
        JMP  addr
.endmacro

; ---------------------------------------------------------------------------
; ZBRANCH  — ( flag -- )  branch if flag = 0
; ---------------------------------------------------------------------------
.macro  ZBRANCH  addr
        LDA  TOS,X
        DROP
        CMP  #0
        BNE  :+
        JMP  addr
:
.endmacro

; ---------------------------------------------------------------------------
; CLEAR  — ( ... -- )  reset parameter stack
; ---------------------------------------------------------------------------
.macro  CLEAR
        JSR  vm_clear
.endmacro
