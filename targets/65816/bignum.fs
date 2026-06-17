.export bn-zero
.export bn-small
.export bn-copy
.export bn-add
.export bn-sub
.export bn-mul
.export bn-div
.export bn-print
.export bn-zero?

.include "core.inc"
.include "pictured.inc"

10000  constant BN-BASE      \ base - 4 decimal digits per cell
125    constant BN-CELLS     \ 125 cells * 4 digits = 500 digits
                             \ +5 extra for carry margin
130    constant BN-SIZE      \ total cells allocated per bignum

variable bn-carry            \ scratch for bn-mul
variable bn-rem              \ scratch for bn-div

\ ---------------------------------------------------------------------------
\ bignum ( -- )
\ Define a new bignum variable. References push base address.
\ ---------------------------------------------------------------------------
: bignum ( -- )
\    create BN-SIZE cells allot
;

\ ---------------------------------------------------------------------------
\ bn-zero ( a -- )
\ Set all cells of bignum a to zero.
\ ---------------------------------------------------------------------------
: bn-zero ( a -- )
    BN-SIZE 0 do
        0 over i cells + !
    loop
    drop
;

\ ---------------------------------------------------------------------------
\ bn-small ( n a -- )
\ Set bignum a to single-cell value n.
\ ---------------------------------------------------------------------------
: bn-small ( n a -- )
    dup bn-zero
    !
;

\ ---------------------------------------------------------------------------
\ bn-copy ( src dst -- )
\ Copy bignum src to dst.
\ ---------------------------------------------------------------------------
: bn-copy ( src dst -- )
    BN-SIZE 0 do
        over i cells + @
        over i cells + !
    loop
    2drop
;

\ ---------------------------------------------------------------------------
\ bn-add ( a b -- )
\ b += a  in place, with carry propagation.
\ ---------------------------------------------------------------------------
variable bn-a
variable bn-b

: bn-add ( a b -- )
    bn-b !
    bn-a !
    0                               \ carry
    BN-SIZE 0 do
        bn-a @ i cells + @          \ a[i]
        bn-b @ i cells + @          \ b[i]
        + +                         \ a[i] + b[i] + carry
        dup BN-BASE /               \ new carry
        swap BN-BASE mod            \ new b[i]
        bn-b @ i cells + !          \ store new b[i]
    loop
    drop
;

\ ---------------------------------------------------------------------------
\ bn-sub ( a b -- )
\ b -= a  in place. Assumes b >= a (no underflow check).
\ ---------------------------------------------------------------------------
: bn-sub ( a b -- )
    bn-b !
    bn-a !
    0                               \ borrow
    BN-SIZE 0 do
        bn-b @ i cells + @          \ b[i]
        bn-a @ i cells + @          \ a[i]
        -                           \ b[i] - a[i]
        swap -                      \ - borrow
        dup 0< if
            BN-BASE +
            1
        else
            0
        then
        swap
        bn-b @ i cells + !
    loop
    drop
;

\ ---------------------------------------------------------------------------
\ bn-mul ( n a -- )
\ a *= n  in place. n must be small enough that n * BN-BASE fits in 32 bits.
\ ---------------------------------------------------------------------------
: bn-mul ( n a -- )
    0 bn-carry !
    BN-SIZE 0 do
        over                        \ ( n a n )
        over i cells + @            \ ( n a n a[i] )
        um*                         \ ( n a ud_lo ud_hi )
        bn-carry @ 0 d+             \ ( n a result_lo result_hi )
        BN-BASE um/mod              \ ( n a rem quot )
        bn-carry !                  \ save carry, stack: ( n a rem )
        over i cells + !            \ store rem, stack: ( n a )
    loop
    2drop
;

\ ---------------------------------------------------------------------------
\ bn-div ( n a -- rem )
\ a /= n  in place, high to low. Returns remainder.
\ n must be <= 65535. Quotient per cell must fit in 16 bits (n > BN-BASE/65535).
\ ---------------------------------------------------------------------------
: bn-div ( n a -- rem )
    0 bn-rem !
    BN-SIZE 0 do
        BN-SIZE 1 - i -
        cells over +
        @
        bn-rem @
        BN-BASE um*
        rot 0 d+
        3 pick
        um/mod                      \ ( n a rem quot )
        2 pick                      \ ( n a rem quot a )
        BN-SIZE 1 - i -
        cells + !                   \ store quot, stack: ( n a rem )
        bn-rem !                    \ stack: ( n a )
    loop
    2drop                           \ drop both n and a
    bn-rem @
;

\ ---------------------------------------------------------------------------
\ bn-zero? ( a -- flag )
\ True if all cells of a are zero.
\ ---------------------------------------------------------------------------
: bn-zero? ( a -- flag )
    true                            \ assume zero
    BN-SIZE 0 do
        over i cells + @
        0<> if
            drop false              \ found non-zero cell
            \ leave
        then
    loop
    swap drop
;

\ ---------------------------------------------------------------------------
\ bn-print ( a -- )
\ Print 500 decimal digits. Most significant cell first.
\ First cell printed without leading zeros, rest with leading zeros.
\ ---------------------------------------------------------------------------
variable bn-leading
: bn-print ( a -- )
    false bn-leading !
    BN-SIZE 0 do                    \ changed from BN-SIZE 1 - 0 do
        BN-SIZE 1 - i -
        cells over +
        @
        bn-leading @ if
            4 u.r
        else
            dup 0<> if
                true bn-leading !
                .
            else
                drop
            then
        then
    loop
    drop
    bn-leading @ 0= if
        0 .
    then
;
