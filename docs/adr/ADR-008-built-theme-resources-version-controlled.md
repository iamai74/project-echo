# ADR-008: Built Theme Resources Are Version-Controlled

> **Status:** Accepted
>
> **Date:** 2026-11-18

---

# Context

The theme build pipeline (`ThemeBuilder`) generates three resources per theme under
`res://resources/themes/{theme}/`:

```text
{theme}_tile_assets.tres
{theme}_theme.tres
{theme}_tileset.tres
```

These are generated from source assets (`res://assets/sprites/themes/{theme}/`), so
they could in principle be treated as disposable build artifacts. Remediation task T-16
raised whether `resources/themes/default/*.tres` should remain Git-tracked or be gitignored
as regenerable output.

Two candidate decisions:

- **Option A** — keep them tracked as intentionally version-controlled shipped assets.
- **Option B** — gitignore them as regenerable build artifacts and untrack the files.

---

# Decision

Built theme resources are **intentionally version-controlled** (Option A).

`res://resources/themes/{theme}/` stays Git-tracked. `.gitignore` gains **no** entry for
`resources/themes/`. No tracked theme resource is removed.

Rationale:

- the default theme is a shipped asset that ships with the project, not a transient build
  cache;
- tracking the built resources makes the shipped theme inspectable and reviewable in a
  normal diff, so a change to theme output is visible without re-running the pipeline;
- the source assets remain the source of truth, so the generated `.tres` files are still
  regenerated from `res://assets/sprites/themes/{theme}/` by `ThemeBuilder` — tracking them
  does not make them a competing source of truth.

The decision is recorded in the artifact ownership table of
[room-data.md](../world/room-data.md#artifact-ownership).

---

# Consequences

Benefits:

- shipped theme is always present in a fresh clone, without a required build step;
- theme output changes surface in code review.

Trade-offs:

- generated `.tres` files are checked in, which is acceptable because they are deterministic
  and regenerable;
- a future theme that is intentionally disposable should be reviewed against this ADR before
  it is gitignored.

---

# Related

- [room-data.md — Artifact Ownership](../world/room-data.md#artifact-ownership)
- [themes.md](../world/themes.md)
