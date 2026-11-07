"""Line-level statement instrumentation for GDScript coverage measurement.

The instrumenter inserts a ``CoverageRecorder.hit("res://...", line)`` call before
each executable statement line. It does not modify the working tree: callers run
it against a temporary copy of the project.

Only statement *start* lines are instrumented. A physical line is a statement
start when it is inside a function body and does not continue a multi-line
expression, a string literal, a match arm pattern or a block header that cannot
be preceded by another statement (``else`` / ``elif``).
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

RECORDER_CALL = 'CoverageRecorder.hit("{path}", {line})'

_CONTROL_KEYWORDS = {"if", "for", "while", "match"}
_SKIP_FIRST_WORDS = {
    "elif",
    "else",
    "func",
    "class",
    "class_name",
    "extends",
    "enum",
    "signal",
    "const",
    "static",
    "breakpoint",
}
_CONTINUATION_WORDS = {"and", "or", "not", "in", "is", "as"}
_OPERATOR_END = set("+-*/%=<>!&|^~,.\u005c")
_CONTINUATION_FIRST = set(".,)]}:+-*/%=<>!&|^~")
_FUNC_DECL = re.compile(r"^(?:static\s+)?func\b")
_WORD = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*")


@dataclass
class LineInfo:
    depth_start: int = 0
    depth_end: int = 0
    starts_in_string: bool = False
    has_code: bool = False
    first_code_index: int | None = None
    first_char: str = ""
    last_code_char: str = ""


@dataclass
class FileScan:
    lines: list[str] = field(default_factory=list)
    info: list[LineInfo] = field(default_factory=list)


def _scan_lines(source: str) -> FileScan:
    lines = source.split("\n")
    info = [LineInfo() for _ in lines]

    depth = 0
    in_triple: str | None = None

    for line_index, line in enumerate(lines):
        current = info[line_index]
        current.depth_start = depth
        current.starts_in_string = in_triple is not None

        i = 0
        length = len(line)
        while i < length:
            char = line[i]

            if in_triple is not None:
                closing = line.find(in_triple, i)
                if closing == -1:
                    i = length
                    continue
                i = closing + len(in_triple)
                in_triple = None
                current.has_code = True
                current.last_code_char = in_triple or '"'
                continue

            if char == "#":
                break

            if char in ("'", '"'):
                if line.startswith(char * 3, i):
                    closing = line.find(char * 3, i + 3)
                    current.has_code = True
                    if current.first_code_index is None:
                        current.first_code_index = i
                        current.first_char = char
                    if closing == -1:
                        current.last_code_char = char
                        in_triple = char * 3
                        i = length
                        continue
                    i = closing + 3
                    current.last_code_char = char
                    continue

                if current.first_code_index is None:
                    current.first_code_index = i
                    current.first_char = char
                current.has_code = True

                raw = i > 0 and line[i - 1] == "r"
                i += 1
                while i < length:
                    if line[i] == "\\" and not raw:
                        i += 2
                        continue
                    if line[i] == char:
                        i += 1
                        break
                    i += 1
                current.last_code_char = char
                continue

            if not char.isspace():
                if current.first_code_index is None:
                    current.first_code_index = i
                    current.first_char = char
                current.has_code = True
                current.last_code_char = char

                if char in "([{":
                    depth += 1
                elif char in ")]}":
                    depth = max(depth - 1, 0)

            i += 1

        current.depth_end = depth

    return FileScan(lines=lines, info=info)


def _indent_of(line: str) -> int:
    return len(line) - len(line.lstrip(" \t"))


def _first_word(line: str, first_code_index: int | None) -> str:
    if first_code_index is None:
        return ""
    match = _WORD.match(line[first_code_index:])
    return match.group(0) if match else ""


def _is_func_declaration(line: str, line_info: LineInfo) -> bool:
    if not line_info.has_code or line_info.starts_in_string:
        return False
    if line_info.first_code_index is None:
        return False
    return bool(_FUNC_DECL.match(line[line_info.first_code_index :]))


def _function_body_mask(scan: FileScan) -> list[bool]:
    """Mark physical lines that belong to a function body (not its signature)."""
    mask = [False] * len(scan.lines)
    body_indent: int | None = None
    in_signature = False
    signature_indent = 0

    for index, line in enumerate(scan.lines):
        line_info = scan.info[index]

        if in_signature:
            if line_info.depth_end == 0 and line_info.last_code_char == ":":
                in_signature = False
                body_indent = signature_indent
            continue

        if _is_func_declaration(line, line_info):
            signature_indent = _indent_of(line)
            if line_info.depth_end != 0 or line_info.last_code_char != ":":
                in_signature = True
            else:
                body_indent = signature_indent
            continue

        if body_indent is None:
            continue

        has_code = line_info.has_code and not line_info.starts_in_string
        if has_code and line_info.depth_start == 0 and _indent_of(line) <= body_indent:
            body_indent = None
            if _is_func_declaration(line, line_info):
                signature_indent = _indent_of(line)
                if line_info.depth_end != 0 or line_info.last_code_char != ":":
                    in_signature = True
                else:
                    body_indent = signature_indent
            continue

        mask[index] = True

    return mask


def _previous_code_line(scan: FileScan, index: int) -> LineInfo | None:
    for previous in range(index - 1, -1, -1):
        info = scan.info[previous]
        if info.has_code and not info.starts_in_string:
            return info
    return None


def _continues_previous(scan: FileScan, index: int) -> bool:
    previous = _previous_code_line(scan, index)
    if previous is None:
        return False
    if previous.last_code_char == "\u005c":
        return True
    return previous.last_code_char in _OPERATOR_END


def _is_statement_start(scan: FileScan, index: int, in_body: bool) -> bool:
    if not in_body:
        return False

    info = scan.info[index]
    line = scan.lines[index]

    if not info.has_code or info.starts_in_string:
        return False
    if info.depth_start != 0:
        return False

    first_char = info.first_char
    if not first_char:
        return False
    if first_char in _CONTINUATION_FIRST or first_char in ("'", '"'):
        return False

    word = _first_word(line, info.first_code_index)
    if not word:
        return False
    if word in _SKIP_FIRST_WORDS or word in _CONTINUATION_WORDS:
        return False

    code = line[info.first_code_index or 0 :].rstrip()
    if code.endswith(":") and word not in _CONTROL_KEYWORDS:
        return False

    if _continues_previous(scan, index):
        return False

    return True


def statement_lines(source: str) -> list[int]:
    """Return 1-based line numbers that start an executable statement."""
    scan = _scan_lines(source)
    body = _function_body_mask(scan)
    return [
        index + 1
        for index in range(len(scan.lines))
        if _is_statement_start(scan, index, body[index])
    ]


def instrument_source(source: str, res_path: str) -> tuple[str, list[int]]:
    """Return instrumented source and the 1-based statement lines it reports."""
    lines = statement_lines(source)
    if not lines:
        return source, []

    original = source.split("\n")
    output = list(original)
    for line_number in sorted(lines, reverse=True):
        line = original[line_number - 1]
        indent = line[: len(line) - len(line.lstrip(" \t"))]
        call = RECORDER_CALL.format(path=res_path, line=line_number)
        output.insert(line_number - 1, f"{indent}{call}")

    return "\n".join(output), lines


def instrument_file(path: Path, res_path: str) -> list[int]:
    source = path.read_text(encoding="utf-8")
    instrumented, lines = instrument_source(source, res_path)
    if lines:
        path.write_text(instrumented, encoding="utf-8")
    return lines
