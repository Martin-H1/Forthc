"""
Recursive-descent parser for the Forth-like compiler.

Grammar (informal):

  program       ::= top_def* EOF
  top_def       ::= constant_def
                  | variable_def
                  | word_def
                  | origin_dir
                  | segment_dir
  constant_def  ::= NUMBER 'constant' NAME
  variable_def  ::= 'variable' NAME
  word_def      ::= ':' NAME body ';'
  origin_dir    ::= '.origin' NUMBER
  segment_dir   ::= '.segment' (STRING | WORD)
  body          ::= stmt*
  stmt          ::= NUMBER
                  | STRING_LIT
                  | PRINT_STRING
                  | if_stmt
                  | begin_stmt
                  | do_stmt
                  | WORD            ; any other word is a call
"""

from .tokenizer import Token, TType, TokenizeError
from .ast_nodes import (
    Program, CreateDef, StructDef, FieldDef, DataItem,
    ConstantDef, VariableDef, WordDef, DefiningWord, DefiningCall,
    DefineDirective, ExportDirective, OriginDirective, SegmentDirective,
    MainDirective, Comma, CComma, NumberLit, StringLit, PrintString,
    WordCall, IfThen, BeginUntil, BeginWhileRepeat, DoLoop, InlineDirective,
)


class ParseError(Exception):
    def __init__(self, msg, token: Token):
        super().__init__(f"Line {token.line}, col {token.col}: {msg} (got {token.type.name} {token.value!r})")
        self.token = token
        self._known_constants: dict = {}

