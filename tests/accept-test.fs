\ accept-test.fs

.main accept-main

.segment "BSS"

128 constant tib-size
create tib 128 allot

.segment "CODE"

: accept-main
  tib tib-size accept
;
