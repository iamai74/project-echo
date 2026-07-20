# Bake Pipeline

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - world-authoring.md
> - world-architecture-overview.md
> - room-architecture.md
> - room-data.md
> - semantic-tiles.md
> - resources.md
> - resources-catalog.md
> - glossary.md

---

# Purpose

This document describes the Bake Pipeline used in Project Echo.

The Bake Pipeline converts designer-authored Room Scenes into optimized runtime assets used by the World Generator.

The main purpose of Bake is moving expensive content processing from gameplay runtime into the authoring stage.

---

# Overview

The complete pipeline:

```text
Room Scene

↓

Validation

↓

Data Extraction

↓

Runtime Room Generation

↓

Asset Storage

↓

World Generator
```

---

# Why Bake Exists

Project Echo does not generate worlds directly from authored scenes during gameplay.

Instead:

```text
Editor Time

↓

Process Content

↓

Create Runtime Data

↓

Gameplay Runtime
```

Benefits:

- predictable runtime performance;
- faster world generation;
- smaller runtime workload;
- validation before release;
- easier debugging.

---

# Input Data

The Bake process consumes authored Room data.

Input sources include:

```text
Room Scene

├── TileMap Layers
│
├── Collision Data
│
├── Entities
│
├── Connection Points
│
├── Semantic Tiles
│
└── Room Metadata
```

---

# Output Data

Bake produces a Runtime representation of the Room.

Conceptually:

```text
Room Scene

↓

Runtime Room
```

Runtime Room contains only data required during gameplay.

---

# Bake Stages

## 1. Scene Loading

The Bake process loads an authored Room Scene.

The scene represents the designer version of the room.

At this stage it may contain:

- editor helpers;
- brushes;
- authoring-only objects;
- temporary visualization.

---

## 2. Validation

Before generating runtime data, the Room must be validated.

Validation checks:

- required nodes exist;
- RoomData is present;
- Connection Points are valid;
- semantic information is consistent;
- required layers exist.

Example:

```text
Missing RoomData

↓

Bake Failed
```

---

## 3. Data Extraction

The Bake process extracts gameplay information.

Possible extracted data:

- room metadata;
- dimensions;
- connection points;
- semantic layout;
- entity placement;
- generation tags.

The goal is converting editor representation into gameplay data.

---

## 4. Runtime Room Generation

The extracted information is converted into Runtime Room data.

Conceptually:

```text
Authored Room

+

Metadata

+

Semantic Information

↓

Runtime Room
```

Runtime Room should not depend on editor-only objects.

---

## 5. Asset Storage

Generated Runtime Room assets are stored as project data.

The storage format should allow:

- fast loading;
- easy lookup;
- version control;
- regeneration after changes.

---

## 6. Database Update

After successful Bake, generated rooms become available for World Generation.

Conceptually:

```text
Runtime Room

↓

Room Database

↓

World Generator
```

The exact database implementation is not fixed yet.

---

# Runtime Flow

During gameplay:

```text
World Generator

↓

Room Database

↓

Runtime Room Selection

↓

Room Loading

↓

Playable Room
```

The game does not repeat the Bake process.

---

# Separation of Responsibilities

## Room Authoring

Responsible for:

- creating room layout;
- adding semantic information;
- defining metadata.

---

## Bake System

Responsible for:

- validation;
- conversion;
- runtime asset generation.

---

## Runtime

Responsible for:

- loading Runtime Rooms;
- assembling the world;
- running gameplay.

---

# Relationship With Semantic Tiles

Semantic Tiles are processed during Bake.

The authoring layer:

```text
Semantic Tile

↓

Gameplay Meaning
```

becomes runtime data:

```text
Runtime Room

↓

Generation Information
```

This allows visual themes to change without rebuilding gameplay structure.

---

# Relationship With RoomData

RoomData is extracted and preserved during Bake.

Example:

```text
RoomData

type = Combat

difficulty = 3

allowed_biomes = Morgue
```

The World Generator uses this information when selecting rooms.

---

# Error Handling

Bake should fail early when invalid content is detected.

Examples:

```text
Invalid Connection Point

↓

Bake Error
```

```text
Missing Room Metadata

↓

Bake Error
```

```text
Invalid Semantic Layer

↓

Bake Error
```

Authoring problems should be discovered before runtime.

---

# Editor Integration

The Bake system is expected to be integrated into Godot editor tooling.

Possible features:

- Bake selected Room;
- Bake all Rooms;
- Validate Room;
- Show Bake errors;
- Preview Runtime Room.

The exact editor implementation is not finalized.

---

# Design Principles

## Runtime Should Not Build Content

Expensive processing belongs in the editor.

---

## Generated Data Should Be Deterministic

The same Room Scene should always produce the same Runtime Room.

---

## Authoring Data and Runtime Data Are Different

Editor representation exists for designers.

Runtime representation exists for gameplay.

---

## Fail Early

Invalid content should be detected during Bake.

---

# Future Extensions

Possible future additions:

- automatic Room Database rebuilding;
- incremental Bake;
- Runtime Room previews;
- validation rules;
- dependency tracking;
- automated content checks.

---

# Decision Summary

The Bake Pipeline is the bridge between World Authoring and Runtime Generation.

Designers create Rooms.

Bake converts them into optimized Runtime Rooms.

World Generator uses Runtime Rooms to assemble the playable world.

This separation keeps procedural generation flexible while maintaining predictable runtime performance.

---

# Related Documents

- World Authoring
- World Architecture Overview
- Room Architecture
- Room Data
- Semantic Tiles
- Connection Points
- World Generation
