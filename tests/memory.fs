\ memory.fs - memory access regresssion tests

.include "core.inc"

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
    test-does
    test-struct
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

: array      ( n -- ) create cells allot does> swap cells + ;
: byte-array ( n -- ) create allot       does> swap + ;

10 array      my-array
20 byte-array my-bytes

: test-does
    cr ." does> test" cr
    \ verify element spacing
    ." my-array[1] - my-array[0] (expect 2) = "
    1 my-array 0 my-array - . cr
    ." my-array[3] - my-array[0] (expect 6) = "
    3 my-array 0 my-array - . cr
    ." my-bytes[3] - my-bytes[0] (expect 3) = "
    3 my-bytes 0 my-bytes - . cr
    ." my-bytes[5] - my-bytes[0] (expect 5) = "
    5 my-bytes 0 my-bytes - . cr
    \ store and fetch
    42 3 my-array !
    ." my-array[3] value (expect 42) = " 3 my-array @ . cr
    65 5 my-bytes c!
    ." my-bytes[5] value (expect 65) = " 5 my-bytes c@ . cr
;

\ struct tests
.struct point
    .field x cell
    .field y cell
.end-struct

.struct rgb
    .field red   1
    .field green 1
    .field blue  1
.end-struct

.struct header
    .field previous cell
    .field flags    1
    .field namelen  1
    .field cfa      cell
    .field name     ?
.end-struct

create origin  point  0 , 0 ,
create red-color rgb  255 c, 0 c, 0 c,
create greeting header  0 , 0 c, 5 c, 0 , Z" hello"

: test-struct
    cr ." struct test" cr
    ." point_x_sizeof (expect 0)  = " point_x . cr
    ." point_y (expect 2)         = " point_y . cr
    ." point_sizeof (expect 4)    = " point_sizeof . cr
    ." rgb_sizeof (expect 3)      = " rgb_sizeof . cr
    ." header_fixed_sizeof (expect 6) = " header_fixed_sizeof . cr
    ." origin x (expect 0)  = " origin point_x + @ . cr
    ." origin y (expect 0)  = " origin point_y + @ . cr
    ." red-color red (expect 255) = " red-color rgb_red + c@ . cr
    ." greeting namelen (expect 5) = " greeting header_namelen + c@ . cr
    ." greeting name (expect hello) = " greeting header_name + cputs cr
;