class Parser:
    def __init__(self, tokens: list[Token], predefined: dict = None):
        self._tokens           = tokens
        self._pos              = 0
        self._struct_names:    set  = set()
        self._defining_words:  set  = set()
        self._known_constants: dict = dict(predefined or {})
        # add built-in nullary constants using CELL_SIZE if provided
        cell_size = self._known_constants.get('CELL_SIZE', 2)
        self._known_constants.setdefault('cell', cell_size)
        self._known_constants.setdefault('cell-size', cell_size)

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _peek(self) -> Token:
        return self._tokens[self._pos]

    def _advance(self) -> Token:
        tok = self._tokens[self._pos]
        if tok.type != TType.EOF:
            self._pos += 1
        return tok

    def _expect(self, ttype: TType) -> Token:
        tok = self._peek()
        if tok.type != ttype:
            raise ParseError(f"Expected {ttype.name}", tok)
        return self._advance()

    def _match(self, *types: TType) -> bool:
        return self._peek().type in types

    def _data_sequence(self) -> list:
        """Collect remaining items in a mixed cell/byte/string data sequence."""
        items = []
        while True:
            if self._match(TType.NUMBER):
                num_tok = self._advance()
                if self._match(TType.COMMA):
                    self._advance()
                    items.append(DataItem(kind='cell', value=num_tok.value))
                elif self._match(TType.CCOMMA):
                    self._advance()
                    items.append(DataItem(kind='byte', value=num_tok.value))
                else:
                    raise ParseError(
                        "Expected ',' or 'c,' after number in data sequence",
                        self._peek())
            elif self._match(TType.WORD):
                lbl_tok = self._advance()
                if self._match(TType.COMMA):
                    self._advance()
                    items.append(DataItem(kind='cell', value=lbl_tok.value))
                else:
                    raise ParseError(
                        "Expected ',' after label in data sequence",
                        self._peek())
            elif self._match(TType.SQUOTE):
                tok2 = self._advance()
                items.append(DataItem(kind='string', value=tok2.value))
            elif self._match(TType.ZQUOTE):
                tok2 = self._advance()
                items.append(DataItem(kind='zstring', value=tok2.value))
            else:
                break
        return items

    def _defining_call(self, tok, args=None) -> DefiningCall:
        if args is None:
            args = []
        def_tok  = self._advance()          # consume defining word name
        name_tok = self._expect(TType.WORD) # new name
        return DefiningCall(
            defining_word=def_tok.value,
            new_name=name_tok.value,
            args=args,
            line=tok.line, col=tok.col)

    def _fold_constant_expr(self) -> int | None:
        """Evaluate a compile-time constant expression.
        Returns the integer result if the entire expression folds cleanly,
        or None if any operand is not a known constant.
        Consumes tokens up to but not including 'constant'.
        """
        CELL_SIZE = self._known_constants.get('CELL_SIZE', 2)
        stack = []

        FOLDABLE_OPS = {
            '+':      lambda a, b: a + b,
            '-':      lambda a, b: a - b,
            '*':      lambda a, b: a * b,
            '/':      lambda a, b: a // b,
            'lshift': lambda a, b: a << b,
            'rshift': lambda a, b: (a & 0xFFFF) >> b,
            'and':    lambda a, b: a & b,
            'or':     lambda a, b: a | b,
            'xor':    lambda a, b: a ^ b,
            '=':      lambda a, b: 0xFFFF if a == b else 0,
            '<':      lambda a, b: 0xFFFF if a < b else 0,
            '>':      lambda a, b: 0xFFFF if a > b else 0,
            '<>':     lambda a, b: 0xFFFF if a != b else 0,
        }
        UNARY_OPS = {
            'negate': lambda a: -a,
            'invert': lambda a: ~a & 0xFFFF,
            '1+':     lambda a: a + 1,
            '1-':     lambda a: a - 1,
            '2*':     lambda a: a * 2,
            '2/':     lambda a: a // 2,
            'cells':  lambda a: a * CELL_SIZE,
        }

        saved_pos = self._pos
        while not self._match(TType.CONSTANT, TType.EOF):
            tok = self._peek()
            if tok.type == TType.NUMBER:
                self._advance()
                stack.append(tok.value)
            elif tok.type == TType.WORD:
                name = tok.value
                if name in self._known_constants:
                    self._advance()
                    stack.append(self._known_constants[name])
                elif name in UNARY_OPS:
                    if len(stack) < 1:
                        self._pos = saved_pos
                        return None
                    self._advance()
                    stack.append(UNARY_OPS[name](stack.pop()))
                elif name in FOLDABLE_OPS:
                    if len(stack) < 2:
                        self._pos = saved_pos
                        return None
                    self._advance()
                    b = stack.pop()
                    a = stack.pop()
                    stack.append(FOLDABLE_OPS[name](a, b))
                else:
                    # unknown word — can't fold
                    self._pos = saved_pos
                    return None
            else:
                # unexpected token — can't fold
                self._pos = saved_pos
                return None

        if len(stack) == 1:
            return stack[0]
        self._pos = saved_pos
        return None

    # ------------------------------------------------------------------
    # Top level
    # ------------------------------------------------------------------

    def parse(self) -> Program:
        defs = []
        while not self._match(TType.EOF):
            node = self._top_def()
            if node is not None:
                defs.append(node)
        return Program(definitions=defs)

    def _top_def(self):
        tok = self._peek()

        if tok.type == TType.STRUCT:
            node = self._struct_def()
            self._struct_names.add(node.name)
            return node

        # Check for defining word call: [args...] defining-word new-name
        if (tok.type == TType.WORD and tok.value in self._defining_words):
            return self._defining_call(tok)

        # constant expression starting with a known constant name
        if (tok.type == TType.WORD and tok.value in self._known_constants):
            val = self._fold_constant_expr()
            if val is not None and self._match(TType.CONSTANT):
                self._advance()
                name_tok = self._expect(TType.WORD)
                self._known_constants[name_tok.value] = val
                return ConstantDef(name=name_tok.value, value=val,
                                   line=tok.line, col=tok.col)
            raise ParseError(
                "Constant expression must be followed by 'constant'",
                self._peek())

        if tok.type == TType.NUMBER:
            # first try: collect leading numbers for defining word call
            saved_pos = self._pos
            args = []
            while self._match(TType.NUMBER):
                num_tok = self._advance()
                args.append(NumberLit(value=num_tok.value,
                                      line=num_tok.line, col=num_tok.col))
            # check if next token is a defining word
            if (self._match(TType.WORD) and
                    self._peek().value in self._defining_words):
                return self._defining_call(tok, args)
            # not a defining call
            # restore and try constant folding
            self._pos = saved_pos
            val = self._fold_constant_expr()
            if val is not None and self._match(TType.CONSTANT):
                self._advance()
                name_tok = self._expect(TType.WORD)
                self._known_constants[name_tok.value] = val
                return ConstantDef(name=name_tok.value, value=val,
                                   line=tok.line, col=tok.col)
            # restore and try simple number constant
            self._pos = saved_pos
            num_tok = self._advance()
            if self._match(TType.CONSTANT):
                self._advance()
                name_tok = self._expect(TType.WORD)
                self._known_constants[name_tok.value] = num_tok.value
                return ConstantDef(name=name_tok.value, value=num_tok.value,
                                   line=num_tok.line, col=num_tok.col)
            else:
                raise ParseError(
                    "Bare number at top level must be followed by "
                    "'constant' or a defining word",
                    num_tok)

        if tok.type == TType.CREATE:
            self._advance()
            name_tok   = self._expect(TType.WORD)
            size       = 0
            data       = []
            struct_ref = ''

            # Optional struct reference (documentary)
            if (self._match(TType.WORD) and
                    self._peek().value in self._struct_names):
                struct_ref = self._advance().value

            if self._match(TType.NUMBER):
                num_tok = self._advance()
                if self._match(TType.ALLOT):
                    self._advance()
                    size = num_tok.value
                elif self._match(TType.COMMA):
                    self._advance()
                    data.append(DataItem(kind='cell', value=num_tok.value))
                    data.extend(self._data_sequence())
                elif self._match(TType.CCOMMA):
                    self._advance()
                    data.append(DataItem(kind='byte', value=num_tok.value))
                    data.extend(self._data_sequence())
                else:
                    raise ParseError(
                        "Expected 'allot', ',' or 'c,' after number in 'create'",
                        self._peek())
            elif self._match(TType.WORD):
                lbl_tok = self._advance()
                if self._match(TType.COMMA):
                    self._advance()
                    data.append(DataItem(kind='cell', value=lbl_tok.value))
                    data.extend(self._data_sequence())
                else:
                    raise ParseError(
                        "Expected ',' after label in create data",
                        self._peek())
            elif self._match(TType.SQUOTE):
                tok2 = self._advance()
                data.append(DataItem(kind='string', value=tok2.value))
                data.extend(self._data_sequence())
            elif self._match(TType.ZQUOTE):
                tok2 = self._advance()
                data.append(DataItem(kind='zstring', value=tok2.value))
                data.extend(self._data_sequence())

            return CreateDef(name=name_tok.value, size=size, data=data,
                             struct_ref=struct_ref,
                             line=tok.line, col=tok.col)

        if tok.type == TType.VARIABLE:
            self._advance()
            name_tok = self._expect(TType.WORD)
            return VariableDef(name=name_tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.COLON:
            return self._word_def()

        if tok.type == TType.DEFINE:
            self._advance()
            sym_tok = self._expect(TType.WORD)
            return DefineDirective(symbol=sym_tok.value,
                                   line=tok.line, col=tok.col)

        if tok.type == TType.EXPORT:
            self._advance()
            word_tok = self._expect(TType.WORD)
            return ExportDirective(word=word_tok.value,
                                   line=tok.line, col=tok.col)

        if tok.type == TType.INLINE:
            self._advance()
            word_tok = self._expect(TType.WORD)
            return InlineDirective(word=word_tok.value,
                                   line=tok.line, col=tok.col)

        if tok.type == TType.ORIGIN:
            self._advance()
            addr_tok = self._expect(TType.NUMBER)
            return OriginDirective(address=addr_tok.value,
                                   line=tok.line, col=tok.col)

        if tok.type == TType.SEGMENT:
            self._advance()
            # segment name can be a quoted string or a bare word
            seg_tok = self._peek()
            if seg_tok.type in (TType.SQUOTE, TType.DOTQUOTE, TType.WORD):
                self._advance()
                return SegmentDirective(name=str(seg_tok.value),
                                        line=tok.line, col=tok.col)
            raise ParseError("Expected segment name", seg_tok)

        if tok.type == TType.MAIN:
            self._advance()
            word_tok = self._expect(TType.WORD)
            return MainDirective(word=word_tok.value,
                                 line=tok.line, col=tok.col)

        raise ParseError("Unexpected token at top level", tok)

    def _struct_def(self) -> StructDef:
        self._advance()                     # consume '.struct'
        name_tok = self._expect(TType.WORD)
        node = StructDef(name=name_tok.value,
                         line=name_tok.line, col=name_tok.col)
        while not self._match(TType.ENDSTRUCT, TType.EOF):
            if self._match(TType.FIELD):
                self._advance()             # consume '.field'
                fname = self._expect(TType.WORD)
                stok  = self._peek()
                if stok.type == TType.NUMBER:
                    self._advance()
                    size = stok.value
                elif stok.type == TType.WORD and stok.value == 'cell':
                    self._advance()
                    size = 0                # 0 = cell, substituted in codegen
                elif stok.type == TType.WORD and stok.value == '?':
                    self._advance()
                    size = -1               # -1 = variable length
                else:
                    raise ParseError(
                        "Expected size, 'cell', or '?' after field name",
                        stok)
                node.fields.append(FieldDef(
                    name=fname.value, size=size,
                    line=fname.line, col=fname.col))
            else:
                raise ParseError(
                    "Expected '.field' inside '.struct'",
                    self._peek())
        self._expect(TType.ENDSTRUCT)
        return node

    # ------------------------------------------------------------------
    # Word definition
    # ------------------------------------------------------------------

    def _word_def(self) -> WordDef | DefiningWord:
        colon_tok = self._advance()            # consume ':'
        name_tok  = self._expect(TType.WORD)   # word name
        setup     = self._body()
        if self._match(TType.DOES):
            self._advance()                    # consume 'does>'
            does_body = self._body()
            self._expect(TType.SEMICOLON)
            node = DefiningWord(
                name=name_tok.value,
                setup=setup,
                does_body=does_body,
                line=colon_tok.line, col=colon_tok.col)
            self._defining_words.add(name_tok.value)
            return node
        self._expect(TType.SEMICOLON)
        return WordDef(name=name_tok.value, body=setup,
                       line=colon_tok.line, col=colon_tok.col)

    # ------------------------------------------------------------------
    # Body (list of statements)
    # ------------------------------------------------------------------

    def _body(self) -> list:
        stmts = []
        while not self._match(TType.SEMICOLON, TType.ELSE,
                               TType.THEN, TType.UNTIL,
                               TType.WHILE, TType.REPEAT,
                               TType.LOOP, TType.PLUSLOOP,
                               TType.DOES, TType.EOF):
            stmts.append(self._stmt())
        return stmts

    def _stmt(self):
        tok = self._peek()

        if tok.type == TType.CREATE:
            self._advance()
            return WordCall(name='create', line=tok.line, col=tok.col)

        if tok.type == TType.ALLOT:
            self._advance()
            return WordCall(name='allot', line=tok.line, col=tok.col)

        if tok.type == TType.NUMBER:
            self._advance()
            return NumberLit(value=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.SQUOTE:
            self._advance()
            return StringLit(text=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.DOTQUOTE:
            self._advance()
            return PrintString(text=tok.value, line=tok.line, col=tok.col)

        if tok.type == TType.IF:
            return self._if_stmt()

        if tok.type == TType.BEGIN:
            return self._begin_stmt()

        if tok.type == TType.DO:
            return self._do_stmt()

        if tok.type == TType.WORD:
            self._advance()
            return WordCall(name=tok.value, line=tok.line, col=tok.col)

        # Bare number inside a body is valid
        if tok.type == TType.NUMBER:
            self._advance()
            return NumberLit(value=tok.value, line=tok.line, col=tok.col)

        # Bare , inside a body is valid
        if tok.type == TType.COMMA:
            self._advance()
            return Comma(text=tok.value, line=tok.line, col=tok.col)

        # Bare c, inside a body is valid
        if tok.type == TType.CCOMMA:
            self._advance()
            return CComma(text=tok.value, line=tok.line, col=tok.col)

        raise ParseError("Unexpected token in word body", tok)

    # ------------------------------------------------------------------
    # Control structures
    # ------------------------------------------------------------------

    def _if_stmt(self) -> IfThen:
        if_tok = self._advance()              # consume 'if'
        consequent = self._body()
        alternate  = []
        if self._match(TType.ELSE):
            self._advance()                   # consume 'else'
            alternate = self._body()
        self._expect(TType.THEN)
        return IfThen(consequent=consequent, alternate=alternate,
                      line=if_tok.line, col=if_tok.col)

    def _begin_stmt(self):
        begin_tok = self._advance()           # consume 'begin'

        # Collect stmts until 'while' or 'until'
        first_body = self._body()

        if self._match(TType.UNTIL):
            self._advance()
            return BeginUntil(body=first_body,
                              line=begin_tok.line, col=begin_tok.col)

        if self._match(TType.WHILE):
            self._advance()
            loop_body = self._body()
            self._expect(TType.REPEAT)
            return BeginWhileRepeat(test=first_body, body=loop_body,
                                    line=begin_tok.line, col=begin_tok.col)

        raise ParseError("Expected 'until' or 'while' after 'begin' body",
                         self._peek())

    def _do_stmt(self) -> DoLoop:
        do_tok   = self._advance()              # consume 'do'
        body     = self._body()
        plus     = self._match(TType.PLUSLOOP)
        self._advance()                         # consume 'loop' or '+loop'
        return DoLoop(body=body, plus_loop=plus,
                      line=do_tok.line, col=do_tok.col)

def parse(tokens: list[Token], predefined: dict = None) -> Program:
    return Parser(tokens, predefined=predefined).parse()
