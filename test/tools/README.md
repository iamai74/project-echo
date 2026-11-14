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
- Excluded from targets: the `report.py` rule names `scripts/world/debug/` and `scripts/theme/debug/`, but neither path exists in the current tree, so the refreshed baseline excludes 0 files / 0 statements.
- Not measured: `addons/` and `test/`.
- Not measured: `debug/scripts/`. It holds prototype scaffolding rather than production code: the `Walker`, `Runner` and `Heavy` enemy subclasses and two world debug drivers. `Walker` has unit tests (`test/unit/actors/test_walker.gd`), but none of these files is measured, so no coverage number describes them; `Runner`, `Heavy` and the drivers have no tests at all. The debug scenes are also the current playable entry point (`project.godot` `run/main_scene` points at `debug/scenes/test_scene.tscn`), so this is a real, accepted gap, not dead code.
- The `Actors` area covers `scripts/actors/` only: `player.gd` and `enemy.gd`. It is not a coverage figure for all actor code, because the enemy subclasses live under the unmeasured `debug/scripts/actors/`. Do not fold that directory into the target scope or the gate; if the prototypes are promoted to production code, measure them in a separate informational area.
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

The gate is informational unless `--enforce-gate` is passed; without a baseline file it is reported as not enforced.

**Project policy** — a manual local ratchet:

- Before merging changes that touch `scripts/`, `autoload/` or `test/`, run `python3 test/tools/coverage/run_coverage.py --enforce-gate` and treat a non-zero exit as a regression to fix or explicitly accept.
- Refreshing: run `--write-baseline` only from a green suite and only after the current gate passes, then re-run with `--enforce-gate` to confirm the new reference; never edit `baseline.json` by hand.
- CI: the repository has no CI job yet; when one is added it should run the same command with `--enforce-gate`. Until then, enforcement is manual.
- Location: the baseline lives under Git-ignored `reports/coverage/`, so it is per-machine and regenerable; it is not shared through Git, and a fresh clone starts without a baseline until one is generated.

### Baseline

The refreshed reference in `reports/coverage/baseline.json` (local, Git-ignored and regenerable — see the policy above):

- Generated `2026-11-14T10:32:57+00:00` with Godot `4.7.2.stable.official.ed1daf0bf`.
- Tests: 613 cases, 56 suites, 0 failures, 0 errors, 2 skipped, 0 orphans.
- Target coverage: 1413 / 1521 statements (92.9%).
- All measured files: 1413 / 1521 statements (92.9%); target and all-files statement coverage coincide because the refreshed baseline excludes no files and the 23 declaration-only files add no statements.
- Files with executed statements: 81 of 83 instrumentable.

### Instrumentation details

`coverage/instrumenter.py` scans each file, tracks bracket depth, string state, function bodies and multi-line signatures, then inserts a recorder call at the same indentation. Multi-line calls, dictionaries, typed function signatures, `match` arms, `else` / `elif` headers and annotations are not instrumented. `coverage/coverage_recorder.gd` stores hits and writes JSON on shutdown.

The measurement is deterministic: two consecutive runs against the same tree produce the same coverage data.
