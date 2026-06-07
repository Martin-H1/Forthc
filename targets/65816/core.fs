.define __core_fs__

.export max
.export min
.export umax
.export umin
.export dmax
.export dmin
.export negate
.export 2+
.export 2-
.export /mod
.export /
.export mod
.export s>d
.export not
.export true
.export false
.export +!
.export cell
.export cell+
.export 2drop
.export 2rot

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


\------------------------------------------------------------------------------
\ DMAX ( d1 d2 -- d ) larger of two doubles
\ https://forth-standard.org/standard/double/DMAX
\------------------------------------------------------------------------------
: dmax
    2over 2over d<
    if
        2swap
    then
    2drop
;

\------------------------------------------------------------------------------
\ DMIN ( d1 d2 -- d ) smaller of two doubles
\ https://forth-standard.org/standard/double/DMIN
\------------------------------------------------------------------------------
: dmin
    2over 2over d<
    if
        2drop
    else
        2swap
        2drop
    then
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

\------------------------------------------------------------------------------
\ /MOD - ( n1 n2 -- rem quot )   signed floored division
\------------------------------------------------------------------------------
: /mod ( n1 n2 -- rem quot )
    swap                            ( n2 n1 )
    s>d                             ( n2 n1 n1_hi )
    rot                             ( n1 n1_hi n2 )
    fm/mod                          ( rem quot )
;

\----------------------------------------------------------------------------\
\ / -  ( n1 n2 -- n3 )   signed 16/16 division
\----------------------------------------------------------------------------
: /
    /mod                            ( rem quot )
    nip                             ( quot )
;

\----------------------------------------------------------------------------
\ MOD - ( n1 n2 -- n3 )   modulo
\----------------------------------------------------------------------------
: mod
    /mod
    drop                            ( remainder )
;

\ S>D - ( n -- n [0 | -1]) sign extend a word to a long.
: s>d
    dup 0<
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

: cells ( n -- n*cell_size)
    CELL_SIZE *
;

: cell+ ( n -- n+CELL_SIZE )
    CELL_SIZE +
;

\ Stack functions
: 2drop
    drop
    drop
;

\------------------------------------------------------------------------------
\ 2ROT -
\ ( d1_lo d1_hi d2_lo d2_hi d3_lo d3_hi -- d2_lo d2_hi d3_lo d3_hi d1_lo d1_hi )
\------------------------------------------------------------------------------
: 2rot
    5 roll                ( d1_hi d2_lo d2_hi d3_lo d3_hi d1_lo )
    5 roll                ( d2_lo d2_hi d3_lo d3_hi d1_lo d1_hi )
;
