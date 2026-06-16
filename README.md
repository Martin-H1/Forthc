# forthc — Forth-like to VM-assembly compiler

A compiler for a Forth-like language that targets a portable virtual-machine
instruction set.  The VM instructions are then lowered to native code by a
set of assembler macros (`vmachine.inc`) and a small runtime library
(`vmachine.s`), both of which are target-specific and fully replaceable.

## Architecture

```
source.fs
   │
   ▼  tokenizer.py   (forthc/tokenizer.py)
list[Token]
   │
   ▼  parser.py      (forthc/parser.py)
Program AST           (forthc/ast_nodes.py)
   │
   ▼  codegen.py     (forthc/codegen.py)
source.s  ← VM-instruction assembly text
source.inc← companion import header (if .export directives present)
   │
   ▼  ca65 / target assembler
   │    .include "vmachine.inc"   ← target macro definitions
   │    .include "vmachine.s"     ← runtime routines
   ▼
binary
```

The output of `forthc` is **subroutine-threaded code** with short primitives
inlined directly (no interpreter overhead for `DUP`, `+`, `@`, etc.).

The VM is currently 1437 lines of 65816 assembly and 432 lines of compiled
Forth spread across `vmachine.s`, `core.fs`, and `pictured.fs`.

---

## Compilation pipeline

| Stage | File | Input → Output |
|---|---|---|
| Tokenizer | `forthc/tokenizer.py` | source text → `list[Token]` |
| Parser | `forthc/parser.py` | tokens → `Program` AST |
| Code generator | `forthc/codegen.py` | AST → VM assembly text + optional `.inc` |

---

## Usage

### 1. Compile Forth source to VM assembly

```bash
python __main__.py examples/basic.fs         # writes basic.s (and basic.inc if exports present)
python __main__.py examples/basic.fs -o out/basic.s

# Debug: dump token stream or AST
python __main__.py examples/basic.fs --dump-tokens
python __main__.py examples/basic.fs --dump-ast
```

### 2. Assemble (65816 target, using ca65)

```bash
# Assemble the compiled Forth module
ca65 --cpu 65816 -I targets/65816 basic.s -o obj/basic.o

# Assemble the VM runtime
ca65 --cpu 65816 -I targets/65816 targets/65816/vmachine.s -o obj/vmachine.o
```

### 3. Link (using ld65)

```bash
ld65 -C targets/65816/debug.cfg obj/vmachine.o obj/basic.o -o basic.bin
```

`debug.cfg` places the `CODE` segment at `$4000` (aligned to `$100`) and
zero page variables in `$00B4–$00FE`.  `MAIN` — the generated entry point —
will be the first code in the `CODE` segment, so the ROM monitor should be
configured to JSL to `$4000`.

A typical `Makefile` rule:

```makefile
TARGET  = 65816
INCDIR  = targets/$(TARGET)
CFGDIR  = targets/$(TARGET)
OBJDIR  = obj/debug

$(OBJDIR)/%.o: %.s
	ca65 --cpu $(TARGET) -I $(INCDIR) $< -o $@

$(OBJDIR)/vmachine.o: $(INCDIR)/vmachine.s
	ca65 --cpu $(TARGET) -I $(INCDIR) $< -o $@

%.bin: $(OBJDIR)/%.o $(OBJDIR)/vmachine.o
	ld65 -C $(CFGDIR)/debug.cfg $(OBJDIR)/vmachine.o $< -o $@
```

---

## Language reference

### Top-level forms

| Syntax | Meaning |
|---|---|
| `n constant name` | Define compile-time constant (folds to `LIT n`) |
| `variable name` | Allocate one cell of storage |
| `create name` | Create a named address with no data |
| `create name n allot` | Create a named address with n bytes reserved |
| `create name n , m , …` | Create a named address with cell data |
| `create name n c, m c, …` | Create a named address with byte data |
| `: name … ;` | Define a word (subroutine) |
| `.origin addr` | Set origin address (e.g. `.origin $8000`) |
| `.segment NAME` | Switch assembler segment |
| `.main name` | Designate entry-point word |
| `.export name` | Export word for linking (also generates `.inc` file) |
| `.define SYMBOL` | Define an assembler guard symbol |

### Inside a word definition

