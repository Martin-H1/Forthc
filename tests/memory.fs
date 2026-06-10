\ memory.fs - memory access regresssion tests

.main test-memory

create buf 32 allot

variable foo

: test-memory
    cr ." memory test: " cr
    test-move
    test-fill
    test-store-fetch
    test-word-table
    test-byte-table
    test-comma
    test-ccomma
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

: test-word-table
    cr ." test table" cr
    ." sine-table[0] (expect 0)     = " sine-table @ . cr
    ." sine-table[2] (expect 1000)  = " sine-table 2 cells + @ . cr
    ." sine-table[5] (expect -707)  = " sine-table 5 cells + @ . cr
    ." rgb-white red (expect 255)   = " rgb-white @ . cr
;

create vowels
    65 c, 69 c, 73 c, 79 c, 85 c,  \ A E I O U

create msg
    72 c, 101 c, 108 c, 108 c, 111 c, 0 c,  \ Hello\0

: test-byte-table
    cr ." byte table test" cr
    ." vowels[0] (expect 65/A) = " vowels c@ . cr
    ." vowels[2] (expect 73/I) = " vowels 2 + c@ . cr
    ." msg as string (expect Hello) = " msg cputs cr
;

: test-comma
    cr ." test ," cr
    here
    0 , 707 , 1000 , 707 , 0 , -707 , -1000 , -707 ,
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
    dup @ . cell+
;

: test-ccomma
    cr ." test c," cr
    here
    72 c, 101 c, 108 c, 108 c, 111 c, 0 c, cputs cr
;