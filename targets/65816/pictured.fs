.export ud/mod
.export <#
.export hold
.export holds
.export #
.export #s
.export sign
.export #>
.export .r
.export u.r
.export d.r
.export d.

\------------------------------------------------------------------------------
\ UD/MOD ( d-low d-high u -- rem quot-low quot-high ) non-standard helper for
\ pictured I/O. Used to divide a double by a base to get a digit to print and
\ the next quotient to divide.
\------------------------------------------------------------------------------
: ud/mod ( d-low d-high u -- rem quot-low quot-high )
    >r 0 r@ um/mod r> swap >r um/mod r>
;

\------------------------------------------------------------------------------
\ <# ( -- ) Initialize the pictured numeric output conversion process.
\ https://forth-standard.org/standard/core/num-start
\------------------------------------------------------------------------------
: <# ( -- )
    pad-end hld !
;

\------------------------------------------------------------------------------
\ HOLD ( char -- ) insert char into pictured numeric output string
\ https://forth-standard.org/standard/core/HOLD
\------------------------------------------------------------------------------
: hold ( char -- )
    hld @ 1- dup hld ! c!
;

\------------------------------------------------------------------------------
\ HOLDS ( c-addr u -- )
\ https://forth-standard.org/standard/core/HOLDS
\------------------------------------------------------------------------------
: holds ( c-addr u -- )
    begin dup while
        1- 2dup + c@ hold
    repeat
    2drop
;

\------------------------------------------------------------------------------
\ # ( ud -- ud ) format one digit
\------------------------------------------------------------------------------
: # ( ud -- ud )
    base @ ud/mod rot
    dup 9 > if 7 + then
    48 +
    hold
;

\------------------------------------------------------------------------------
\ #S ( ud -- 0 0 ) format all digits
\------------------------------------------------------------------------------
: #s ( ud -- 0 0 )
    begin # 2dup or 0= until
;

\------------------------------------------------------------------------------
\ SIGN ( n -- ) if n negative prepend minus sign
\------------------------------------------------------------------------------
: sign ( n -- )
    0< if 45 hold then
;

\------------------------------------------------------------------------------
\ #> ( ud -- c-addr u ) finalize pictured numeric output
\------------------------------------------------------------------------------
: #> ( ud -- c-addr u )
    2drop hld @ pad-end over -
;

\------------------------------------------------------------------------------
\ .R ( n1 n2 -- ) Display n1 right aligned in a field n2 characters wide. If
\ the number of characters required to display n1 is greater than n2, all
\ digits are displayed with no leading spaces in a field as wide as necessary.
\ https://forth-standard.org/standard/core/DotR
\------------------------------------------------------------------------------
: .r ( n1 n2 -- )
    swap dup >r abs 0 <# #s r> sign #> rot over - 0 max spaces type
;

\------------------------------------------------------------------------------
\ U.R ( u n -- ) Display u right aligned in a field n characters wide. If the
\ number of characters required to display u is greater than n, all digits are
\ displayed with no leading spaces in a field as wide as necessary.
\ https://forth-standard.org/standard/core/UDotR
\------------------------------------------------------------------------------
: u.r ( u n -- )
    >r 0 <# #s #> r> over - 0 max spaces type
;

\------------------------------------------------------------------------------
\ D.R ( d n -- ) Display d right aligned in a field n characters wide. If the
\ number of characters required to display d is greater than n, all digits are
\ displayed with no leading spaces in a field as wide as necessary.
\ https://forth-standard.org/standard/double/DDotR
\------------------------------------------------------------------------------
: d.r ( d n -- )
    >r tuck dabs <# #s rot sign #> r> over - 0 max spaces type
;

\------------------------------------------------------------------------------
\ D. ( d_lo d_hi -- ) print signed 32-bit double followed by space
\------------------------------------------------------------------------------
: d. ( d -- )
    0 d.r space
;
