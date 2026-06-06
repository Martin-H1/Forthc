\ This is a test of the compiler's ability to handle the .export directive.
.export square
.export cube

: square ( n -- n^2 ) dup * ;
: cube   ( n -- n^3 ) dup dup * * ;
: main  cr 5 square . cr  3 cube . cr ;

.main main
