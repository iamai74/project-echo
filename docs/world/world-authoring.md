# World Authoring

> **Last Updated:** 2026-11-14
>
> **Related:**
> - [overview.md](overview.md)
> - [room-architecture.md](room-architecture.md)
> - [room-data.md](room-data.md)
> - [semantic-tiles.md](semantic-tiles.md)
> - [bake-pipeline.md](bake-pipeline.md)
> - [themes.md](themes.md)

---

# Purpose

This document describes the process of creating world content in Project Echo.

World authoring is the designer-facing stage that produces rooms which are later baked into runtime-ready data.

---

# Overview

```text
Designer
   │
   ▼
Authored Room Scene
   │
   ├── Room root with logical bounds (implemented)
   ├── Semantic brushes
   ├── Connection authoring    (implemented)
   └── Marker authoring        (implemented)
   │
   ▼
Bake Pipeline
   │
   ├── Semantic data
   ├── Validation
   ├── RoomData
   └── RuntimeRoom scene
   │
   ▼
Theme build / application
   │
   ▼
World Generator (planned)
   │
   ▼
Playable World
```

---

# Authoring Philosophy

Project Echo separates visual representation from gameplay meaning.

The designer authors spatial intent using semantic brushes. Visuals are supplied later by a theme.

```text
Spatial intent
      +
Semantic data
      +
Validation
      ↓
Runtime-ready room
```

This allows a room to be reused with different visual themes without changing its collision topology.

---

# Room as Authoring Unit

The primary authoring unit is the room.

A room represents:

- a playable area;
- a reusable world fragment;
- a generation building block.

An authored room scene may contain:

- semantic brushes;
- authoring helpers;
- editor visualization;
- future connection and marker authoring objects.

---

# Logical Room Bounds (implemented)

Authored rooms use an explicit playable rectangle via `RoomAuthoring.room_bounds`. Room extent is no longer derived from platform and wall cells.

The authoring contract is a `RoomAuthoring` root:

```gdscript
@tool
class_name RoomAuthoring
extends Node2D

@export var room_bounds: Rect2i
```

`room_bounds` is expressed in grid cells and describes the full playable rectangle, including empty air. It has an origin as well as a size because authored rooms may use negative grid coordinates.

Data ownership:

| Location | Meaning |
|----------|---------|
| `RoomAuthoring.room_bounds` | Authored logical playable rectangle |
| `RoomData.room_bounds` | Baked copy of the logical rectangle |
| `RoomData.geometry_bounds` | Derived extent of platform and wall cells |

Baking must not infer logical bounds from brushes, markers, connections or theme assets. The `RoomAuthoring` root and both `RoomData` fields are implemented.

---

# Authoring Structure

```text
Room Scene
├── RoomAuthoring root         (implemented)
├── PlatformBrush(es)
├── WallBrush(es)
├── BackgroundBrush(es)
├── Marker brushes            (implemented)
├── Volume brushes            (data model exists; authoring incomplete)
└── Connection authoring      (implemented)
```

All brushes are discovered recursively by `BrushCollector`. Brushes must inherit from `SemanticBrush` and return a non-`UNKNOWN` brush type to be collected.

---

# Semantic Brush Framework

A semantic brush is a `@tool` `Node2D` that describes an authoring operation.

Current base type:

```gdscript
@tool
class_name SemanticBrush
extends Node2D

enum BrushType {
    UNKNOWN,
    PLATFORM,
    WALL,
    BACKGROUND,
    MARKER,
    CONNECTION_POINT,
}
```

Common properties:

| Property | Description |
|----------|-------------|
| `enabled` | Uniform skip for baking and validation; disabled brushes are still collected but skipped by every processor and validator |
| `size` | Grid size in cells |
| `priority` | Reserved for overlap resolution |

Brushes convert their pixel position and size into grid coordinates using `World.settings.tile_size`.

---

# Implemented Brushes

## PlatformBrush