| Syntax | Meaning |
|---|---|
| `n` | Push literal integer (decimal, `$hex`, `0xhex`, `0bbinary`) |
| `name` | Call a word, push a constant, or push address of variable/create |
| `." text"` | Print string literal |
| `S" text"` | Push (addr, len) of string |
| `if … then` | Conditional |
| `if … else … then` | Conditional with alternate |
| `begin … until` | Loop until TOS is true |
| `begin … while … repeat` | Loop while TOS is true |
| `do … loop` | Counted loop (`limit index do … loop`) |
| `do … +loop` | Counted loop with variable step |

### Comments

```forth
\ line comment
( paren comment )
```

### Module system

Words marked with `.export` cause the compiler to emit a companion `.inc`
file containing `.import` declarations for all exported symbols. Other
modules include this file to resolve cross-module references:

```forth
\ math-utils.fs
.export square
.export cube

: square ( n -- n^2 ) dup * ;
: cube   ( n -- n^3 ) dup dup * * ;
```

This generates `math-utils.inc`:
```asm
.ifndef __math_utils_fs__
__math_utils_fs__ = 1
        .import cube
        .import square
.endif
```

### Struct definitions

`.struct` defines a named data structure at compile time. No memory is
allocated — only offset constants are generated. Memory allocation is a
separate operation using `create` or `allot`.

```forth
.struct point
    .field x cell
    .field y cell
.end-struct
```

Generates assembler constants:

```asm
point_x      = 0
point_y      = 2
point_sizeof = 4
```

Field sizes can be specified in bytes or as `cell` (target cell size, 2 bytes
on the 65816):

```forth
.struct header
    .field previous cell   \ 2 bytes
    .field flags    1      \ 1 byte
    .field namelen  1      \ 1 byte
    .field cfa      cell   \ 2 bytes
    .field name     ?      \ variable length — must be last field
.end-struct
```

When a `?` field is present the size constant is named `_fixed_sizeof` to
remind the programmer that the variable-length payload is not included:

```asm
header_previous     = 0
header_flags        = 2
header_namelen      = 3
header_cfa          = 4
header_name         = 6
header_fixed_sizeof = 6
```

**Allocating instances:**

Static instances are created with `create`. The struct name after the
instance name is optional and documentary only — the programmer is
responsible for providing the correct data:

```forth
create origin    point   0 , 0 ,
create red-color rgb     255 c, 0 c, 0 c,
create greeting  header  0 , 0 c, 5 c, 0 , Z" hello"
```

Runtime instances reserve space from the dictionary:

```forth
point_sizeof allot   \ reserve space for one point at runtime
```

**Accessing fields:**

Field offset constants are added to the base address and then fetched:

```forth
origin point_x + @        \ fetch x field of origin
red-color rgb_red + c@    \ fetch red field of red-color
```

**Naming conventions:**

Word names use hyphens (`red-color`, `my-buffer`) following Forth convention.
Struct field constants use underscores (`rgb_red`, `point_x`) because they
are compiler-generated. Always reference instances by their original
hyphenated Forth name — the compiler handles mangling to assembler labels
transparently:

```forth
create red-color rgb  255 c, 0 c, 0 c,  \ defined as red-color
...
red-color rgb_red + c@    \ correct — use original hyphenated name
red_color rgb_red + c@    \ wrong — red_color not found in compiler
```

**Defining words (`does>`):**

`does>` creates a defining word — a word that generates new named words
with custom runtime behavior. The primary use case is typed array
abstractions:

```forth
: array      ( n -- ) create cells allot does> swap cells + ;
: byte-array ( n -- ) create allot       does> swap + ;

10 array      my-array    \ creates a 10-cell array
20 byte-array my-bytes    \ creates a 20-byte array
```

When `my-array` is referenced in a word body it receives an index on the
stack and pushes the address of that element:

```forth
3 my-array          \ ( index -- addr )  address of element 3
42 3 my-array !     \ store 42 at element 3
3 my-array @        \ fetch element 3
```

The compiler resolves `does>` entirely at compile time — no runtime
dictionary modification occurs. The setup body (`create cells allot`) is
evaluated symbolically to determine the static allocation size, and a
`.res N` directive is emitted in the assembler output.

