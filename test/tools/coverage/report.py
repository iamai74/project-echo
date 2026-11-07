"""Coverage report generation and regression gate for Project Echo."""

from __future__ import annotations

import html
import json
from datetime import datetime, timezone
from pathlib import Path

AREA_NAMES = (
    "State machine",
    "Theme",
    "World / bake / semantic",
    "Core gameplay",
    "Actors",
    "Other",
)

OVERALL_DROP_LIMIT = 0.5
FILE_REGRESSION_FLOOR = 80.0

EXCLUDED_FILES = (
    ("scripts/world/debug/", "Debug driver"),
    ("scripts/theme/debug/", "Debug driver"),
)


def exclusion_for(path: str) -> str | None:
    for prefix, reason in EXCLUDED_FILES:
        if path.startswith(prefix):
            return reason
    return None


def area_for(path: str) -> str:
    if path.startswith("scripts/state_machine/"):
        return "State machine"
    if path.startswith("scripts/theme/"):
        return "Theme"
    if path.startswith("scripts/world/"):
        return "World / bake / semantic"
    if path.startswith("scripts/core/"):
        return "Core gameplay"
    if path.startswith("scripts/actors/"):
        return "Actors"
    if path == "autoload/world.gd":
        return "World / bake / semantic"
    return "Other"


def _percent(covered: int, statements: int) -> float:
    if statements == 0:
        return 0.0
    return round(covered * 100.0 / statements, 1)


def _line_ranges(lines: list[int]) -> str:
    if not lines:
        return ""
    ranges: list[str] = []
    start = previous = lines[0]
    for line in lines[1:]:
        if line == previous + 1:
            previous = line
            continue
        ranges.append(str(start) if start == previous else f"{start}-{previous}")
        start = previous = line
    ranges.append(str(start) if start == previous else f"{start}-{previous}")
    return ", ".join(ranges)


def build_report(
    statements: dict[str, list[int]],
    hits: dict[str, list[int]],
    test_summary: dict,
    godot_version: str,
) -> dict:
    files: list[dict] = []
    for path in sorted(statements):
        instrumentable = sorted(set(statements[path]))
        covered_lines = sorted(set(hits.get(path, [])) & set(instrumentable))
        uncovered = sorted(set(instrumentable) - set(covered_lines))
        exclusion_reason = exclusion_for(path)
        files.append(
            {
                "path": path,
                "area": area_for(path),
                "excluded": exclusion_reason is not None,
                "exclusion_reason": exclusion_reason,
                "statements": len(instrumentable),
                "covered": len(covered_lines),
                "percent": _percent(len(covered_lines), len(instrumentable)),
                "covered_lines": covered_lines,
                "uncovered_lines": uncovered,
                "uncovered_ranges": _line_ranges(uncovered),
            }
        )

    declaration_only = [file for file in files if file["statements"] == 0]
    instrumentable = [file for file in files if file["statements"] > 0]
    target_files = [file for file in instrumentable if not file["excluded"]]
    excluded_files = [file for file in instrumentable if file["excluded"]]

    total_statements = sum(file["statements"] for file in files)
    total_covered = sum(file["covered"] for file in files)

    target_statements = sum(file["statements"] for file in target_files)
    target_covered = sum(file["covered"] for file in target_files)
    excluded_statements = sum(file["statements"] for file in excluded_files)
    excluded_covered = sum(file["covered"] for file in excluded_files)

    areas: list[dict] = []
    for name in AREA_NAMES:
        area_files = [file for file in instrumentable if file["area"] == name]
        area_statements = sum(file["statements"] for file in area_files)
        area_covered = sum(file["covered"] for file in area_files)
        if not area_files:
            continue
        areas.append(
            {
                "name": name,
                "files": len(area_files),
                "statements": area_statements,
                "covered": area_covered,
                "percent": _percent(area_covered, area_statements),
            }
        )

    target_areas: list[dict] = []
    for name in AREA_NAMES:
        area_files = [file for file in target_files if file["area"] == name]
        area_statements = sum(file["statements"] for file in area_files)
        area_covered = sum(file["covered"] for file in area_files)
        if not area_files:
            continue
        target_areas.append(
            {
                "name": name,
                "files": len(area_files),
                "statements": area_statements,
                "covered": area_covered,
                "percent": _percent(area_covered, area_statements),
            }
        )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "godot_version": godot_version,
        "tests": test_summary,
        "totals": {
            "files": len(files),
            "instrumentable_files": len(instrumentable),
            "declaration_only_files": len(declaration_only),
            "files_with_hits": sum(1 for file in instrumentable if file["covered"] > 0),
            "statements": total_statements,
            "covered": total_covered,
            "percent": _percent(total_covered, total_statements),
        },
        "target_totals": {
            "files": len(target_files),
            "statements": target_statements,
            "covered": target_covered,
            "percent": _percent(target_covered, target_statements),
            "excluded_files": len(excluded_files),
            "excluded_statements": excluded_statements,
            "excluded_covered": excluded_covered,
        },
        "areas": areas,
        "target_areas": target_areas,
        "files": files,
    }


