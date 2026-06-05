\ memory.fs - memory access regresssion tests

.main test-memory

create buf 32 allot

variable foo

: test-memory
    cr ." memory test: " cr
    test-move
    test-fill
    test-store-fetch
    ." done"
    cr
;

: test-move
    S" This text was moved!" dup >r buf swap move
    buf r> type cr
;

: test-fill
    buf 10 44 fill
    ." '" buf 10 type ." '" cr
;

: test-store-fetch
    25 foo ! foo @ . cr
;