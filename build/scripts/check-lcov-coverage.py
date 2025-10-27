#!/usr/bin/env python3
"""
Fail the build if any Solidity contract under src/ has line coverage below 100%.
Parses the LCOV report emitted by `forge coverage --report lcov --out lcov.info`.
"""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path.cwd().resolve()
    lcov_path = root / "lcov.info"

    if not lcov_path.exists():
        print(f"[ERROR] LCOV report not found at {lcov_path}", file=sys.stderr)
        return 1

    current: Path | None = None
    tracked = False
    lf = None
    lh = None
    failures: list[tuple[Path, int, int]] = []

    with lcov_path.open() as fh:
        for raw_line in fh:
            line = raw_line.strip()

            if line.startswith("SF:"):
                source_path = Path(line[3:]).resolve()
                try:
                    rel = source_path.relative_to(root)
                except ValueError:
                    rel = source_path
                current = rel
                tracked = str(rel).startswith("src/")
                lf = lh = None
                continue

            if line.startswith("LF:"):
                lf = int(line[3:])
                continue

            if line.startswith("LH:"):
                lh = int(line[3:])
                continue

            if line == "end_of_record":
                if tracked and lf not in (None, 0):
                    hits = 0 if lh is None else lh
                    if hits != lf:
                        failures.append((current, hits, lf))  # type: ignore[arg-type]
                current = None
                tracked = False
                lf = lh = None

    if failures:
        print("[COVERAGE] Expected 100% line coverage for contracts under src/, got:")
        for path, hits, total in failures:
            print(f" - {path}: {hits}/{total} lines covered")
        return 1

    print("[COVERAGE] 100% line coverage for all contracts under src/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
