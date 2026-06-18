\ Calculate Pi using bignums and Machin's formula:
\ Pi = 16*arctan(1/5) - 4*arctan(1/239)
\ Which is computable with the arctangent series (Gregory's series):
\ arctan (x) = (x^1)/1 - (x^3)/3 + (x^5)/5 - (x^7)/7 + .. + -1^n*(x^2n+1)/(2n+1)

.include "core.inc"
.include "bignum.inc"

.main print-pi

500 constant DIGITS     \ SCALE = 10^500 as a bignum - need to construct this

10000  constant BN-BASE      \ base - 4 decimal digits per cell
125    constant BN-CELLS     \ 125 cells * 4 digits = 500 digits
                             \ +5 extra for carry margin
130    constant BN-SIZE      \ total cells allocated per bignum

.segment "BSS"		\ Place the variables and bignums in the data area

variable ar-x           \ x in arctan(1/x)
variable ar-x2          \ x squared
variable ar-i           \ current odd term index: 1, 3, 5, 7, ...
variable ar-sign        \ true = next term subtracts, false = next term adds

create pi-result 260 allot
create scale     260 allot
create scratch   260 allot
create scratch2  260 allot
create sum       260 allot
create term      260 allot

.segment "CODE"

: make-scale ( -- )
    1 scale bn-small
    DIGITS 0 do
        10 scale bn-mul
    loop
;

: arctan-recip ( x -- )
    dup ar-x !
    dup *
    ar-x2 !
    scale term bn-copy
    ar-x @ term bn-div drop
    term sum bn-copy
    1 ar-i !
    false ar-sign !
    begin
        ar-x2 @ term bn-div drop
        term bn-zero? 0=
    while
        ar-i @ 2 + dup ar-i !
        term scratch bn-copy
        scratch bn-div drop
        ar-sign @ if
            scratch sum bn-add
        else
            scratch sum bn-sub
        then
        ar-sign @ 0= ar-sign !
    repeat
;

: calc-pi ( -- )
    5 arctan-recip
    sum scratch2 bn-copy
    16 scratch2 bn-mul
    239 arctan-recip
    4 sum bn-mul
    sum scratch2 bn-sub
    scratch2 pi-result bn-copy
;

: mul16-test
    5 arctan-recip
    sum scratch2 bn-copy
    ." before *16: " scratch2 bn-print cr
    16 scratch2 bn-mul
    ." after *16: " scratch2 bn-print cr
;

: print-pi ( -- )
    cr ." Pi to 500 digits:" cr
    make-scale
    calc-pi
    pi-result bn-print
    cr
;
