\ Example Forth program: fibonacci and string output
\ Demonstrates constants, word definitions, if/then, begin/until

.main print-fibs

15 constant max-fib

\ Fibonacci — iterative version
\ ( n -- fib(n) )
: fib
    dup 2 < if
        drop 1
    else
        0 1            \ a=0, b=1
        rot            \ n a b  →  reorder: b a n
        swap           \ n b a   hmm; let's keep it simple
        drop           \ discard
        \ Actually use begin/until loop:
        1              \ counter
        begin
            over over + \ a b  →  a b (a+b)
            rot drop    \ b (a+b)
            swap        \ (a+b) b
            over        \ (a+b) b (a+b)
            drop        \ (a+b) b
            swap        \ b (a+b)
        over max-fib = until
        drop
    then
;

\ Print all fibonacci numbers up to max-fib
: print-fibs
    1
    begin
        dup fib .
        cr
        1 +
        dup max-fib >
    until
    drop
;
