# Room Data

> **Status:** Stable
>
> **Last Updated:** 2026-11-06
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

@export var version: int = 1
@export var bounds: Rect2i

@export var platforms: Array[SemanticCell]
@export var walls: Array[SemanticCell]
@export var background: Array[BackgroundCell]

@export var connections: Array[ConnectionData]
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | `int` | Format version, currently `1` |
| `bounds` | `Rect2i` | Bounding rectangle computed from platform and wall cells |
| `platforms` | `Array[SemanticCell]` | Platform cells |
| `walls` | `Array[SemanticCell]` | Wall cells |
| `background` | `Array[BackgroundCell]` | Background cells |
| `connections` | `Array[ConnectionData]` | Room connection data; currently empty |

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

enum Side { TOP, BOTTOM, RIGHT, LEFT }

@export var id: StringName
@export var side: Side
@export var position: Vector2i
@export var size: Vector2i
```

The data type exists and is part of `RoomData`, but connection authoring, baking and validation are not implemented yet.

See [connection-points.md](connection-points.md).

---

# Creation

`RoomDataBuilder` creates `RoomData` from `SemanticRoomData`:

- platform cells come from the `PLATFORM` spatial layer;
- wall cells come from the `WALL` spatial layer;
- background cells come from the `BACKGROUND` spatial layer;
- `bounds` is computed from platform and wall cells only;
- `connections` is left empty.

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

# Related Documents

- [Room Architecture](room-architecture.md)
- [Semantic Tiles](semantic-tiles.md)
- [Bake Pipeline](bake-pipeline.md)
- [Resources](../architecture/resources.md)
- [ADR-004](../adr/ADR-004-room-data-as-resource.md)
