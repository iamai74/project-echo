# Room Data

> **Status:** Stable
>
> **Last Updated:** 2026-11-14
>
> **Related:**
> - [room-architecture.md](room-architecture.md)
> - [semantic-tiles.md](semantic-tiles.md)
> - [bake-pipeline.md](bake-pipeline.md)
> - [../architecture/resources.md](../architecture/resources.md)
> - [ADR-004 — Store RoomData as a Godot Resource](../adr/ADR-004-room-data-as-resource.md)

---

# Purpose

`RoomData` stores the validated semantic layout of a baked room.

It describes room geometry in a runtime-ready form and is independent from runtime gameplay state.

---

# Storage

`RoomData` is a Godot `Resource` with `class_name RoomData`.

Bake output is written to:

```text
res://scenes/rooms/<room_basename>/<room_basename>_room_data.tres
```

The generated runtime scene is written next to it as:

```text
res://scenes/rooms/<room_basename>/<room_basename>_runtime.tscn
```

The authored room scene remains the source of truth. Baked files should be regenerated rather than edited by hand.

---

# Structure

```gdscript
class_name RoomData
extends Resource

@export var version: int = 2
@export var room_bounds: Rect2i
@export var geometry_bounds: Rect2i

@export var platforms: Array[SemanticCell]
@export var walls: Array[SemanticCell]
@export var background: Array[BackgroundCell]

@export var markers: Array[MarkerData]
@export var connections: Array[ConnectionData]
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | `int` | Format version, currently `2` |
| `room_bounds` | `Rect2i` | Authored logical playable rectangle; empty in version 1 resources |
| `geometry_bounds` | `Rect2i` | Derived extent of platform and wall cells; legacy `bounds` loads as `geometry_bounds` |
| `platforms` | `Array[SemanticCell]` | Platform cells |
| `walls` | `Array[SemanticCell]` | Wall cells |
| `background` | `Array[BackgroundCell]` | Background cells |
| `markers` | `Array[MarkerData]` | Authored marker placements |
| `connections` | `Array[ConnectionData]` | Room connection data |

## Version 1 compatibility

Version 1 `RoomData` resources (with `version: 1` and legacy `bounds` field) remain read-only compatible. On load:

- `bounds` → `geometry_bounds` (the legacy bounding extent)
- `room_bounds` → empty `Rect2i(0, 0, 0, 0)`
- `markers` → empty array
- `connections` → empty array
- `version` stays `1`; does not auto-upgrade

New resources should set `version: 2` and populate `room_bounds` and `geometry_bounds` explicitly. Do not hand-edit generated resources.

---

# SemanticCell

Platform and wall cells use `SemanticCell`:

```gdscript
class_name SemanticCell
extends Resource

@export var position: Vector2i
@export var shape: CellShape.Value
@export var corners: CellCorner.Value
@export var flags: int
```

| Field | Description |
|-------|-------------|
| `position` | Grid position |
| `shape` | Topology shape (`SINGLE`, `TOP`, `BOTTOM`, `LEFT`, `RIGHT`, `FULL`) |
| `corners` | Topology corner variant |
| `flags` | Reserved; not currently populated |

`shape` and `corners` are copied from `SpatialTopology` by `RoomDataBuilder`.

---

# BackgroundCell

```gdscript
class_name BackgroundCell
extends Resource

@export var position: Vector2i
```

Background cells currently carry only a position.

---

# ConnectionData

```gdscript
class_name ConnectionData
extends Resource

@export var id: StringName
@export var side: ConnectionSide.Value
@export var position: Vector2i
@export var size: Vector2i
```

Connection authoring, baking and validation are implemented; see [connection-points.md](connection-points.md).

See [connection-points.md](connection-points.md).

---

# Creation

`RoomDataBuilder` creates `RoomData` from `SemanticRoomData`:

- platform cells come from the `PLATFORM` spatial layer;
- wall cells come from the `WALL` spatial layer;
- background cells come from the `BACKGROUND` spatial layer;
- `room_bounds` is copied from the authored `RoomAuthoring.room_bounds`; `geometry_bounds` is computed from platform and wall cells only;
- `connections` are copied from `context.connections` (produced by `BakeConnectionsStep`).

The builder is invoked by `BuildRuntimeRoomStep` after validation and post-processing.

---

# Runtime Data

`RoomData` never stores:

- player position;
- enemy health;
- opened chests;
- destroyed objects;
- active timers;
- current tile visuals.

Runtime state belongs to gameplay systems.

Tile selection belongs to theme application, not `RoomData`.

---

# Design Rationale

Storing baked room layout as a Resource allows:

- editor-friendly inspection;
- reusable room assets;
- deterministic bake output;
- separation from authoring brushes;
- consumption by runtime construction and future world generation.

A generated runtime scene is stored alongside it so that runtime does not need to rebuild room structure.

---

# Artifact Ownership

The table lists each artifact location, its kind, whether it is Git-tracked, and how it is regenerated.

The production directory is the configured destination and is not populated yet: no production room has been baked, so `res://scenes/rooms/` does not exist. All baked rooms currently tracked in the repository live under `res://debug/scenes/rooms/`.

| Location | Kind | Tracked | Regeneration |
|---|---|---|---|
| `res://scenes/rooms/<room_basename>/` | Production baked rooms (`*_room_data.tres`, `*_runtime.tscn`) | Yes — runtime assets required for execution | Re-run the production bake pipeline |
| `res://debug/scenes/rooms/<room_basename>/` | Debug bake output | Yes — regeneration not proven (ART-4 failed); keep tracked | Re-run the debug bake pipeline; output is not currently reproducible (see `docs/task/art-4-result.md`) |
| `user://test_<suite>/<room_basename>/` | Test/temporary artifacts | No — outside the repository | Re-run the relevant test suite |
| `res://resources/themes/{theme}/` | Built theme resources (`*_tile_assets.tres`, `*_theme.tres`, `*_tileset.tres`) | Yes — intentionally version-controlled | Re-run the theme build pipeline |
| `res://assets/sprites/themes/{theme}/` | Theme source assets | Yes — source of truth | Edit source assets, then rebuild |

Rules:

- `SaveRoomDataStep.output_root` defaults to `DEFAULT_OUTPUT_ROOT` (`res://scenes/rooms`).
- Tests override `output_root` to a `user://test_<suite>` root in `before_test` and remove it in `after_test`.
- Debug bake sets `output_root` to the debug root before running the pipeline.
- Debug rooms stay tracked until regeneration is proven. ART-4 found that four of the six tracked files have no source scene and the two reproducible files differ on every run, so they must not be ignored or removed.
- Production bake never writes to `user://`.
- `.gitignore` must not gain a blanket `scenes/rooms/` or `resources/themes/` entry.

---

# Related Documents

- [Room Architecture](room-architecture.md)
- [Semantic Tiles](semantic-tiles.md)
- [Bake Pipeline](bake-pipeline.md)
- [Resources](../architecture/resources.md)
- [ADR-004](../adr/ADR-004-room-data-as-resource.md)
