.include "core.inc"
.include "pictured.inc"

.main core-test

: within-test
    cr ." within test" cr
    ." 5 1 10 within (expect -1) = " 5 1 10  within . cr
    ." 1 1 10 within (expect -1) = " 1 1 10  within . cr \ lo boundary inclusive
    ." 10 1 10 within (expect 0) = " 10 1 10 within . cr \ hi boundary exclusive
    ." 0 1 10 within (expect 0) = " 0 1 10   within . cr
    ." 11 1 10 within (expect 0) = " 11 1 10 within . cr

    \ Unsigned wrap-around case - the power of using u
    ." 0 $FF00 $FFFF within (expect 0)  = " 0 $FF00 $FFFF within . cr
    ." $FF80 $FF00 $FFFF within (expect -1) = " $FF80 $FF00 $FFFF within . cr
;

: slashmod-star-test
    cr ." */mod */ test" cr
    ." 10 3 2 */mod (expect 0 15) = " 10 3 2 */mod .s cr clear
    ." 10 3 3 */mod (expect 0 10) = " 10 3 3 */mod .s cr clear
    ." -10 3 2 */mod (expect 0 -15) = " -10 3 2 */mod .s cr clear
    ." 7 2 3 */ (expect 4)  = " 7 2 3 */ .s cr clear
    ." -7 2 3 */ (expect -4) = " -7 2 3 */ .s cr clear
    ." 100 3 7 */ (expect 42) = " 100 3 7 */ .s cr clear
;

: mplus-test
    cr ." m+ test" cr
    ." 5 0 3 m+ (expect 8 0)   = " 5 0 3 m+   d. cr
    ." 5 0 -3 m+ (expect 2 0)  = " 5 0 -3 m+  d. cr
    ." -1 -1 1 m+ (expect 0 0) = " -1 -1 1 m+ d. cr
    ." $7FFF 0 1 m+ (expect $8000 0) = " $7FFF 0 1 m+ d. cr
;

: mstar-test
    clear
    cr ." m* test" cr
    ." 3 4 m* (expect 12)    = " 3 4 m* d. cr
    ." -3 4 m* (expect -12) = " -3 4 m* d. cr
    ." -3 -4 m* (expect 12)  = " -3 -4 m* d. cr
    ." $7FFF $7FFF m* (expect large positive) = " $7FFF $7FFF m* d. cr
    ." $8000 $7FFF m* (expect large negative) = " $8000 $7FFF m* d. cr
;

: mstarslash-test
    cr ." m*/ test" cr
    ." 3 0 4 2 m*/ (expect 6)   = " 3 0 4 2 m*/ d. cr
    ." -3 -1 4 2 m*/ (expect -6) = " -3 -1 4 2 m*/ d. cr
    ." 1000 0 355 113 m*/ (expect approx pi*1000) = " 1000 0 355 113 m*/ d. cr
;

: minmax-test
    cr ." min_int max_int test" cr
    ." min_int (expect $8000) = " min_int .hex cr
    ." max_int (expect $7FFF) = " max_int .hex cr
    ." min_2int (expect -2147483648) = " min_2int d. cr
    ." max_2int (expect 2147483647) = " max_2int d. cr
;

: core-test
    within-test
    slashmod-star-test
    mplus-test
    mstar-test
    mstarslash-test
    minmax-test
;