def evaluate_gate(
    current: dict,
    baseline: dict | None,
    overall_drop_limit: float = OVERALL_DROP_LIMIT,
    file_floor: float = FILE_REGRESSION_FLOOR,
) -> dict:
    if baseline is None:
        return {
            "enforced": False,
            "passed": True,
            "failures": [],
            "note": "No baseline report found; gate is informational.",
        }

    failures: list[dict] = []
    current_totals = current.get("target_totals", current["totals"])
    baseline_totals = baseline.get("target_totals", baseline["totals"])
    delta = round(current_totals["percent"] - baseline_totals["percent"], 1)

    if delta < -overall_drop_limit:
        failures.append(
            {
                "scope": "overall",
                "baseline": baseline_totals["percent"],
                "current": current_totals["percent"],
                "message": f"Overall coverage dropped {abs(delta):.1f} points "
                f"(limit {overall_drop_limit:.1f}).",
            }
        )

    current_files = {
        file["path"]: file for file in current["files"] if not file.get("excluded")
    }
    for baseline_file in baseline["files"]:
        if baseline_file.get("excluded"):
            continue
        if baseline_file["statements"] == 0 or baseline_file["percent"] < file_floor:
            continue
        current_file = current_files.get(baseline_file["path"])
        if current_file is None:
            failures.append(
                {
                    "scope": baseline_file["path"],
                    "baseline": baseline_file["percent"],
                    "current": None,
                    "message": "File is above the regression floor but no longer reported.",
                }
            )
            continue
        if current_file["percent"] < baseline_file["percent"]:
            failures.append(
                {
                    "scope": baseline_file["path"],
                    "baseline": baseline_file["percent"],
                    "current": current_file["percent"],
                    "message": f"File regression {baseline_file['percent']:.1f}% -> "
                    f"{current_file['percent']:.1f}%.",
                }
            )

    return {
        "enforced": True,
        "passed": not failures,
        "failures": failures,
        "overall_delta": delta,
        "overall_drop_limit": overall_drop_limit,
        "file_regression_floor": file_floor,
        "baseline_generated_at": baseline.get("generated_at"),
    }


def write_json(path: Path, report: dict) -> None:
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def write_lcov(path: Path, report: dict) -> None:
    records: list[str] = []
    for file in report["files"]:
        if file["statements"] == 0:
            continue
        records.append("TN:")
        records.append(f"SF:{file['path']}")
        records.append(f"LF:{file['statements']}")
        records.append(f"LH:{file['covered']}")
        covered = set(file["covered_lines"])
        for line in sorted(covered | set(file["uncovered_lines"])):
            records.append(f"DA:{line},{1 if line in covered else 0}")
        records.append("end_of_record")
    path.write_text("\n".join(records) + "\n", encoding="utf-8")


