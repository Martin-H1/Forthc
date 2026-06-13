.main const-main

2           constant two
two 3 *     constant six
6 two /     constant three-b
1 cell 8 * 3 - lshift constant rescale
rescale 3 * constant three-rescaled
rescale 4 * constant four-rescaled

: const-main
  const-expr-test
  const-cmd-test
;

: const-expr-test
    cr ." constant expression test" cr
    ." two (expect 2)              = " two . cr
    ." six (expect 6)              = " six . cr
    ." three-b (expect 3)          = " three-b . cr
    ." rescale (expect 8192/$2000) = " rescale . cr
    ." three-rescaled (expect 24576/$6000) = " three-rescaled . cr
    ." four-rescaled (expect 32768/$8000)  = " four-rescaled . cr
;

\ These should give same result as the hardcoded versions
1 cell 8 * 3 - lshift constant rescale-b
rescale rescale-b = constant rescale-match

: const-cmd-test
    cr ." --const test" cr
    ." rescale-match (expect -1/true) = " rescale-match . cr
;
