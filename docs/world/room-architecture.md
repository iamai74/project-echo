# Room Architecture

> **Status:** In Progress
>
> **Last Updated:** 2026-11-14
>
> **Related:**
> - [overview.md](overview.md)
> - [room-data.md](room-data.md)
> - [semantic-tiles.md](semantic-tiles.md)
> - [bake-pipeline.md](bake-pipeline.md)
> - [themes.md](themes.md)

---

# Purpose

A room is the fundamental gameplay building block of Project Echo.

Instead of generating gameplay from individual tiles during runtime, the game assembles worlds from rooms that were authored and baked in advance.

---

# Room Representations

A room is not a single object. It has three separate representations with different responsibilities.

## 1. Authored Room Scene

The authored scene is the designer-facing source of truth. It contains:

- semantic brushes for platforms, walls and background;
- authoring-only nodes;
- editor visualization;
- planned `RoomAuthoring` root carrying explicit logical room bounds.

Semantic brushes are `@tool` nodes. They describe intent and draw editor previews, but they do not bake rooms or construct runtime content.

## 2. Baked Room Data

The bake pipeline converts authored data into:

- `RoomData` — a `Resource` containing validated semantic cells;
- a generated runtime room scene;
- an optional theme applied to that scene.

Baked output is stored under `scenes/rooms/<room_name>/`.

## 3. Runtime Room

The generated runtime scene is instantiated during gameplay.

Current structure:

```text
RuntimeRoom (Node2D)
└── Semantic (Node2D)
    └── Tiles (TileMapLayer)
```

`RuntimeRoomBuilder` creates only this structure. It does not create tiles.

`ThemeApplyer` finds `Semantic/Tiles` and populates it using `ThemeInfo` and `RoomData`.

---

# Responsibilities

A room is responsible for containing, in its authored or baked form:

- geometry;
- gameplay layout;
- semantic information;
- connection data;
- metadata required by generation.

A room is **not** responsible for:

- procedural world generation;
- selecting its biome;
- choosing its visual theme;
- runtime gameplay state.

---

# Logical and Geometry Bounds (planned)

A room needs two distinct rectangles. They have different owners and must not be conflated.

| Rectangle | Meaning | Source |
|-----------|---------|--------|
| Logical room bounds | Full playable area, including empty air | Authored `RoomAuthoring.room_bounds` |
| Geometry bounds | Extent occupied by platform and wall cells | Derived from final spatial cells |

Planned data flow:

```text
RoomAuthoring.room_bounds
        │
        ▼
RoomBakeContext.room_bounds
        │
        ▼
BuildRuntimeRoomStep / RoomDataBuilder
        │
        ▼
RoomData.room_bounds

platform + wall cells
        │
        ▼
GeometryBounds
        │
        ▼
RoomDataBuilder
        │
        ▼
RoomData.geometry_bounds
```

Rules:

- logical bounds must not be calculated from platform or wall cells;
- geometry bounds must not define playable space;
- marker and connection placement is checked against logical bounds;
- geometry checks and diagnostics may use geometry bounds;
- neither rectangle belongs to a theme.

The current implementation has a single geometry-derived `RoomData.bounds`. The `RoomAuthoring` root and the `RoomData.room_bounds` / `RoomData.geometry_bounds` split are planned, not implemented.

---

# Room Composition

```mermaid
flowchart TD

    Room["Authored Room Scene"]

    Room --> Brushes["Semantic Brushes"]
    Room --> Metadata["Room metadata / connection data"]

    Brushes --> Bake["Bake Pipeline"]
    Metadata --> Bake

    Bake --> RoomData["RoomData"]
    Bake --> RuntimeScene["RuntimeRoom scene"]

    RoomData --> ThemeApply["ThemeApplyer"]
    RuntimeScene --> ThemeApply
```

---

# Runtime Lifecycle

```mermaid
flowchart LR

    Authored["Authored Room"] --> Bake["Bake"]
    Bake --> Baked["RoomData + RuntimeRoom scene"]
    Baked --> Instantiate["Instantiate RuntimeRoom"]
    Instantiate --> Theme["Apply theme"]
    Theme --> Gameplay["Gameplay"]
    Gameplay --> Unload["Unload"]
```

Runtime does not repeat the bake process.

---

# Authoring Boundaries

## Brushes

Brushes are authoring objects. They:

- have a grid position and size;
- know their brush type;
- may carry traits such as `ONE_WAY` or `BREAKABLE`;
- are collected recursively from the room scene.

Brushes do not:

- perform bake operations;
- know about bake steps or processors;
- construct `TileMap` content;
- apply themes.

## Bake Steps

Bake steps transform data:

- collect brushes;
- initialize semantic data;
- run processors;
- compute topology;
- validate;
- build `RoomData` and the runtime scene;
- apply the default theme;
- save the output.

## Runtime

Runtime is responsible for:

- instantiating baked runtime rooms;
- assembling the world;
- running gameplay.

---

# Visual Representation

Visual representation is applied by themes, not by room authoring.

A room can be reused with different themes as long as its semantic layout remains compatible.

Examples:

```text
Semantic platform
→ default theme
→ platform tiles
```

```text
Semantic platform
→ forest theme (planned)
→ grass/wood platform tiles
```

A theme must not change collision topology or gameplay semantics.

---

# Design Philosophy

Rooms are authored once and reused many times.

The procedural generator assembles rooms instead of constructing geometry from scratch.

This provides:

- predictable gameplay;
- better runtime performance;
- designer control;
- easier balancing;
- visual variety through themes.

---

# Current Limitations

- The room database and world generator are not implemented.
- Rooms have no explicit logical bounds. `RoomData.bounds` is currently derived from platform and wall cells; the planned `RoomAuthoring.room_bounds` and `RoomData.room_bounds` / `RoomData.geometry_bounds` split are not implemented.
- Connections are represented by `ConnectionData`, but no authoring or bake path populates `RoomData.connections` yet.
- Marker and volume layers are not baked.
- Runtime room construction currently creates a single `TileMapLayer` named `Tiles`.
- The default theme is applied during bake; biome-driven theme selection is planned.

---

# Related Documents

- [World Overview](overview.md)
- [Room Data](room-data.md)
- [Semantic Tiles](semantic-tiles.md)
- [Bake Pipeline](bake-pipeline.md)
- [Themes](themes.md)
