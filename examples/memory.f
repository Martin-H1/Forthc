.main test-memory

: test-memory
    cr ." memory test: " cr
    test-move
    test-fill
    ." done"
    cr
;

: test-move
    S" This text was moved!" dup >r $0600 swap move
    $600 r> type cr
;

: test-fill
    $600 10 44 fill
    ." '" $600 10 type ." '" cr
;
