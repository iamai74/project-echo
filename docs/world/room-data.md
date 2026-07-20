# Room Data

> **Status:** Stable
>
> **Last Updated:** 2026-07-19
>
> **Related:**
> - room-architecture.md
> - ../architecture/resources.md

---

# Purpose

RoomData stores all static configuration required to describe a room.

RoomData is independent from runtime gameplay state.

---

# Storage

RoomData is implemented as a Godot Resource.

Example:

```
RoomData.tres
```

---

# Responsibilities

RoomData contains:

- Room identifier
- Room size
- Biome
- Scene reference
- Tags
- Connection Points
- Generation metadata

---

# Runtime Data

RoomData never stores:

- player position
- enemy health
- opened chests
- destroyed objects

Runtime state belongs to gameplay systems.

---

# Conceptual Structure

```text
RoomData

├── id

├── biome

├── scene

├── tags

├── connection_points

├── generation_weight

└── metadata
```

---

# Design Rationale

Using Resource allows:

- editor-friendly workflow
- reusable assets
- balancing without code
- future procedural generation
