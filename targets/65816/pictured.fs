.define __pictured_fs__

.export ud/mod
.export <#
.export hold
.export holds
.export #
.export #s
.export sign
.export #>
.export .r
.export u.r
.export d.r
.export d.

: ud/mod ( d-low d-high u -- rem quot-low quot-high )
    >r 0 r@ um/mod r> swap >r um/mod r>
;

: <# ( -- )
    pad-end hld !
;

: hold ( char -- )
    hld @ 1- dup hld ! c!
;

: holds ( c-addr u -- )
    begin dup while
        1- 2dup + c@ hold
    repeat
    2drop
;

: # ( ud -- ud )
    base @ ud/mod rot
    dup 9 > if 7 + then
    48 +
    hold
;

: #s ( ud -- 0 0 )
    begin # 2dup or 0= until
;

: sign ( n -- )
    0< if 45 hold then
;

: #> ( ud -- c-addr u )
    2drop hld @ pad-end over -
;

: .r ( n1 n2 -- )
    swap dup >r abs 0 <# #s r> sign #> rot over - spaces type
;

: u.r ( u n -- )
    >r 0 <# #s #> r> over - spaces type
;

: d.r ( d n -- )
    >r tuck dabs <# #s rot sign #> r> over - spaces type
;

: d. ( d -- )
    0 d.r space
;
