\ output.fs - output to console regression tests

.include "pictured.inc"

.main output-test

: output-test
    hello
    test-type
    test-space
    test-spaces
    test-dot
    test-dots
    test-pic
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
    -12399 . cr
;

: test-dots
 1 2 3 4 .s cr clear ;

: test-pic
    ." 10 10 10 ud/mod (expect 0 1 1) = " 10 10 10 ud/mod .s cr clear
    ." hld . (expect BSS address) = " hld .hex cr
    ." pad-end <# hld @ - (expect 0) = " pad-end <# hld @ - .  cr
    ." hld @ = " hld @ .hex cr
    ." hld @ 50 hold hld @ - (expect 1) = " hld @ 50 hold hld @ - . cr
    ." hld @ c@ (expect 50) = " hld @ c@ . cr
    ." -31072 1 <# # (expect 10000 0) = " -31072 1 <# # .s cr clear
    ." -31072 1 <# #s #> (expect addr 6) = " -31072 1 <# #s #> .s cr clear

    ." -31072 1 d. (expect addr 6) = " -31072 1 d. cr clear

    1234 0 <# #s #> ." 1234 0 <# #s #> (expect 1234) = " type cr
    -1234 dup >r abs 0 <# #s r> sign #> ." (expect -1234) = " type cr
    ." '" 8 0 10 d.r ." '" cr
;
