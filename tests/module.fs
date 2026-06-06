.export square
.export cube

: square ( n -- n^2 ) dup * ;
: cube   ( n -- n^3 ) dup dup * * ;
: main   5 square . cr  3 cube . cr ;
.main main
