\ logic.fs - logical operator regression tests.

.main logic-test

: logic-test
    ." Logic test enter" cr
    1 3 and ." 1 3 And test (expect 1) = " . cr
    1 2 or  ." 1 2 Or test (expect 3) = " . cr
    1 3 xor ." 1 3 Xor test (expect 2) = " . cr
    1 invert ." 1 invert test (expect -2) = " . cr
    -1 2 < ." -1 2 < test (expect -1) = " . cr
    1 -2 > ." 1 -2 > test (expect -1) = " . cr
    1 2 < ." 1 2 < test (expect -1) = " . cr
    1 2 > ." 1 2 > test (expect 0) = " . cr

    32 32 U< ." 32 32 U< (expect 0) = " . cr
    42 32 U< ." 42 32 U< (expect 0) = " . cr
    32 42 U< ." 32 42 U< (expect -1) = " . cr
    32 65534 U< ." -132 65534 U< (expect -1) = " . cr

    32 32 U> ." 32 32 U> (expect 0) = " . cr
    42 32 U> ." -1 42 32 U> (expect -1) = " . cr
    32 42 U> ." 32 42 U> (expect 0) = " . cr
    32 65534 U> ." 32 65534 U> (expect 0) = " . cr

    0 0= ." 0 0= test (expect -1) = " . cr
    1 0= ." 1 0= test (expect 0) = " . cr

    1 0<> ." 1 0<> test (expect -1) = " . cr
    0 0<> ." 0 0<> test (expect 0) = " . cr

    -1 0< ." -1 0< test (expect -1) = " . cr
    1 0<  ." 1 0< test (expect 0) = " . cr
    -1 0> ." -1 0> test (expect 0) = " . cr
    1 0>  ." 1 0> test (expect -1) = " . cr

    1 2 = ." 1 2 = test (expect 0) = " . cr
    2 2 = ." 2 2 = test (expect -1) = " . cr

    32 32 <> ." 32 32 <> (expect 0) = " . cr
    42 32 <> ." 42 32 <> (expect -1) = " . cr

    ." Logic test exit" cr
;
