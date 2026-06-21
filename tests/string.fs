\ string.fs - text regression tests

.include "core.inc"

.main string-test

\ A string.f test file covering s", .", type, count

create buf 20 allot

: string-test
    cr ." String test enter." cr

    S" Test of an s-quote string and type!" .s space type cr

    \ create a length prefixed string
    10 buf c! s" 1234567890" buf 1+ swap move

    \ Use count to convert it to addr+1 len
    ." buf dup count (expect addr addr+1 len and 1234567890) = " cr
    buf dup count .s type cr clear \ clear discards original buf addr

    ." String test exit." cr
;