Supported setup body patterns:

| Setup body | Args | Allocation |
|---|---|---|
| `create` | none | label only, no allocation |
| `create allot` | `n` | `.res n` bytes |
| `create cells allot` | `n` | `.res n*2` bytes |

---

## VM instruction set

### Inline primitives (expanded as macros)

| Instruction | Stack effect | Forth word |
|---|---|---|
| `LIT n` | `-- n` | — |
| `EXIT` | — | — |
| `BRANCH addr` | `--` | — |
| `ZBRANCH addr` | `flag --` | — |
| `FETCH` | `addr -- n` | `@` |
| `STORE` | `n addr --` | `!` |
| `BFETCH` | `addr -- b` | `c@` |
| `BSTORE` | `b addr --` | `c!` |
| `TOR` | `n --` | `>r` |
| `RFROM` | `-- n` | `r>` |
| `RTOS` | `-- n` | `r@`, `i` |
| `TWOTOR` | `n1 n2 --` | `2>r` |
| `TWORFROM` | `-- n1 n2` | `2r>` |
| `DUP` | `n -- n n` | `dup` |
| `QDUP` | `n -- [n n\|0]` | `?dup` |
| `DROP` | `n --` | `drop` |
| `NIP` | `n1 n2 -- n2` | `nip` |
| `ABS` | `n -- \|n\|` | `abs` |
| `INVERT` | `n -- ~n` | `invert` |
| `ONEPLUS` | `n -- n+1` | `1+` |
| `ONEMINUS` | `n -- n-1` | `1-` |
| `TWOSTAR` | `n -- n*2` | `2*` |
| `TWOSLASH` | `n -- n/2` | `2/` |
| `ADD` | `n1 n2 -- n3` | `+` |
| `SUB` | `n1 n2 -- n3` | `-` |
| `STAR` | `n1 n2 -- n3` | `*` |
| `EQ` | `n1 n2 -- flag` | `=` |
| `CLEAR` | `… --` | `clear` |

### Runtime calls (implemented in vmachine.s)

Complex operations emit `CALL vm_xxx` and are implemented in `vmachine.s`:

**Arithmetic:** `um*` `um/mod` `sm/rem` `fm/mod` `/mod` `/` `mod`

**Bitwise:** `and` `or` `xor` `lshift` `rshift`

**Comparison:** `<` `>` `u<` `u>` `u<=` `u>=` `=` `<>` `0=` `0<>` `0<` `0>`

**Stack:** `swap` `over` `rot` `-rot` `tuck` `pick` `roll` `2dup` `2drop`
`2swap` `2over` `depth` `.s`

**Double cell:** `2@` `2!` `d+` `d-` `dabs` `dnegate` `d=` `du<` `d<`
`s>d` `um*`

**Memory:** `@` `!` `c@` `c!` `move` `fill` `allot` `here` `count`
`,` `c,`

**I/O:** `emit` `key` `type` `cputs` `cr` `space` `spaces` `.` `u.`
`.hex` `.s`

**Numeric base:** `base` (variable address)

**Control:** `execute`

### Forth library (vmachine.s runtime — compiled Forth)

These words are implemented in Forth source and compiled to subroutines:

**core.fs:** `max` `min` `umax` `umin` `negate` `not` `true` `false`
`2+` `2-` `+!` `aligned` `cell` `cells` `cell+` `2drop` `2rot`
`within` `*/mod` `*/` `m+` `m*` `m*/` `s>d` `d2*` `d2/` `d>s`
`dmax` `dmin` `d0=` `d0<` `min-int` `max-int` `min-2int` `max-2int`
`/mod` `/` `mod`

**pictured.fs:** `<#` `#` `#s` `#>` `hold` `holds` `sign`
`ud/mod` `.r` `u.r` `d.r` `d.`

---

## Targets

### 65816 (`targets/65816/`)

| File | Contents |
|---|---|
| `vmachine.inc` | Macro definitions for all VM instructions plus `.import` declarations |
| `vmachine.s` | Runtime routines: multiply, divide, bitwise ops, I/O, pictured output, … |
| `core.fs` | Forth-level library words |
| `pictured.fs` | Pictured numeric output words |
| `debug.cfg` | ld65 linker config (`$4000` CODE, `$00B4` ZP) |

