\ math.f - Arithmetic regression tests

.main main

: urinary-test
      0 invert ." 0 invert (expect -1) = " . cr
     11 1+     ." 11 1+ (expect 12) = "    . cr
     10 1-     ." 10 1- (expect 9) = "     . cr
     24 2*     ." 24 2* (expect 48) = "    . cr
    -24 2*     ." -24 2* (expect -48) = "  . cr
     24 2/     ." 24 2/ (expect 12) = "    . cr
    -24 2/     ." -24 2/ (expect -12) = "  . cr
;

: plus-test
    ." 597 + 4133 (expect 4730) = "
    597  4133 + . cr
;

: minus-test
    ." 4133 - 597 (expect 3536) = "
    4133 597 - . cr
;

: star-test
    ." 4133 * 7 (expect 28931) = " 4133 7 * . cr
    ." 4133 * -3 (expect -12399) = " 4133 -3 * . cr
    ." -3 * -3 (expect 9) = " -3 -3 * . cr
    ." -3 * 20 (expect -60) = " -3 20 * . cr
;

: slash-test
   ." 4133 / 20 (expect 206) = " 4133 20 / . cr
   ." 4133 / -3 (expect -1377) = " 4133 -3 / . cr
   ." -3 / -3 (expect 1) = "  -3 -3 / . cr
     -3 20 / . cr
     -3  1 / . cr
;

: mod-test
   4133 20 MOD . cr
   4133 -3 MOD . cr
     -3 -3 MOD . cr
     -3 20 MOD . cr
;

: slashmod-test
   4133 20 /MOD . cr
   4133 -3 /MOD . cr
     -3 -3 /MOD . cr
     -3 20 /MOD . cr
;

: main
    cr
    urinary-test
    plus-test
    minus-test
    star-test
    slash-test
    mod-test
    slashmod-test
;
