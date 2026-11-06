# Connection Points

> **Status:** In Progress
>
> **Last Updated:** 2026-11-06
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

enum Side { TOP, BOTTOM, RIGHT, LEFT }

@export var id: StringName
@export var side: Side
@export var position: Vector2i
@export var size: Vector2i
```

`RoomData.connections` is typed as `Array[ConnectionData]`.

The current bake pipeline always produces an empty connection list. There is not yet:

- a connection authoring brush or marker;
- collection of connections during baking;
- validation of connection placement;
- world-generation consumer.

`ConnectionData` therefore defines the intended baked representation, not a completed authoring workflow.

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
