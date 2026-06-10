\ examples/basic.f

.main main

15 constant foo

: multiply-demo
    2 3 *
;

: show-foo
    foo .
    cr
;

: countdown   ( n -- )
    begin
        dup .
        cr
        1 -
        dup 0 =
    until
    drop
;

variable counter

: increment-counter
    counter @
    1 +
    counter !
;

: reset-counter
    0 counter !
;

: get-counter  ( -- n )
    counter @
;

: say-hello
    ." Hello, World!"
    cr
;

: main
    say-hello
    5 countdown
    show-foo
;