**Stack model:** parameter stack in zero page, indexed by X (grows down,
16-bit cells).  Return stack is the hardware stack (`JSR`/`RTS`).

**Memory map:**
- `$0000–$00B3` — zero page scratch and VM variables
- `$00B4–$00FE` — parameter stack (PSTACK_INIT = $00FE)
- `$0100–$01FF` — hardware return stack
- `$0200–$05FF` — available RAM
- `$0600` — HERE pointer initial value (HERE_INIT)
- `$4000` — code segment base (debug config)

To add a new target, create `targets/<arch>/vmachine.inc` and
`targets/<arch>/vmachine.s` following the same conventions.

---

## Name mangling

Forth allows characters in word names that are illegal in assembler
identifiers. `_mangle()` in `codegen.py` translates them:

| Forth char | Assembler |
|---|---|
| `-` | `_` |
| `?` | `_q` |
| `!` | `_store` |
| `@` | `_fetch` |
| `>` | `_to` |
| `<` | `_from` |
| `=` | `_eq` |
| `+` | `_pl` |
| `*` | `_mul` |
| `/` | `_sl` |
| `.` | `_dot` |
| `#` | `_hash` |
| `'` | `_tick` |

Other non-alphanumeric characters become `_xNN` (hex code).
Use `tools/show_mangled.py` to check the mangled name of any word:

```bash
python tools/show_mangled.py "#>" "#s" "ud/mod"
```

---

## Extending the language

* **New primitives:** add to `INLINE_OPS` or `RUNTIME_CALLS` in `codegen.py`
  and implement the macro or runtime routine in `vmachine.inc` / `vmachine.s`.
* **New syntax:** add a `TType` in `tokenizer.py`, a keyword mapping in
  `KEYWORD_MAP`, an AST node in `ast_nodes.py`, a parse rule in `parser.py`,
  and a `_gen_xxx` method in `codegen.py`.
* **New targets:** provide `vmachine.inc` + `vmachine.s` only — no compiler
  changes needed.
* **New library words:** add to `core.fs` or a new `.fs` module. Use
  `.export` to make them available to other modules.

---

## Performance

The compiler generates subroutine-threaded code with short primitives inlined
as assembler macros. This eliminates the NEXT dispatch overhead of indirect-
threaded interpreters while keeping the code compact.

### Benchmark: Mandelbrot set

The Mandelbrot set generator (`examples/mandelbrot.fs`) is used as the primary
performance benchmark. It exercises fixed-point arithmetic heavily, particularly
signed multiply (`m*`), unsigned multiply (`um*`), and scaled division (`*/`).

Tested on a WDC 65816 SBC at 8MHz:

| Version | Time | vs ITC |
|---|---|---|
| ITC Forth interpreter | 67.0s | baseline |
| Forthc (initial) | 44.6s | −33.5% |
| + `.inline` directives | 44.1s | −34.2% |
| + Peephole optimizer | 43.6s | −34.9% |
| + Loop unrolling (`-D UNROLL`) | 42.9s | −36.0% |
| + `*/` power-of-two specialization | 27.2s | **−59.4%** |

### Optimizations

**Inlining** — mark short words with `.inline` to expand them at call sites
instead of generating a JSR/RTS pair:
```forth
: negate ( n -- -n ) invert 1+ ;
.inline negate
```

**Peephole optimizer** — the compiler automatically replaces common instruction
sequences with more efficient equivalents:

| Pattern | Replacement |
|---|---|
| `LIT $0001 / ADD` | `ONEPLUS` |
| `LIT $0001 / SUB` | `ONEMINUS` |
| `LIT $0001 / CALL vm_lshift` | `TWOSTAR` |
| `LIT $0000 / CALL vm_eq` | `CALL vm_zeq` |
| `LIT $0000 / CALL vm_lt` | `CALL vm_zlt` |
| `LIT $0000 / CALL vm_gt` | `CALL vm_zgt` |
| `CALL vm_swap / DROP` | `NIP` |
| `LIT n / DROP` | *(eliminated)* |

Disable with `--no-peephole` for debugging.

