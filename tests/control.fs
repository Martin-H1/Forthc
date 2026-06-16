\ control.fs - control structures regression tests

.include "core.inc"

.main control-test

: control-test
    ." Control structures test enter" cr
    0 if-test
    1 if-test
    0 if-else-test
    1 if-else-test
    do-loop-test
    begin-until-test
    begin-while-test
    plusloop-test
    recurse-test
    ." Control structures test exit" cr
;

: if-test
    .s if ." if taken" then cr
;

: if-else-test
    .s if ." if taken" else ." else taken" then cr
;

: do-loop-test
    10 0 do i . loop cr
;

: begin-until-test
    10 begin
        dup .
        1 -
        dup 0 =
    until
    drop cr
;

: begin-while-test
    ." begin-while test" cr
    0 begin
        dup -10 > while
        1- dup .
    repeat
    cr ." done" cr
;

: plusloop-test
    cr ." +loop test" cr
    \ Basic positive step
    ." Count by 2 (expect 0 2 4 6 8) = "
    10 0 do i . 2 +loop cr

    \ Step larger than 1 that divides evenly
    ." Count by 3 (expect 0 3 6 9) = "
    12 0 do i . 3 +loop cr

    \ Step of 1 should behave like regular loop
    ." Count by 1 (expect 0 1 2 3 4) = "
    5 0 do i . 1 +loop cr

    \ Non-zero start index
    ." 5 to 9 by 2 (expect 5 7 9) = "
    11 5 do i . 2 +loop cr

    \ negative to positive loop
    ." -62 to 64 by 8 = "
    64 -62 do i . 8 +loop cr
;

: factorial ( n -- n! )
    dup 1 > if
        dup 1 - recurse *
    else
        drop 1
    then
;

: recurse-test
    cr ." recurse test" cr
    ." 1 factorial (expect 1)   = " 1 factorial . cr
    ." 5 factorial (expect 120) = " 5 factorial . cr
    ." 7 factorial (expect 5040) = " 7 factorial . cr
;
