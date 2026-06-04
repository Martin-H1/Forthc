\ math.f - Arithmetic regression tests

.main main

: base-test
    base @ ." base @ u. (expect 10) = " u. cr
    16 base ! 255 ." 16 base ! 255 u. (expect FF) = " u. cr
    10 base ! 255 ." 10 base ! 255 u. (expect 255) = " u. cr
;

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
    597 4133 + ." 597 + 4133 (expect 4730) = " . cr
;

: minus-test
    4133 597 - ." 4133 - 597 (expect 3536) = " . cr
;

: star-test
    4133 7 *   ." 4133 * 7 (expect 28931) = " . cr
    4133 -3 *  ." 4133 * -3 (expect -12399) = " . cr
    -3 -3 *    ." -3 * -3 (expect 9) = " . cr
    -3 20 *    ." -3 * 20 (expect -60) = " . cr
;

: umstar-test
    4133  20    um* ." 4133 20 um* (expect 17124 1) = " swap u. u. cr
    4133  65533 um* ." 4133 65533 um* (expect 53137 4132) = " swap u. u. cr
    65533 65533 um* ." 65533 65533 um* (expect 9 65530) = " swap u. u. cr
    65533 20    um* ." 65533 20 um* (expect 65476 19) = " swap u. u. cr
;

: umslashmod-test
    1025 0 14 um/mod ." 1025 0 14 um/mod (expect 3 73) = " swap u. u. cr
    1025 0 0  um/mod ." 1025 0 0 um/mod (expect 1025 -1) = " swap u. . cr
;

: slashmod-test
    4133 20 /MOD ." 4133 20 /MOD (expect 13 206) = " swap . . cr
    4133 -3 /MOD ." 4133 -3 /MOD (expect -1 -1378) = " swap . . cr
    -3 -3 /MOD   ." -3 -3 /MOD  (expect 0 1) = " swap . . cr
    -3 20 /MOD   ." -3 20 /MOD (expect 17 -1) = " swap . . cr
;

: slash-test
    4133 20 /    ." 4133 / 20 (expect 206) = " . cr
    4133 -3 /    ." 4133 / -3 (expect -1378) = " . cr
    -3 -3 /      ." -3 / -3 (expect 1) = " . cr
    -3 20 /      ." -3 20 / (expect -1) = " . cr
    -3  1 /      ." -3 1 / (expect -3) = " . cr
;

: mod-test
     4133 20 MOD ." 4133 20 MOD (expect 13) = " . cr
     4133 -3 MOD ." 4133 -3 MOD (expect -1) = " . cr
     -3 -3 MOD   ." -3 -3 MOD (expect 0) = " . cr
     -3 20 MOD   ." -3 20 MOD (expect 17) = " . cr
;

: main
    cr
    base-test
    urinary-test
    plus-test
    minus-test
    star-test
    umstar-test
    umslashmod-test
    slashmod-test
    slash-test
    mod-test
;
