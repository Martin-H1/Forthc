#!/usr/bin/env python3
"""
forthc — Forth-to-VM-assembly compiler.

Usage:
    python -m forthc <source.f> [-o <output.s>] [--dump-tokens] [--dump-ast]

If -o is not given, output is written to <source>.s
"""

import argparse
import sys
import pathlib

from forthc.tokenizer import tokenize, TokenizeError
from forthc.parser    import parse, ParseError
from forthc.codegen   import generate, CodeGenError


def main():
    ap = argparse.ArgumentParser(
        prog='forthc',
        description='Compile Forth-like source to VM assembly.')
    ap.add_argument('source',
                    help='Input Forth source file')
    ap.add_argument('-o', '--output',
                    help='Output assembly file (default: <source>.s)')
    ap.add_argument('--dump-tokens', action='store_true',
                    help='Print token stream and exit')
    ap.add_argument('--dump-ast', action='store_true',
                    help='Print AST and exit')
    ap.add_argument('--const', action='append', metavar='NAME=VALUE',
                    help='Define a compile-time constant (may be repeated)')
    ap.add_argument('--no-peephole', action='store_true',
                    help='Disable peephole optimization')
    args = ap.parse_args()

    src_path = pathlib.Path(args.source)
    if not src_path.exists():
        print(f"forthc: error: file not found: {src_path}", file=sys.stderr)
        sys.exit(1)

    predefined = {}
    for c in (args.const or []):
        try:
            name, val = c.split('=', 1)
            predefined[name.strip()] = int(val.strip(), 0)
        except ValueError:
            print(f"forthc: bad --const format: {c!r} (expected NAME=VALUE)",
                  file=sys.stderr)
            sys.exit(1)

    source = src_path.read_text(encoding='utf-8')

    # --- Tokenize ---
    try:
        tokens = tokenize(source)
    except TokenizeError as e:
        print(f"forthc: tokenize error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dump_tokens:
        for tok in tokens:
            print(tok)
        return

    # --- Parse ---
    try:
        program = parse(tokens, predefined=predefined)
    except ParseError as e:
        print(f"forthc: parse error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dump_ast:
        import pprint
        pprint.pprint(program)
        return

    # stem: "core.fs" -> "core_fs", "pictured.fs" -> "pictured_fs"
    stem = src_path.name.replace('.', '_').replace('-', '_')

    # --- Code generation ---
    try:
        result = generate(program, stem=stem, predefined=predefined,
                          no_peephole=args.no_peephole)
    except CodeGenError as e:
        print(f"forthc: codegen error: {e}", file=sys.stderr)
        sys.exit(1)

    # --- Write .s output ---
    if args.output:
        out_path = pathlib.Path(args.output)
    else:
        out_path = src_path.with_suffix('.s')
    out_path.write_text(result.asm, encoding='utf-8')
    print(f"forthc: wrote {out_path}  ({len(result.asm)} bytes)")

    # --- Write .inc if exports exist ---
    if result.inc:
        inc_path = out_path.with_suffix('.inc')
        inc_path.write_text(result.inc, encoding='utf-8')
        print(f"forthc: wrote {inc_path}")

if __name__ == '__main__':
    main()
