\ Example Forth program: fibonacci sequence
\ Demonstrates constants, word definitions, if/then, begin/until
.main print-fibs

15 constant max-fib

: fib ( n -- fib(n) )
    dup 2 < if
        drop 1
    else
        1 - >r          \ save iteration count on R
        1 1             \ seed: a=1 b=1
        begin
            swap over + \ a b → b (a+b)
            r> 1 -      \ decrement count
            dup >r      \ save updated count back to R
            0=          \ done when count reaches 0
        until
        r> drop         \ discard count
        nip             \ discard a, return b
    then
;

: print-fibs ( -- )
    1
    begin
        dup . ." : " dup fib . cr
        1 +
        dup max-fib >
    until
    drop
;
