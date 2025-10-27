#!/usr/bin/env bash
set -euo pipefail

# Regenerates TESTS.md with a bullet list of real-world scenarios covered by
# the Foundry test suite. Scenario descriptions are taken from the leading
# comment inside each `test_*` function.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export UPDATE_TEST_SCENARIOS_ROOT="${ROOT_DIR}"

python3 <<'PY'
import os
import re
import sys
from pathlib import Path

root_env = os.environ.get("UPDATE_TEST_SCENARIOS_ROOT")
if not root_env:
    sys.stderr.write("[ERROR] UPDATE_TEST_SCENARIOS_ROOT not set.\n")
    sys.exit(1)

ROOT = Path(root_env)
TESTS_MD = ROOT / "TESTS.md"
TEST_FILES = [
    ROOT / "test" / "YurtFraction.t.sol",
]

START_MARKER = "<!-- TEST_SCENARIOS_START -->"
END_MARKER = "<!-- TEST_SCENARIOS_END -->"

if not TESTS_MD.exists():
    sys.stderr.write(f"[ERROR] TESTS.md not found: {TESTS_MD}\n")
    sys.exit(1)

scenarios = []
for path in TEST_FILES:
    if not path.exists():
        sys.stderr.write(f"[WARN] Test file missing: {path}\n")
        continue

    with path.open() as f:
        lines = f.readlines()

    current = None
    expecting_comment = False
    for line in lines:
        stripped = line.strip()

        if stripped.startswith("function test_"):
            match = re.match(r"function\s+(test_[A-Za-z0-9_]+)", stripped)
            current = match.group(1) if match else None
            expecting_comment = True
            continue

        if expecting_comment:
            if stripped.startswith("//"):
                description = stripped[2:].strip()
                scenarios.append((current, description))
                expecting_comment = False
            elif stripped == "":
                continue
            else:
                scenarios.append((current, ""))
                expecting_comment = False

# Deduplicate while preserving order.
deduped = []
seen = set()
for name, desc in scenarios:
    if name in seen:
        continue
    deduped.append((name, desc))
    seen.add(name)
scenarios = deduped

if not scenarios:
    sys.stderr.write("[WARN] No scenarios discovered; TESTS.md not modified.\n")
    sys.exit(0)

tests_text = TESTS_MD.read_text()
if START_MARKER not in tests_text or END_MARKER not in tests_text:
    sys.stderr.write(
        "[ERROR] TESTS.md is missing TEST_SCENARIOS markers.\n"
        f"Ensure the file contains both {START_MARKER} and {END_MARKER}.\n"
    )
    sys.exit(1)

start_index = tests_text.index(START_MARKER) + len(START_MARKER)
end_index = tests_text.index(END_MARKER)

lines = []
for name, desc in scenarios:
    if desc:
        lines.append(f"- {desc} (`{name}`)")
    else:
        lines.append(f"- `{name}`")

content = "\n" + "\n".join(lines) + "\n"
new_tests = tests_text[:start_index] + content + tests_text[end_index:]
TESTS_MD.write_text(new_tests)
print(f"Updated TESTS.md with {len(lines)} test scenario(s).")
PY
