#!/usr/bin/env python3
"""Go-template-aware yamllint wrapper for pre-commit.

Debos recipes in mods/*/target.yaml are Go templates ({{ ... }}), which are
not valid YAML.  This script mangles template expressions into benign
placeholders before linting, so yamllint still validates the structural YAML
around them:

  - whole-line template actions (e.g. {{- $suite := ... -}}) are replaced
    with a "# __template__" comment to preserve line numbers and avoid
    empty-lines / scalar-vs-mapping breakage;
  - inline {{ ... }} expressions are replaced with the placeholder "x".

Modeled on the yamllint CLI: reads a config file and prints
"<file>:<line>:<col>: <level>: <desc> (<rule>)" for every problem.
"""

import re
import sys

from yamllint import linter
from yamllint.config import YamlLintConfig

WHOLE_LINE_TEMPLATE = re.compile(r"^\s*\{\{.*\}\}\s*$")
INLINE_TEMPLATE = re.compile(r"\{\{.*?\}\}")


def mangle(text: str) -> str:
    out: list[str] = []
    for line in text.splitlines():
        if WHOLE_LINE_TEMPLATE.match(line):
            out.append("# __template__")
        else:
            out.append(INLINE_TEMPLATE.sub("x", line))
    return "\n".join(out) + "\n"


def main(argv: list[str]) -> int:
    strict = False
    config_path: str | None = None
    files: list[str] = []
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--strict":
            strict = True
        elif arg in ("-c", "--config"):
            i += 1
            config_path = argv[i]
        elif arg.startswith("-c"):
            config_path = arg[2:].lstrip("=")
        elif arg.startswith("--config="):
            config_path = arg[len("--config=") :]
        elif not arg.startswith("-"):
            files.append(arg)
        i += 1

    if config_path is None:
        config = YamlLintConfig("extends: default")
    else:
        config = YamlLintConfig(file=config_path)

    failed = False
    for path in files:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        if "{{" in text:
            text = mangle(text)
        for problem in linter.run(text, config, filepath=path):
            if problem.level == "error" or (strict and problem.level == "warning"):
                failed = True
            if problem.level == "error" or strict:
                print(f"{path}:{problem.line}:{problem.column}: {problem.level}: {problem.desc} ({problem.rule})")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
