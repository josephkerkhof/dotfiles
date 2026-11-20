#!/usr/bin/env python3
"""Reject prose comments added to PHP source.

A docblock may carry annotations (@param, @return, ...) and their wrapped
continuations. Anything else - a `//` line, a `#` line, or prose sitting in a
docblock before its first annotation - is refused.
"""

from __future__ import annotations

import difflib
import json
import pathlib
import re
import sys

SKIP = ("/vendor/", "/node_modules/", "/storage/framework/")
ANNOTATION = re.compile(r"^\s*\*?\s*@\w")
DOC_OPEN = re.compile(r"^\s*/\*\*")
DOC_ONE_LINE = re.compile(r"^\s*/\*\*.*\*/\s*$")
DOC_ONE_LINE_ANNOTATION = re.compile(r"/\*\*\s*@\w")
BLOCK_OPEN = re.compile(r"^\s*/\*(?!\*)")
LINE_COMMENT = re.compile(r"^\s*(//|#(?!\[))")
DOC_BODY = re.compile(r"^\s*\*")


def is_watched(path: str) -> bool:
    return (
        path.endswith(".php")
        and not path.endswith(".blade.php")
        and not any(fragment in path for fragment in SKIP)
    )


def added_lines(old: str, new: str) -> list[str]:
    if not old:
        return new.splitlines()

    diff = difflib.unified_diff(old.splitlines(), new.splitlines(), n=0, lineterm="")
    return [line[1:] for line in diff if line.startswith("+") and not line.startswith("+++")]


def offences(lines: list[str]) -> list[str]:
    found: list[str] = []
    in_doc = False
    doc_had_annotation = False

    for line in lines:
        if in_doc:
            if ANNOTATION.match(line):
                doc_had_annotation = True
            elif DOC_BODY.match(line) and line.strip() not in {"*", "*/"} and not doc_had_annotation:
                found.append(line)
            if "*/" in line:
                in_doc = False
            continue

        if DOC_ONE_LINE.match(line):
            if not DOC_ONE_LINE_ANNOTATION.search(line):
                found.append(line)
            continue

        if DOC_OPEN.match(line):
            in_doc, doc_had_annotation = True, False
            continue

        if LINE_COMMENT.match(line) or BLOCK_OPEN.match(line):
            found.append(line)

    return found


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return 0

    if event.get("tool_name") not in {"Write", "Edit", "MultiEdit"}:
        return 0

    tool_input = event.get("tool_input") or {}
    path = tool_input.get("file_path", "")

    if not is_watched(path):
        return 0

    edits = tool_input.get("edits") or [tool_input]
    lines: list[str] = []

    for edit in edits:
        if "content" in edit:
            existing = pathlib.Path(path)
            old = existing.read_text() if existing.is_file() else ""
            lines += added_lines(old, edit["content"])
        else:
            lines += added_lines(edit.get("old_string", ""), edit.get("new_string", ""))

    guilty = offences(lines)

    if not guilty:
        return 0

    shown = "\n".join(f"    {line.strip()}" for line in guilty[:10])
    print(
        f"Blocked: {len(guilty)} prose comment line(s) in {path}.\n{shown}\n\n"
        "Only @param/@return/@throws style annotations and their wrapped\n"
        "continuations are allowed. Explanation belongs in the commit message,\n"
        "or in clearer names and smaller methods. Rewrite without the comment.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
