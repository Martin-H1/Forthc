\ math.f - Arithmetic regression tests

.main main

: plus-test 597 4133 + . cr ;

: minus-test 4133 597 - . cr ;

: star-test
   4133 7 * . cr
  4133 -3 * . cr
    -3 -3 * . cr
    -3 20 * . cr
;

: slash-test
   4133 20 / . cr
   4133 -3 / . cr
     -3 -3 / . cr
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
    plus-test
    minus-test
    star-test
    slash-test
    mod-test
    slashmod-test
;
