\ double.fs - Double number regression tests

.include "core.inc"

.main double-test

: double-test
    cr ." double test enter" cr
    twostorefetch-test
    twoswap-test
    twoover-test
    tworot-test
    stod-test
    dplus-test
    dminus-test
    dabs-test
    dtwostar-test
    dtwoslash-test
    dtos-test
    dneg-test
    deq-test
    dzeq-test
    dzlt-test
    dult-test
    dlt-test
    dmax-test
    dmin-test
    ." double test exit" cr
;

create dcell 4 allot

: twostorefetch-test
    1 2 dcell  2!
    dcell 2@ ." 2! D@ (expect 1 2) = " .s clear cr
;

: twoswap-test
    1 2 3 4 2swap ." 1 2 3 4 2swap expect (3 4 1 2) = " .s cr clear
;

: twoover-test
    1 2 3 4 2over ." 1 2 3 4 2over expect (1 2 3 4 1 2) = " .s cr clear
;

: tworot-test
    1 2 3 4 5 6 2rot ." 1 2 3 4 5 6 2rot (expect 3 4 5 6 1 2) = " .s cr clear
;

: stod-test
    1234 S>D ." 1234 S>D (expect 1234 0) = " .s cr clear
    -1 S>D ." -1 S>D (expect -1 -1) = " .s cr clear
;

: dplus-test
         1  0      2 0 D+ ." 1. 2. D+ (expect 3 0) = " swap . . cr
        -1 -1      1 0 D+ ." -1. 1. D+ (expect 0 0 = " . . cr
    -31072  1 -31072 1 D+ ." 100000. 100000. D+ (expect 3392 3) = " swap . . cr
;

: dminus-test
    3 0 2 0 d- ." 3. 2. D- (expect 1 0) = " swap . . cr
    0 0 1 0 d- ." 3. 1. D- (expect -1 -1) = " . . cr
;

: dabs-test
    -1 -1 DABS ." -1. DABS (expect 1 0) = " swap . . cr
     1  0 DABS ."  1. DABS (expect 1 0) = " swap . . cr
;

: dtwostar-test
    4 4 d2* ." 4 4 d2* expect (8 8) = " .s cr clear
;

: dtwoslash-test
    4 4 d2/ ." 4 4 d2/ expect (2 2) = " .s cr clear
;

: dtos-test
    1234 0 D>S ." 1234 0 D>S (expect 1234) = " .s cr clear
;

: dneg-test
     1  0 DNEGATE ." 1. DNEGATE (expect -1 -1) = " . . cr
    -1 -1 DNEGATE ." -1. DNEGATE (expect 1 0) = " swap . . cr
     0  0 DNEGATE ." 0. DNEGATE (expect 0 0) = " . . cr
;

: deq-test
    1 0 1 0 D= ." 1. 1. D= (expect -1) = " . cr
    1 0 2 0 D= ." 1. 2. D= (expect 0) = " . cr
    -31072  1 -31072 1  D= ." 100000. 100000. D= (expect -1) = " . cr
;

: dzeq-test
    0 0 D0= ." 0 0 D0= (expect -1) = " . cr
    1 0 D0= ." 1 0 D0= (expect 0) = " . cr
    0 1 D0= ." 0 1 D0= (expect 0) = " . cr
;

: dzlt-test
    0 0 D0< ." 0. D0< (expect 0) = " . cr
    1 0 D0< ." 1. D0< (expect 0) = " . cr
    -1 -1 D0< ." -1. D0< (exxpect -1) = " . cr
;

: dult-test
    1 0 2 0 DU< ." 1. 2. DU< (expect -1) = " . cr
    2 0 1 0 DU< ." 2. 1. DU< (expect 0) = " . cr
;

: dlt-test
    1 0 2 0 D< ." 1. 2. D< (expect -1) = " . cr
    2 0 1 0 D< ." 2. 1. D< (expect 0) = " . cr
    -1 -1 0 0 D< ." -1. 0. D< (expect -1) = " . cr
;

: dmax-test
    1 0 2 0 DMAX ." 1. 2. DMAX (expect 2 0) = " .s cr clear
    1 0 0 0 DMAX ." 1. 0. DMAX (expect 1 0) = " .s cr clear
    1 0 -1 -1 DMAX ." 1. -1. DMAX (expect 1 0) = " .s cr clear
;

: dmin-test
    1 0 2 0 DMIN ." 1. 2. DMIN (expect 1 0) = " .s cr clear
    1 0 0 0 DMIN ." 1. 0. DMIN (expect 0 0) = " .s cr clear
    1 0 -1 -1 DMIN ." 1. -1. DMIN (expect -1 -1) = " .s cr clear
;