**Loop unrolling** — pass `-D UNROLL` to ca65 to unroll the inner loops in
`vm_umstar` and `vm_umslashmod`, eliminating loop overhead in the software
multiply and divide routines:
```makefile
CA65FLAGS = -I ../targets/65816 -D UNROLL
```

**`*/` power-of-two specialization** — when the divisor in a `*/` expression
is a compile-time constant that is a power of two, the compiler replaces the
full divide with an arithmetic right shift:
```forth
1024 constant RESCALE
z-real @ dup RESCALE */   \ compiles to: multiply then shift right 10 bits
```

This is the single largest optimization for fixed-point arithmetic programs.
Use power-of-two scale factors wherever possible to take advantage of it.

---

## Building the SDK

Before building tests or examples, build the VM SDK once:

```bash
cd targets/65816
make
```

This produces:
- `sdk/include/` — assembler headers for all VM modules
- `sdk/lib/vmachine.lib` — compiled VM library

Then build tests:
```bash
cd tests
make all
```

---

## Running the tests

```bash
cd tests
make all
```

Pass `--no-peephole` to disable the peephole optimizer for debugging:
```bash
python __main__.py --no-peephole source.fs
```

Pass `--const` to define compile-time constants for target-specific values:
```bash
python __main__.py --const CELL_SIZE=2 --const CELL_BITS=16 source.fs
```

Test modules covering:

| File | Coverage |
|---|---|
| `control.fs` | `if/else/then`, `do/loop`, `+loop`, `begin/until`, `begin/while/repeat` |
| `core-test.fs` | `within`, `min/max`, `*/mod`, `*/`, `m+`, `m*`, `m*/`, double-cell constants |
| `double.fs` | All double-cell words: `2@` `2!` `d+` `d-` `dabs` `d=` `du<` `d<` etc. |
| `logic.fs` | All comparison operators including unsigned and zero comparisons |
| `math.fs` | Arithmetic: `+` `-` `*` `/` `mod` `/mod` and signed/unsigned variants |
| `memory.fs` | `@` `!` `c@` `c!` `move` `fill` `create`/`allot` lookup tables |
| `module.fs` | `.export` / `.import` cross-module linking |
| `output.fs` | `.` `u.` `.hex` `.s` `."` `S"` `type` pictured I/O `.r` `u.r` `d.r` `d.` |
| `stack.fs` | `dup` `?dup` `drop` `swap` `over` `rot` `-rot` `pick` `roll` `>r` `r>` |
| `string.fs` | `S"` `."` `type` `count` `move` counted strings |

---

## Project layout

```
forthc/
├── __main__.py             command-line driver
├── common.mk               shared Makefile definitions
├── forthc/
│   ├── __init__.py         public API
│   ├── tokenizer.py        lexical analysis
│   ├── ast_nodes.py        AST node dataclasses
│   ├── parser.py           recursive-descent parser
│   └── codegen.py          VM assembly code generator
├── targets/
│   └── 65816/
│       ├── vmachine.inc    65816 macro definitions + import declarations
│       ├── vmachine.s      65816 runtime routines
│       ├── core.fs         Forth library (math, stack, memory utils)
│       └── pictured.fs     Pictured numeric output
├── sdk/
│   ├── include/
│   │   ├── core.inc        Forth library imports
│   │   ├── pictured.inc    Pictured numeric output imports
│   │   └── vmachine.inc    65816 macro definitions + import declarations
│   └── lib/
│       └── vmachine.lib    ar65 library
├── examples/
│   ├── Makefile
│   ├── basic.fs            Simple counter and output example
│   ├── fibonacci.fs        Classic Fibonacci number generator
│   ├── hanoi.fs            Recursive tower of Hanoi
│   ├── mandelbrot.fs       Text Mandelbrot set generator
│   └── pi.fs               Calculate Pi using the Nilakantha infinite series.
├── tests/
│   ├── Makefile
│   ├── debug.cfg           ld65 linker config ($4000 CODE, $00B4 ZP)
│   ├── control.fs
│   ├── core-test.fs
│   ├── double.fs
│   ├── logic.fs
│   ├── math.fs
│   ├── memory.fs
│   ├── module.fs
│   ├── output.fs
│   ├── stack.fs
│   └── string.fs
└── tools/
    └── show_mangled.py     Show assembler-mangled name for Forth words
```
