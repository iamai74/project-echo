# World Authoring Architecture

**Status:** Vision

---

# 1. Purpose

This document describes the high-level vision of the World Authoring system.

It intentionally avoids implementation details.

The implementation of each subsystem will be documented separately when development reaches that stage.

---

# 2. Vision

The game world should not be created by manually building gameplay scenes.

Instead, rooms are created through dedicated authoring tools and then transformed into runtime assets.

The expected workflow is:

Authoring Scene
		│
		▼
	 Brushes
		│
		▼
   Room Builder
		│
		▼
	   Bake
		│
		▼
   Runtime Room
		│
		▼
 World Generator

The runtime uses only baked rooms.

---

# 3. Goals

The World Authoring system should:

- separate editor-only data from runtime data;
- make room creation fast and repeatable;
- allow designers to iterate without manually rebuilding rooms;
- prepare the project for procedural world generation;
- remain easy to extend as the project grows.

---

# 4. Architectural Principles

## 4.1 Single Source of Truth

The Authoring Scene is the only source of truth.

All room modifications are performed there.

Runtime Rooms are generated artifacts and must never be edited manually.

```
Authoring Scene
		│
		▼
	   Bake
		│
		▼
   Runtime Room
```

If a room needs to be changed, the Authoring Scene must be updated and baked again.

---

## 4.2 Bake is Part of the Build Pipeline

Bake is performed before gameplay.

The game should not perform work that can be completed during content creation.

Examples include:

- TileMaps
- Collision
- Navigation
- Decorations
- Metadata
- Spawn data

---

## 4.3 Runtime Must Stay Lightweight

Runtime contains only gameplay data.

Editor-only systems such as:

- Brushes
- Room Builder
- Bake logic

must never exist during gameplay.

---

## 4.4 Build Functionality First

The first goal is correctness.

The second goal is quality.

### Stage 1

- reliable room generation;
- correct geometry;
- biome tile assignment;
- playable rooms.

### Stage 2

- smarter Brushes;
- better tile variation;
- improved decoration;
- visual polish;
- additional automation.

---

## 4.5 Avoid Premature Optimization

Complex systems should only be introduced when they solve an existing problem.

Examples:

- Bake Cache
- Incremental Bake
- Parallel Bake
- Asset dependency tracking

These are intentionally out of scope for the MVP.

---

# 5. Decisions

The following decisions have been made.

## Runtime Rooms

Runtime Rooms are stored on disk.

The game loads pre-built rooms only.

Rooms are never baked during gameplay.

---

## Bake Cache

Bake Cache is not part of the MVP.

If Bake later becomes slow enough to impact development, this decision can be revisited.

---

## Brush Intelligence

Brushes will evolve gradually.

The initial goal is correctness.

Visual improvements will be added after the authoring pipeline is stable.

---

## Runtime Editing

Runtime Rooms are never edited manually.

If a Runtime Room requires a manual fix, the Authoring workflow or Bake pipeline should be improved instead.

---

# 6. MVP Roadmap

Phase 1

1. Design World Authoring Architecture
2. Design Room Scene Architecture
3. Create Brush Framework
4. Implement PlatformBrush
5. Implement Room Builder
6. Implement Bake Plugin
7. Bake First Room

Each stage will be designed immediately before implementation.

---

# 7. Open Questions

The following topics will be designed in separate documents.

- Authoring Scene Architecture
- Brush Framework
- Room Builder
- Intermediate Room Model
- Bake Plugin
- Runtime Room Architecture

---

# 8. Documentation Philosophy

Project Echo follows an incremental architecture process.

Every architecture document evolves through three stages.

## Vision

High-level ideas and project direction.

## Design

Detailed design prepared immediately before implementation.

## Final

Documentation reflecting the implemented system.

Documentation should evolve together with the project rather than attempting to predict every future decision.
