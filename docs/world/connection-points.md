# Connection Points

> **Status:** Implemented
>
> **Last Updated:** 2026-11-14
>
> **Related:**
> - [room-architecture.md](room-architecture.md)
> - [room-data.md](room-data.md)
> - [world-generation.md](world-generation.md)
> - [../adr/ADR-007-use-connection-points.md](../adr/ADR-007-use-connection-points.md)

---

# Purpose

Connection points describe where a room may connect to other rooms.

They are the interface between handcrafted room authoring and procedural world assembly.

---

# Design Principle

A connection point is an explicit design element.

It must not be inferred automatically from room geometry, such as by scanning for openings in walls.

This keeps room intent under designer control and avoids coupling world generation to tile layout.

---

# Current Implementation

The baked data model exists:

```gdscript
class_name ConnectionData
extends Resource

@export var id: StringName
@export var side: ConnectionSide.Value
@export var position: Vector2i
@export var size: Vector2i
```

`RoomData.connections` is typed as `Array[ConnectionData]`.

## Authoring

Connection points are authored using `ConnectionPointBrush` in the room scene. Designers place connection point brushes on room exits to designate where rooms may connect.

Connection points must have:

- **explicit, non-empty ID** (`StringName`) - required, no bake-time generation;
- **room-local side** (`ConnectionSide`) - which room side the connection belongs to;
- **position** - in the room local grid;
- **size** - the opening size (`Vector2i`).

## Baking

The bake pipeline collects `ConnectionPointBrush` instances and produces `ConnectionData` entries. The bake copies the authored ID verbatim and never generates, rewrites or falls back to one.

## Validation

Three new validators operate on connection points:

1. `ConnectionPointValidator` - validates connection geometry, boundary, orientation, emptiness, ID uniqueness and overlap.

Connection point validation errors remain in the report and should be fixed at the authoring source; they do not automatically abort the pipeline unless escalated to fatal.

---

## Planned identity contract

The authoring and bake path requires:

- an explicit, non-empty ID on every connection point;
- room-local IDs that stay stable when other connections are added, removed or reordered;
- unique IDs per room, with duplicates and empty IDs reported as validation errors;
- bake copies the authored ID verbatim and never generates, rewrites or falls back to one.

The ID is design data, not a bake artifact.

---

# Responsibilities

A connection point describes:

- identity (`id`);
- the room side it belongs to (`side`);
- its position in the room;
- its opening size (`size`).

It is **not** responsible for:

- spawning rooms;
- validating world layouts;
- performing procedural generation;
- modifying room contents;
- choosing a biome or theme.

Its purpose is purely descriptive.

---

# Intended Usage

Connection points are planned to support:

- room graph generation;
- compatibility validation between adjacent rooms;
- biome and generation constraints;
- room streaming boundaries.

These consumers do not exist yet.

---

# Relationship to Room Data

Connections are part of `RoomData`:

```text
RoomData
├── platforms
├── walls
├── background
└── connections → ConnectionData[]
```

See [room-data.md](room-data.md) for the full resource structure.

Because connections live in `RoomData`, they survive independently of the visual theme and of the generated runtime scene.

---

# ADR

The decision to model connections as explicit objects is recorded in [ADR-007](../adr/ADR-007-use-connection-points.md).

The ADR uses the term **ConnectionPoint**. The implemented baked data type is `ConnectionData`; the two names refer to the same architectural concept at different stages.

---

# Related Documents

- [Room Architecture](room-architecture.md)
- [Room Data](room-data.md)
- [World Generation](world-generation.md)
- [ADR-007 — Use Connection Points](../adr/ADR-007-use-connection-points.md)
