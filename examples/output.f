.main output-test

: output-test
    hello
    test-type
    test-space
    test-spaces
    test-dot
;

: hello
    ." Hello world!"
    cr
;

: test-type
    ." cputs test: "
    S" Hello from TYPE!" type
    cr
    ." done"
    cr
;

: test-space
    ." '" space ." '" cr
;

: test-spaces
    ." '" 10 spaces ." '" cr
;

: test-dot
    ." test-dot" cr
    0 12 - . cr
    0 12 - u. cr
    -12399 .
;
