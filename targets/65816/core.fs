.export max
.export min
.export umax
.export umin
.export within
.export d0=
.export d0<
.export dmax
.export dmin
.export min-int
.export max-int
.export min-2int
.export max-2int
.export negate
.export 2+
.export 2-
.export /mod
.export /
.export */mod
.export */
.export mod
.export s>d
.export m+
.export m*
.export m*/
.export d2*
.export d2/
.export d>s
.export not
.export true
.export false
.export +!
.export aligned
.export cell
.export cells
.export cell+
.export erase
.export 2drop
.export 2rot

$FFFF constant forth_true
0     constant forth_false
2     constant cell_size
$8000 constant int_min
$7FFF constant int_max
$FFFF constant minus_one
$FFFF constant uint_max

\ Comparison

: max ( n1 n2 -- n3 )
    2dup > if drop else nip then
;

: min ( n1 n2 -- n3 )
    2dup < if drop else nip then
;

: umax ( u1 u2 -- u3 )
    2dup u< if drop else nip then
;

: umin ( u1 u2 -- u3 )
    2dup u> if drop else nip then
;

\------------------------------------------------------------------------------
\ WITHIN ( n lo hi -- flag ) true if lo <= n < hi
\------------------------------------------------------------------------------
: within
    over - >R
    - r>
    u<
;

\------------------------------------------------------------------------------
\ D0= ( ud_lo ud_hi -- flag ) true if double is zero
\ https://forth-standard.org/standard/double/DZeroEqual
\------------------------------------------------------------------------------
: d0=
    or
    0=
;

\------------------------------------------------------------------------------
\ D0< ( ud_lo ud_hi -- flag ) true if double is negative
\ https://forth-standard.org/standard/double/DZeroless
\------------------------------------------------------------------------------
: d0<
    nip
    0<
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

\------------------------------------------------------------------------------
\ MIN-INT ( -- n ) pushes lowest single precision integer
\------------------------------------------------------------------------------
: min-int
    INT_MIN
;

\------------------------------------------------------------------------------
\ MAX-INT ( -- n ) pushes highest single precision integer
\------------------------------------------------------------------------------
: max-int
    INT_MAX
;

\------------------------------------------------------------------------------
\ MIN-2INT ( -- d ) pushes lowest single precision integer
\------------------------------------------------------------------------------
: min-2int
    0 min-int      \ Sign bit only
;

\------------------------------------------------------------------------------
\ MAX-2INT ( -- d ) pushes highest single precision integer
\------------------------------------------------------------------------------
: max-2int
    UINT_MAX       \ UINT_MAX has all bits set.
    INT_MAX        \ Sign bit clear, all other bits set.
;

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

\------------------------------------------------------------------------------
\ */MOD ( n1 n2 n3 -- n4 n5 ) Multiply n1 by n2 producing the intermediate
\ double-cell result d. Divide d by n3 producing the single-cell remainder n4
\ and the single-cell quotient n5. An ambiguous condition exists if n3 is zero,
\ or if the quotient n5 lies outside the range of a single-cell signed integer.
\ If d and n3 differ in sign, the implementation-defined result returned will
\ be the same as that returned by either the phrase >R M* R> FM/MOD or the
\ phrase >R M* R>
\ https://forth-standard.org/standard/core/TimesDivMOD
\------------------------------------------------------------------------------
: */mod
    >r                              ( n1 n2 ) \ R: ( n3 )
    m*                              ( d ) \ 32-bit result
    r>                              ( d n3 )
    sm/rem                          ( rem quot )
;

\------------------------------------------------------------------------------
\ */ ( n1 n2 n3 -- n4 ) Multiply n1 by n2 producing the intermediate
\ double-cell result d. Divide d by n3 giving the single-cell quotient n4.
\ An ambiguous condition exists if n3 is zero or if the quotient n4 lies
\ outside the range of a signed number.
\ https://forth-standard.org/standard/core/TimesDiv
\------------------------------------------------------------------------------
: */
    */mod                           ( rem quot )
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

\------------------------------------------------------------------------------
\ M+ ( d n -- d ) add single to double, sign extending n first
\------------------------------------------------------------------------------
: m+
    s>d               \ sign extend n to double
    d+                \ add to d
;

\------------------------------------------------------------------------------
\ M* ( n1 n2 -- d ) d is the signed product of n1 times n2.
\ https://forth-standard.org/standard/core/MTimes
\------------------------------------------------------------------------------
: m*
    2dup                      ( n1 n2 n1 n2 )
    xor                       ( n1 n2 xor ) \ sign of result
    >r                        \ R: ( sign )
    abs                       ( n1 |n2| )
    swap                      ( |n2| n1 )
    abs                       ( |n2| |n1| )
    um*                       ( ud ) \ unsigned 32-bit result
    r>                        ( ud sign )
    0<                        ( ud flag ) \ true if result negative
    if
        dnegate               \ negate if signs differed
    then
;

\------------------------------------------------------------------------------
\ m*/ ( d1 n1 +n2 -- d2 ) Multiply d1 by n1 producing the 3-cell intermediate
\ result t. Divide t by +n2 giving the double-cell quotient d2. An ambiguous
\ condition exists if +n2 is zero or negative, or the quotient lies outside of
\ the range of a double-precision signed integer.
\ https://forth-standard.org/standard/double/MTimesDiv
\------------------------------------------------------------------------------
: m*/
    >r s>d >r abs -rot s>d r> xor r> swap >r >r dabs rot tuck
    um*
    2swap um* swap >r 0 d+ r> -rot i um/mod -rot r>
    um/mod
    -rot r>
    if
        if
	    1 0 d+
        then
        dnegate
    else
        drop
    then
;

\------------------------------------------------------------------------------
\ D2* ( d -- d*2 ) double shift left.
\ https://forth-standard.org/standard/double/DTwoTimes
\------------------------------------------------------------------------------
: d2*
    2dup
    d+
;

\------------------------------------------------------------------------------
\ D2/ ( d -- d/2 ) double arithmetic right shift.
\ https://forth-standard.org/standard/double/DTwoDiv
\------------------------------------------------------------------------------
: d2/
    dup
    1 and
    15 lshift
    >r
    2/
    swap
    2/
    r>
    or
    swap
;

\------------------------------------------------------------------------------
\ D>S ( d -- n ) truncate double to single, discard high cell
\------------------------------------------------------------------------------
: d>s
    drop
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

\------------------------------------------------------------------------------
\ ALIGNED ( addr -- a-addr ) a-addr is the first aligned address greater than
\ or equal to addr.
\ https://forth-standard.org/standard/core/ALIGNED
\------------------------------------------------------------------------------
: aligned
    1+
    uint_max 1-
    and
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

\------------------------------------------------------------------------------
\ ERASE ( addr u -- ) fill u bytes starting at addr with zero
\------------------------------------------------------------------------------
: erase
    0 fill
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