- Brush type: `PLATFORM`.
- Traits: `ONE_WAY`, `BREAKABLE`.
- Produces `SemanticSpatialPlatformCell` data.
- Overlapping platform cells are reported by `PlatformBakeProcessor` as `BRUSH_OVERLAP` errors.

## WallBrush

- Brush type: `WALL`.
- Produces `SemanticSpatialTopologyCell` data.
- Wall cells receive topology during post-processing.

## BackgroundBrush

- Brush type: `BACKGROUND`.
- Produces background cells.
- Background cells are not topology cells and are not part of room bounds.

## Marker and Volume Brushes

`MarkerBrush` is implemented and baked by `BakeMarkersStep`. `VolumeBrush` remains a placeholder; volume authoring is not implemented.

---

# Authoring Rules

## Grid alignment

Brushes are expected to align to the world tile grid.

`SemanticBrush.is_valid_brush()` checks that the brush position is a multiple of `World.settings.tile_size`.

## Overlap

Platforms and walls are separate semantic layers:

- duplicate cells within a layer are invalid;
- platform and wall cells may not overlap.

These rules are enforced during bake, not silently repaired.

## Meaning before appearance

Brushes must describe gameplay meaning rather than a specific biome's visuals. Visual selection belongs to themes.

---

# Bake Process

Bake converts authored brushes into runtime data.

```text
Room Scene
   │
   ▼
Collect brushes
   │
   ▼
Initialize semantic data
   │
   ▼
Run registered bake processors
   │
   ▼
Compute topology
   │
   ▼
Validate
   │
   ▼
Build RoomData + RuntimeRoom
   │
   ▼
Apply default theme
   │
   ▼
Save baked assets
```

See [bake-pipeline.md](bake-pipeline.md) for step and validator details.

---

# Bake Responsibilities

Bake is responsible for:

- collecting brushes;
- converting authoring brushes into semantic cells;
- computing platform/wall topology;
- validating semantic data;
- producing `RoomData`;
- constructing the runtime room scene;
- applying the default theme;
- saving baked assets.

Bake must happen before gameplay. Runtime does not repeat the bake process.

---

# Runtime Separation

Runtime uses baked output, not the authored room scene.

```text
Runtime uses:
RoomData
RuntimeRoom scene
ThemeInfo
```

Benefits:

- predictable runtime cost;
- no brush processing during gameplay;
- deterministic room structure;
- reusable visual themes.

---

# Designer Workflow

## 1. Create the room scene

Create a new scene containing semantic brush nodes. When logical room bounds land, use a `RoomAuthoring` root and set `room_bounds`; plain `Node2D` roots will bake without logical bounds.

## 2. Author spatial layout

Place `PlatformBrush`, `WallBrush` and `BackgroundBrush` nodes on the grid.

Use platform traits where appropriate.

## 3. Author gameplay data

Marker and connection authoring are implemented and baked. Volume authoring is still in progress.

## 4. Bake the room

Run the bake pipeline against the authored scene. Fix validation errors rather than bypassing them.

## 5. Inspect output

Generated files:

```text
scenes/rooms/<room_name>/<room_name>_room_data.tres
scenes/rooms/<room_name>/<room_name>_runtime.tscn
```

## 6. Build and apply a theme

Theme data is built separately from the room bake pipeline. The default theme is applied during bake.

See [themes.md](themes.md).

---

# Current Limitations

- There is no editor command or batch bake UI yet; bake is currently driven from debug/test scripts.
- Logical room bounds are authored through the `RoomAuthoring` root.
- Connection authoring and validation are implemented.
- Marker authoring and baking are implemented; volume authoring is not.
- Room metadata beyond semantic layout is not implemented.
- The runtime scene contains a single `TileMapLayer`; entities are not spawned during bake.

---

# Related Documents

- [World Overview](overview.md)
- [Room Architecture](room-architecture.md)
- [Room Data](room-data.md)
- [Semantic Tiles](semantic-tiles.md)
- [Bake Pipeline](bake-pipeline.md)
- [Themes](themes.md)