def write_text(path: Path, report: dict) -> None:
    totals = report["totals"]
    target = report.get("target_totals", totals)
    tests = report["tests"]
    lines = [
        "Project Echo coverage report",
        f"Generated: {report['generated_at']}",
        f"Godot: {report['godot_version']}",
        "",
        f"Tests: {tests.get('cases', '?')} cases, {tests.get('suites', '?')} suites, "
        f"{tests.get('failures', '?')} failures, {tests.get('errors', '?')} errors",
        f"Coverage (target scope): {target['covered']} / {target['statements']} "
        f"statements ({target['percent']}%)",
        f"Measured (all source files): {totals['covered']} / {totals['statements']} "
        f"statements ({totals['percent']}%)",
        f"Excluded from targets: {target.get('excluded_files', 0)} files, "
        f"{target.get('excluded_statements', 0)} statements "
        f"({target.get('excluded_covered', 0)} covered)",
        f"Files: {totals['files']} source files, "
        f"{totals['instrumentable_files']} instrumentable, "
        f"{totals['declaration_only_files']} declaration-only, "
        f"{totals['files_with_hits']} with executed statements",
        "",
        "By area (all source files):",
    ]
    for area in report["areas"]:
        lines.append(
            f"  {area['name']:<26} {area['covered']:>5} / {area['statements']:<5} "
            f"{area['percent']:>5.1f}%"
        )

    lines.extend(["", "By area (target scope):"])
    for area in report.get("target_areas", report["areas"]):
        lines.append(
            f"  {area['name']:<26} {area['covered']:>5} / {area['statements']:<5} "
            f"{area['percent']:>5.1f}%"
        )

    lines.extend(["", "By file (lowest coverage first):", ""])
    files = sorted(
        (file for file in report["files"] if file["statements"] > 0),
        key=lambda file: (file["percent"], file["path"]),
    )
    for file in files:
        range_note = f"  uncovered: {file['uncovered_ranges']}" if file["uncovered_lines"] else ""
        excluded_note = "  [excluded from targets]" if file["excluded"] else ""
        lines.append(
            f"  {file['percent']:>5.1f}%  {file['covered']:>4}/{file['statements']:<4} "
            f"{file['path']}{excluded_note}{range_note}"
        )

    declaration_only = [file["path"] for file in report["files"] if file["statements"] == 0]
    if declaration_only:
        lines.extend(["", "Declaration-only files:"])
        lines.extend(f"  {path}" for path in declaration_only)

    gate = report.get("gate")
    if gate:
        lines.extend(["", "Gate:"])
        if not gate["enforced"]:
            lines.append("  informational (no baseline)")
        else:
            lines.append(
                f"  {'PASSED' if gate['passed'] else 'FAILED'}"
                f" (overall delta {gate['overall_delta']:+.1f} points)"
            )
            for failure in gate["failures"]:
                lines.append(f"  - {failure['message']}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_html(path: Path, report: dict) -> None:
    totals = report["totals"]
    target = report.get("target_totals", totals)
    tests = report["tests"]
    gate = report.get("gate")

    def bar(percent: float) -> str:
        tone = "#2f9e44" if percent >= 80 else "#e8a317" if percent >= 60 else "#c92a2a"
        return (
            '<div class="bar"><span style="width:'
            f'{percent:.1f}%;background:{tone}"></span></div>'
        )

    area_rows = "\n".join(
        f"<tr><td>{html.escape(area['name'])}</td><td class='num'>{area['covered']} / "
        f"{area['statements']}</td><td class='num'>{area['percent']:.1f}%</td>"
        f"<td>{bar(area['percent'])}</td></tr>"
        for area in report.get("target_areas", report["areas"])
    )

    file_rows = "\n".join(
        f"<tr><td class='path'>{html.escape(file['path'])}"
        f"{' <span class=\"tag\">excluded</span>' if file.get('excluded') else ''}</td>"
        f"<td>{html.escape(file['area'])}</td>"
        f"<td class='num'>{file['covered']} / {file['statements']}</td>"
        f"<td class='num'>{file['percent']:.1f}%</td>"
        f"<td>{bar(file['percent'])}</td>"
        f"<td class='ranges'>{html.escape(file['uncovered_ranges'])}</td></tr>"
        for file in sorted(
            (file for file in report["files"] if file["statements"] > 0),
            key=lambda file: (file["percent"], file["path"]),
        )
    )

    if gate is None:
        gate_html = "<p>Not evaluated.</p>"
    elif not gate["enforced"]:
        gate_html = "<p class='muted'>Informational: no baseline report found.</p>"
    elif gate["passed"]:
        gate_html = (
            f"<p class='pass'>Passed. Overall delta {gate['overall_delta']:+.1f} points.</p>"
        )
    else:
        items = "".join(f"<li>{html.escape(item['message'])}</li>" for item in gate["failures"])
        gate_html = (
            f"<p class='fail'>Failed. Overall delta {gate['overall_delta']:+.1f} points.</p>"
            f"<ul>{items}</ul>"
        )

    document = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Project Echo coverage</title>
<style>
  :root {{
    color-scheme: light dark;
    --bg: #f7f7f8; --panel: #ffffff; --ink: #1d1f23; --muted: #6b7280;
    --line: #e5e7eb; --accent: #2f6feb;
  }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --bg:#14161a; --panel:#1c1f25; --ink:#e8eaed; --muted:#9aa0a6;
             --line:#2b3038; --accent:#7aa2ff; }}
  }}
  * {{ box-sizing: border-box; }}
  body {{ margin:0; padding:32px; background:var(--bg); color:var(--ink);
          font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }}
  main {{ max-width: 1180px; margin: 0 auto; }}
  h1 {{ margin: 0 0 4px; font-size: 26px; }}
  h2 {{ margin: 32px 0 12px; font-size: 18px; }}
  .muted {{ color: var(--muted); }}
  .cards {{ display:grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap:12px; margin:24px 0; }}
  .card {{ background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:16px; }}
  .card .label {{ color:var(--muted); font-size:12px; text-transform:uppercase;
                  letter-spacing:.06em; }}
  .card .value {{ font-size:26px; font-weight:650; margin-top:4px; }}
  table {{ width:100%; border-collapse:collapse; background:var(--panel);
           border:1px solid var(--line); border-radius:10px; overflow:hidden; }}
  th, td {{ padding:9px 12px; border-bottom:1px solid var(--line); text-align:left;
            vertical-align:top; }}
  th {{ font-size:12px; text-transform:uppercase; letter-spacing:.05em; color:var(--muted); }}
  tr:last-child td {{ border-bottom:none; }}
  td.num {{ font-variant-numeric: tabular-nums; white-space:nowrap; }}
  td.path {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:12.5px; }}
  td.ranges {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
               font-size:12px; color:var(--muted); max-width:260px; }}
  .tag {{ display:inline-block; margin-left:6px; padding:1px 6px; border-radius:99px;
          background:var(--line); color:var(--muted); font-size:11px; }}
  .bar {{ width:120px; height:7px; border-radius:99px; background:var(--line); overflow:hidden; }}
  .bar span {{ display:block; height:100%; }}
  .pass {{ color:#2f9e44; font-weight:600; }}
  .fail {{ color:#c92a2a; font-weight:600; }}
</style>
</head>
<body>
<main>
  <h1>Project Echo coverage</h1>
  <p class="muted">Generated {html.escape(report['generated_at'])} with
     {html.escape(report['godot_version'])}.</p>

  <div class="cards">
    <div class="card"><div class="label">Target statements</div>
      <div class="value">{target['percent']:.1f}%</div>
      <div class="muted">{target['covered']} / {target['statements']}</div></div>
    <div class="card"><div class="label">Tests</div>
      <div class="value">{tests.get('cases', '?')}</div>
      <div class="muted">{tests.get('suites', '?')} suites,
        {tests.get('failures', '?')} failures</div></div>
    <div class="card"><div class="label">Source files</div>
      <div class="value">{totals['instrumentable_files']}</div>
      <div class="muted">{totals['declaration_only_files']} declaration-only</div></div>
    <div class="card"><div class="label">Files executed</div>
      <div class="value">{totals['files_with_hits']}</div>
      <div class="muted">of {totals['instrumentable_files']} instrumentable</div></div>
  </div>
  <p class="muted">Measured across all {totals['files']} source files:
     {totals['covered']} / {totals['statements']} statements
     ({totals['percent']:.1f}%). Targets exclude
     {target.get('excluded_files', 0)} debug files and
     {target.get('excluded_statements', 0)} statements.</p>

  <h2>Gate</h2>
  {gate_html}

  <h2>By area</h2>
  <table>
    <thead><tr><th>Area</th><th>Covered</th><th>Percent</th><th></th></tr></thead>
    <tbody>{area_rows}</tbody>
  </table>

  <h2>By file</h2>
  <p class="muted">Lowest coverage first. Uncovered columns list statement lines.</p>
  <table>
    <thead><tr><th>File</th><th>Area</th><th>Covered</th><th>Percent</th><th></th>
      <th>Uncovered lines</th></tr></thead>
    <tbody>{file_rows}</tbody>
  </table>
</main>
</body>
</html>
"""
    path.write_text(document, encoding="utf-8")
