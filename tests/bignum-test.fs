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

    \ s>bn and bn.
    0 test-bn s>bn
    ." 0 = " test-bn bn. cr

    1 test-bn s>bn
    ." 1 = " test-bn bn. cr

    9999 test-bn s>bn
    ." 9999 = " test-bn bn. cr

    10000 test-bn s>bn
    ." 10000 = " test-bn bn. cr

    \ bn0=
    0 test-bn s>bn
    ." 0 is zero (expect true/-1) = " test-bn bn0= . cr

    1 test-bn s>bn
    ." 1 is zero (expect false/0) = " test-bn bn0= . cr
;

: div-debug
    ." Starting div-debug" cr
    9999 test-bn s>bn
    ." s>bn done" cr
    BN-BASE test-bn bn*
    ." bn* done" cr
    ." Value = " test-bn bn. cr
    ." Calling bn/rem with n=10000" cr
    BN-BASE test-bn bn/rem
    ." bn/rem done rem = " . cr
    ." quot = " test-bn bn. cr
;

: phase2-test
    cr ." Phase 2: arithmetic" cr

    \ bn*
    1 test-bn s>bn
    10 test-bn bn*
    ." 1*10 (expect 10) = " test-bn bn. cr

    1234 test-bn s>bn
    10 test-bn bn*
    ." 1234*10 (expect 12340) = " test-bn bn. cr

    1 test-bn s>bn
    BN-BASE test-bn bn*
    ." 1*10000 (expect 10000) = " test-bn bn. cr

    9999 test-bn s>bn
    BN-BASE test-bn bn*
    ." 9999*10000 (expect 99990000) = " test-bn bn. cr

    \ bn/rem
    12340 test-bn s>bn
    10 test-bn bn/rem
    ." 12340/10 rem (expect 0) = " . cr
    ." 12340/10 quot (expect 1234) = " test-bn bn. cr

    10000 test-bn s>bn
    BN-BASE test-bn bn/rem
    ." 10000/10000 rem (expect 0) = " . cr
    ." 10000/10000 quot (expect 1) = " test-bn bn. cr

    \ carry across cell boundary
    1 test-bn s>bn
    BN-BASE test-bn bn*
    ." 1*10000 stored in cell 1 (expect 10000) = " test-bn bn. cr

    \ bn+
    1 test-bn s>bn
    1 test-bn2 s>bn
    test-bn test-bn2 bn+
    ." 1+1 (expect 2) = " test-bn2 bn. cr

    9999 test-bn s>bn
    1 test-bn2 s>bn
    test-bn test-bn2 bn+
    ." 9999+1 (expect 10000) = " test-bn2 bn. cr

    \ bn-
    1 test-bn s>bn
    10000 test-bn2 s>bn
    test-bn test-bn2 bn-
    ." 10000-1 (expect 9999) = " test-bn2 bn. cr

    \ borrow across cell boundary
    0 test-bn s>bn              \ 10000 stored as cell1=1, cell0=0
    BN-BASE test-bn bn*         \ now test-bn = 10000
    1 test-bn2 s>bn
    test-bn2 test-bn bn-        \ test-bn -= test-bn2 = 10000 - 1 = 9999
    ." 10000-1 with borrow (expect 9999) = " test-bn bn. cr
;

: bignum-main
  phase1-test
  phase2-test
;
