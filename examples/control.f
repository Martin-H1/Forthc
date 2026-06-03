.main control-test

: control-test
    ." Control structures test enter" cr
    0 if-test
    1 if-test
    0 if-else-test
    1 if-else-test
    do-loop-test
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
