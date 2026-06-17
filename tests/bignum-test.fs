\ bignum-test.fs

.include "bignum.inc"

.main bignum-main

\ Local copies of bignum constants - needed until cross-module constants
10000  constant BN-BASE
125    constant BN-CELLS
130    constant BN-SIZE

\ Use create directly instead of bignum defining word
\ create test-bn  BN-SIZE cells allot
\ create test-bn2 BN-SIZE cells allot
create test-bn  260 allot
create test-bn2 260 allot

: phase1-test
    cr ." Phase 1: basic operations" cr

    \ bn-small and bn-print
    0 test-bn bn-small
    ." 0 = " test-bn bn-print cr

    1 test-bn bn-small
    ." 1 = " test-bn bn-print cr

    9999 test-bn bn-small
    ." 9999 = " test-bn bn-print cr

    10000 test-bn bn-small
    ." 10000 = " test-bn bn-print cr

    \ bn-zero?
    0 test-bn bn-small
    ." 0 is zero (expect true/-1) = " test-bn bn-zero? . cr

    1 test-bn bn-small
    ." 1 is zero (expect false/0) = " test-bn bn-zero? . cr
;

: div-debug
    ." Starting div-debug" cr
    9999 test-bn bn-small
    ." bn-small done" cr
    BN-BASE test-bn bn-mul
    ." bn-mul done" cr
    ." Value = " test-bn bn-print cr
    ." Calling bn-div with n=10000" cr
    BN-BASE test-bn bn-div
    ." bn-div done rem = " . cr
    ." quot = " test-bn bn-print cr
;

: phase2-test
    cr ." Phase 2: arithmetic" cr

    \ bn-mul
    1 test-bn bn-small
    10 test-bn bn-mul
    ." 1*10 (expect 10) = " test-bn bn-print cr

    1234 test-bn bn-small
    10 test-bn bn-mul
    ." 1234*10 (expect 12340) = " test-bn bn-print cr

    1 test-bn bn-small
    BN-BASE test-bn bn-mul
    ." 1*10000 (expect 10000) = " test-bn bn-print cr

    9999 test-bn bn-small
    BN-BASE test-bn bn-mul
    ." 9999*10000 (expect 99990000) = " test-bn bn-print cr

    \ bn-div
    12340 test-bn bn-small
    10 test-bn bn-div
    ." 12340/10 rem (expect 0) = " . cr
    ." 12340/10 quot (expect 1234) = " test-bn bn-print cr

    10000 test-bn bn-small
    BN-BASE test-bn bn-div
    ." 10000/10000 rem (expect 0) = " . cr
    ." 10000/10000 quot (expect 1) = " test-bn bn-print cr

    \ carry across cell boundary
    1 test-bn bn-small
    BN-BASE test-bn bn-mul
    ." 1*10000 stored in cell 1 (expect 10000) = " test-bn bn-print cr

    \ bn-add
    1 test-bn bn-small
    1 test-bn2 bn-small
    test-bn test-bn2 bn-add
    ." 1+1 (expect 2) = " test-bn2 bn-print cr

    9999 test-bn bn-small
    1 test-bn2 bn-small
    test-bn test-bn2 bn-add
    ." 9999+1 (expect 10000) = " test-bn2 bn-print cr

    \ bn-sub
    1 test-bn bn-small
    10000 test-bn2 bn-small
    test-bn test-bn2 bn-sub
    ." 10000-1 (expect 9999) = " test-bn2 bn-print cr

    \ borrow across cell boundary
    0 test-bn bn-small          \ 10000 stored as cell1=1, cell0=0
    BN-BASE test-bn bn-mul      \ now test-bn = 10000
    1 test-bn2 bn-small
    test-bn2 test-bn bn-sub     \ test-bn -= test-bn2 = 10000 - 1 = 9999
    ." 10000-1 with borrow (expect 9999) = " test-bn bn-print cr
;

: bignum-main
  phase1-test
  phase2-test
;
