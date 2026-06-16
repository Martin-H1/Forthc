"""
Abstract Syntax Tree node definitions for the Forth compiler.
"""

from dataclasses import dataclass, field
from typing import Any


# ---------------------------------------------------------------------------
# Base
# ---------------------------------------------------------------------------

@dataclass
class ASTNode:
    line: int = field(default=0, repr=False, compare=False)
    col:  int = field(default=0, repr=False, compare=False)


# ---------------------------------------------------------------------------
# Top-level definitions
# ---------------------------------------------------------------------------


@dataclass
class CreateDef(ASTNode):
    """create name [struct-ref] [allot | data-sequence]"""
    name:       str  = ''
    size:       int  = 0        # from allot (0 = no allot)
    data:       list = field(default_factory=list)   # list of DataItem
    struct_ref: str  = ''       # struct name if specified, documentary only
    line:       int  = 0
    col:        int  = 0


@dataclass
class FieldDef:
    """One field in a .struct definition."""
    name: str = ''
    size: int = 0     # bytes; 0 = cell (substituted in codegen), -1 = variable (?)
    line: int = 0
    col:  int = 0


@dataclass
class StructDef(ASTNode):
    """.struct name .field ... .end-struct"""
    name:   str  = ''
    fields: list = field(default_factory=list)  # list of FieldDef


@dataclass
class DataItem:
    """One item in a create data sequence."""
    kind:  str    = ''      # 'cell', 'byte', 'string', 'zstring'
    value: object = None    # int for cell/byte, str for string/zstring/label


@dataclass
class ConstantDef(ASTNode):
    """15 constant foo  →  foo = 15"""
    name:  str = ''
    value: int = 0


@dataclass
class VariableDef(ASTNode):
    """variable bar  →  allocate one cell named bar"""
    name: str = ''


@dataclass
class WordDef(ASTNode):
    """: foo <body> ;"""
    name: str        = ''
    body: list       = field(default_factory=list)


@dataclass
class DefiningWord(ASTNode):
    """: name setup-body does> does-body ;"""
    name:      str  = ''
    setup:     list = field(default_factory=list)
    does_body: list = field(default_factory=list)

@dataclass
class DefiningCall(ASTNode):
    """args defining-word new-name — top level use of a defining word"""
    defining_word: str  = ''
    new_name:      str  = ''
    args:          list = field(default_factory=list)


@dataclass
class DefineDirective(ASTNode):
    """.define FOO  →  define an assembler symbol with no value (for guards)."""
    symbol: str = ''

@dataclass
class ExportDirective(ASTNode):
    """.export foo  →  mark word 'foo' as a public symbol for the linker."""
    word: str = ''

@dataclass
class IncludeDirective(ASTNode):
    """.include "filename.inc"  →  pass-through to assembler"""
    filename: str = ''

@dataclass
class InlineDirective(ASTNode):
    """.inline name  — mark word for inline expansion at call sites"""
    word: str = ''

@dataclass
class OriginDirective(ASTNode):
    """.origin $8000  →  set the origin address"""
    address: int = 0


@dataclass
class SegmentDirective(ASTNode):
    """.segment "CODE"  →  switch segment"""
    name: str = ''


@dataclass
class MainDirective(ASTNode):
    """.main foo  →  designate 'foo' as the program entry point."""
    word: str = ''


# ---------------------------------------------------------------------------
# Expressions / statements inside a word definition
# ---------------------------------------------------------------------------

@dataclass
class Comma(ASTNode):
    ', →  compiles TOS cell into memory.'
    text: str = ''


@dataclass
class CComma(ASTNode):
    ', →  compiles TOS LSB into memory.'
    text: str = ''


@dataclass
class NumberLit(ASTNode):
    """A numeric literal pushes its value onto the stack."""
    value: int = 0


@dataclass
class StringLit(ASTNode):
    """S" hello"  →  push (addr, len) of string onto stack."""
    text: str = ''


@dataclass
class PrintString(ASTNode):
    '." hello"  →  print string literal.'
    text: str = ''


@dataclass
class WordCall(ASTNode):
    """Reference to any Forth word (built-in or user-defined)."""
    name: str = ''


@dataclass
class IfThen(ASTNode):
    """if <consequent> [ else <alternate> ] then"""
    consequent: list = field(default_factory=list)
    alternate:  list = field(default_factory=list)


@dataclass
class BeginUntil(ASTNode):
    """begin <body> until  — loop until TOS is true"""
    body: list = field(default_factory=list)


@dataclass
class BeginWhileRepeat(ASTNode):
    """begin <test> while <body> repeat"""
    test: list = field(default_factory=list)
    body: list = field(default_factory=list)


@dataclass
class DoLoop(ASTNode):
    """do <body> loop"""
    body: list = field(default_factory=list)
    plus_loop: bool = False    # True if +loop, False if loop
    line:      int  = 0
    col:       int  = 0


# ---------------------------------------------------------------------------
# Top-level program
# ---------------------------------------------------------------------------

@dataclass
class Program(ASTNode):
    definitions: list = field(default_factory=list)
