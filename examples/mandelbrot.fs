.main mandelbrot

\ Setup constants to remove magic numbers to allow
\ for greater zoom with different scale factors.
20    constant MAXITER
-39   constant MINVAL   \ 20 * -1.95
40    constant MAXVAL   \ 20 * 2
$0280 constant RESCALE  \ 20 * 32
$0A00 constant S_ESCAPE \ 20 * 32 * 4

\ These variables hold values during the escape calculation.
variable c-real
variable c-imag
variable z-real
variable z-imag
variable iters

\ Compute squares, but rescale to remove extra scaling factor.
: zr_sq z-real @ dup RESCALE */ ;
.inline zr_sq

: zi_sq z-imag @ dup RESCALE */ ;
.inline zi_sq

\ Translate escape iters to ascii greyscale.
: .CHAR
  s" ..,'~!^:;[/<&?oxOX#   "
  drop + 1
  type ;

\ Numbers above 4 will always escape, so compare to a scaled value.
: escapes? S_ESCAPE > ;
.inline escapes?

\ Increment count and compare to max iterations.
: count_and_test? iters @ 1+ dup iters ! MAXITER > ;
.inline count_and_test?

\ stores the row column values from the stack for the escape calculation.
: init_vars ( i-val r-val -- )
  5 lshift dup c-real ! z-real !	\ 32 * r-val
  5 lshift dup c-imag ! z-imag !	\ 32 * i-val
  1 iters ! ;

\ Performs a single iteration of the escape calculation.
: doescape
    zr_sq zi_sq 2dup +
    escapes? if
      2drop
      true
    else
      - c-real @ +   \ leave result on stack
      z-real @ z-imag @ RESCALE */ 1 lshift
      c-imag @ + z-imag !
      z-real !                   \ Store stack item into ZREAL
      count_and_test?
    then ;

\ Iterates on a single cell to compute its escape factor.
: docell ( i-val r-val -- )
  init_vars
  begin
    doescape
  until
  iters @
  .char ;

\ For each cell in a row.
: dorow ( i-val -- )
  MAXVAL MINVAL do
    dup i docell
  loop
  drop ;

\ For each row in the set.
: mandelbrot
  cr
  MAXVAL MINVAL do
    i dorow cr
  loop ;
