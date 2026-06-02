.main stack-test

: stack-test
    ." Stack test enter" cr
    0 dup ." Dup test (expect 0 0) = " .s cr
    ?dup  ." ?Dup test (expect 0 0) = " .s cr
    drop drop ." Drop test expect empty stack " .s cr
    1 2 3 nip ." Nip test (expect 1 3) = " .s cr
    swap ." Swap test (expect 3 1) = " .s cr
    over ." Over test (expect 3 1 3) = " .s cr
    clear 1 2 2dup ." 2dup test (expect 1 2 1 2) = " .s cr
    2drop ." 2drop test (expect 1 2) = " .s cr
    clear 1 2 tuck ." Tuck test (expect 2 1 2) = " .s cr
    clear 1 2 3 rot ." Rot test (expect 2 3 1) = " .s cr
    clear 1 2 3 -rot ." -Rot test (expect 3 1 2) = " .s cr
    clear 1 2 3 2 pick ." Pick test (expect 1 2 3 1) = " .s cr
    clear 1 2 3 4 5 3 roll ." 3 Roll test (expect 1 3 4 5 2) = " .s cr
    clear 1 >r r> ." >r r> test (expect 1) = " .s cr
    ." Stack test exit" cr
;
