# World Authoring

> **Last Updated:** 2026-07-20
>
> **Related**
>
> - world-architecture-overview.md
> - room-architecture.md
> - room-data.md
> - semantic-tiles.md
> - connection-points.md
> - world-generation.md
> - resources.md
> - glossary.md

---

# Purpose

This document describes the process of creating world content in Project Echo.

World Authoring is the process where designers create gameplay spaces that later become optimized runtime assets used by the World Generator.

The authoring pipeline separates:

- content creation;
- gameplay metadata;
- runtime optimization;
- procedural assembly.

---

# Overview

The complete world creation pipeline:

```text
Designer

↓

Room Scene

↓

Semantic Authoring

↓

Validation

↓

Bake

↓

Runtime Room

↓

World Generator

↓

Playable World
```

---

# Authoring Philosophy

Project Echo separates the visual representation of a room from its gameplay meaning.

The designer does not directly create procedural generation data.

Instead:

```text
Visual Layout

+

Semantic Information

+

Metadata

↓

Runtime Representation
```

---

# Room as Authoring Unit

The primary authoring unit is the Room.

A Room represents:

- a playable area;
- a reusable world fragment;
- a generation building block.

A Room contains:

- geometry;
- visual layers;
- gameplay elements;
- connection information;
- metadata.

---

# Room Authoring Structure

A typical authored Room:

```text
Room Scene

├── Visual Layers
│
├── Collision
│
├── Entities
│
├── Connection Points
│
└── Room Metadata
```

---

# Visual Authoring

Visual elements are created using TileMaps and authored assets.

The visual layer is responsible for:

- appearance;
- decoration;
- biome presentation.

Visual representation should not define gameplay rules.

---

# Semantic Authoring

Semantic layers describe gameplay meaning.

Examples:

```text
Floor

Wall

Platform

Obstacle

Decoration

Spawn Area

Connection Area
```

Semantic information allows the same gameplay structure to receive different visual themes.

Example:

```text
Semantic Floor

↓

Forest Biome

↓

Grass Tiles
```

or:

```text
Semantic Floor

↓

Morgue Biome

↓

Stone Tiles
```

---

# Brush Framework

World Authoring uses semantic brushes to simplify content creation.

A Brush represents a reusable authoring operation.

Examples:

- PlatformBrush
- WallBrush
- FloorBrush

A Brush defines:

- what semantic element is created;
- how it is placed;
- what metadata it generates.

---

# KitPiece

KitPiece represents a reusable world building element.

Examples:

- platform segment;
- wall section;
- room decoration;
- environment module.

KitPieces allow designers to create consistent rooms from reusable parts.

---

# Connection Authoring

Connections between rooms are represented through Connection Points.

A Connection Point defines:

- location;
- orientation;
- possible connection direction.

Example:

```text
Room A

[Connection Point]

		||

		||

[Connection Point]

Room B
```

The World Generator uses this information when assembling rooms.

---

# Room Metadata

Each Room contains metadata describing how it can be used.

Examples:

- room type;
- difficulty;
- biome restrictions;
- generation tags.

This information is stored through RoomData.

Example:

```text
RoomData

type = Combat

difficulty = 3

allowed_biomes = Morgue
```

---

# Bake Process

The Bake process converts authored content into runtime data.

Pipeline:

```text
Room Scene

↓

Validation

↓

Extract Metadata

↓

Generate Runtime Room

↓

Store Asset
```

---

# Bake Responsibilities

Bake is responsible for:

- validating room structure;
- collecting metadata;
- generating runtime representation;
- preparing data for World Generation.

Bake should happen before gameplay.

---

# Runtime Separation

The game does not use authored Room Scenes directly.

Runtime uses:

```text
Runtime Room
```

instead.

Benefits:

- faster loading;
- smaller runtime cost;
- predictable generation;
- reduced processing during gameplay.

---

# Designer Workflow

Typical workflow:

## 1. Create Room

Designer creates a new Room Scene.

---

## 2. Build Layout

Designer creates:

- floors;
- walls;
- platforms;
- decorations.

---

## 3. Add Semantic Information

Designer assigns gameplay meaning.

Example:

```text
This tile is a Floor

This area is Enemy Spawn

This point is Room Exit
```

---

## 4. Add Metadata

Designer defines:

- room type;
- difficulty;
- biome restrictions.

---

## 5. Bake

Room is converted into Runtime data.

---

## 6. Test

Runtime Room is tested inside the World Generator.

---

# Separation of Responsibilities

## Designer

Creates:

- room layout;
- semantic information;
- metadata.

---

## Bake System

Creates:

- runtime representation;
- optimized data.

---

## World Generator

Creates:

- final playable world.

---

# Design Principles

## Author Once, Reuse Many Times

Rooms should be reusable building blocks.

---

## Meaning Before Appearance

Gameplay semantics should not depend on visual assets.

---

## Runtime Should Be Predictable

Expensive processing should happen during authoring.

---

## Data Driven Generation

World Generator should consume prepared data instead of interpreting raw scenes.

---

# Future Extensions

Possible future systems:

- advanced room validation;
- procedural decoration;
- biome-specific dressing;
- automatic connection checking;
- editor visualization tools;
- room preview generation.

---

# Decision Summary

World Authoring in Project Echo is a data preparation pipeline.

Designers create Rooms using semantic tools.

Bake converts authored content into Runtime Rooms.

World Generator assembles Runtime Rooms into the final playable world.

This separation allows a flexible procedural world while keeping runtime performance predictable.

---

# Related Documents

- World Architecture Overview
- Room Architecture
- Room Data
- Semantic Tiles
- Connection Points
- World Generation
