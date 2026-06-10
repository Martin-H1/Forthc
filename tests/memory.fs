\ memory.fs - memory access regresssion tests

.main test-memory

create buf 32 allot

variable foo

: test-memory
    cr ." memory test: " cr
    test-move
    test-fill
    test-store-fetch
    test-table
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

create sine-table
    0 , 707 , 1000 , 707 , 0 , -707 , -1000 , -707 ,

create rgb-black  0 , 0 , 0 ,
create rgb-white  255 , 255 , 255 ,

: test-table
    cr ." test table" cr
    ." sine-table[0] (expect 0)     = " sine-table @ . cr
    ." sine-table[2] (expect 1000)  = " sine-table 2 cells + @ . cr
    ." sine-table[5] (expect -707)  = " sine-table 5 cells + @ . cr
    ." rgb-white red (expect 255)   = " rgb-white @ . cr
;
