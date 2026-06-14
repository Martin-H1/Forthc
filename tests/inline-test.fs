.main inline-test

: double ( n -- n*2 ) 2* ;
.inline double

: triple ( n -- n*3 ) dup 2* + ;
.inline triple

\ This should be rejected - contains >r
: unsafe ( n -- n ) >r r> ;
\ .inline unsafe   \ would cause compile error

: peephole 1 + 2 * ;

: inline-test
    cr ." inline test" cr
    ." 5 double (expect 10) = " 5 double . cr
    ." 5 triple (expect 15) = " 5 triple . cr
;
