# World Generation

> **Status:** Planned
>
> **Last Updated:** 2026-07-19
>
> **Related:**
> - overview.md
> - room-architecture.md

---

# Purpose

This document describes the future procedural world generation architecture.

---

# Generation Philosophy

Project Echo combines:

- handcrafted rooms
- procedural room selection
- data-driven generation

The generator creates world structure rather than room geometry.

---

# Planned Pipeline

```mermaid
graph TD

Biome

↓

Select Rooms

↓

Validate Connections

↓

Build World Graph

↓

Instantiate Rooms

↓

Gameplay
```

---

# Biomes

Each biome defines:

- available rooms
- enemy pool
- visual theme
- music
- difficulty
- generation rules

---

# Connection Validation

Connection rules are intentionally postponed.

They will be designed after biome generation requirements become clear.

---

# World Streaming

A future WorldStreamer system will be responsible for:

- loading nearby rooms
- unloading inactive rooms
- reducing memory usage

This system is outside the scope of the current milestone.
