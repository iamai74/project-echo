# Test tools

Test infrastructure that supports the suites. This directory is **not** part of the test suite itself.

## Coverage runner

`coverage/run_coverage.py` measures statement-line coverage without adding a Godot dependency and without touching the working tree.

```sh
python3 test/tools/coverage/run_coverage.py
```

Requirements:

- Python 3.10 or newer;
- Godot 4 on `PATH`, or set `GODOT_BIN` / pass `--godot /path/to/godot`.

### Options

| Option | Effect |
|--------|--------|
| `--write-baseline` | Write `reports/coverage/baseline.json` from this run |
| `--enforce-gate` | Exit non-zero when the gate fails |
| `--keep-temp` | Keep the temporary instrumented project |
| `--skip-import` | Reuse an already imported `--keep-temp` copy |
| `--godot PATH` | Godot binary (`GODOT_BIN` is also read) |
| `--tests PATH` | GdUnit4 test path (default `res://test`) |
| `--output DIR` | Report directory (default `reports/coverage`) |
| `--baseline FILE` | Baseline used by the gate |

### What it does

1. Copies the project to a temporary directory, excluding `.git`, `.godot`, `reports` and editor caches.
2. Inserts `CoverageRecorder.hit(...)` before each executable statement line in the copy.
3. Adds the recorder as the first autoload in the copy only.
4. Imports the copy and runs the full GdUnit4 suite headless with `-c`, which disables GdUnit fail-fast so a failing case cannot stop a suite before the remaining tests are measured.
5. Reads the recorder output and writes the reports.

The working tree, its `.godot` cache and its Git state are never modified.

### Scope

- Measured: every `.gd` file under `scripts/` and `autoload/`.
- Excluded from targets: `scripts/world/debug/` and `scripts/theme/debug/`. They are still measured so the original baseline stays comparable.
- Not measured: `addons/` and `test/`.
- Metric: executable statement-line coverage. A line is a statement start when it is inside a function body and does not continue a multi-line expression, string, match arm or block header. `pass` lines are counted, matching the original baseline harness.
- Branch coverage is not measured.

### Outputs

Written under `reports/coverage/` (Git-ignored):

- `coverage.json` — totals, areas, per-file covered and uncovered lines, gate result;
- `lcov.info` — LCOV tracefile;
- `coverage.txt` — text summary, lowest coverage first;
- `index.html` — self-contained HTML report;
- `baseline.json` — reference baseline, written only with `--write-baseline`.

### Gate

The gate compares the current `target_totals` against `baseline.json`:

- overall drop larger than **0.5 percentage points** fails;
- any regression in a file already at or above **80%** fails.

The gate is informational by default. Pass `--enforce-gate` once the ratchet is enabled. Without a baseline file the gate is reported as not enforced.

### Instrumentation details

`coverage/instrumenter.py` scans each file, tracks bracket depth, string state, function bodies and multi-line signatures, then inserts a recorder call at the same indentation. Multi-line calls, dictionaries, typed function signatures, `match` arms, `else` / `elif` headers and annotations are not instrumented. `coverage/coverage_recorder.gd` stores hits and writes JSON on shutdown.

The measurement is deterministic: two consecutive runs against the same tree produce the same coverage data.
