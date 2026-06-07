.define CORE_FS

.export max
.export min
.export umax
.export umin
.export negate
.export 2+
.export 2-
.export not
.export true
.export false
.export +!
.export cell
.export cell+

\ Comparison

: max ( n1 n2 -- n3 )
    2dup < if drop else nip then
;

: min ( n1 n2 -- n3 )
    2dup > if drop else nip then
;

: umax ( u1 u2 -- u3 )
    2dup u< if drop else nip then
;

: umin ( u1 u2 -- u3 )
    2dup u> if drop else nip then
;

\ Arithmetic

: negate ( n -- -n )
    invert 1+
;

: 2+ ( n -- n+2 )
    1+ 1+
;

: 2- ( n -- n-2 )
    1- 1-
;

\ Logic

: not ( f -- f )
    0=
;

: true  ( -- -1 )
    FORTH_TRUE
;

: false ( -- 0  )
    FORTH_FALSE
;

\ Memory functions

: +! ( n addr -- )
    dup @ rot + swap !
;

: cell ( -- n )
    CELL_SIZE
;

: cell+ ( n -- n+CELL_SIZE )
    CELL_SIZE +
;

