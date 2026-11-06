# World Generation

> **Status:** Planned
>
> **Last Updated:** 2026-11-06
>
> **Related:**
> - [overview.md](overview.md)
> - [room-architecture.md](room-architecture.md)
> - [room-data.md](room-data.md)
> - [connection-points.md](connection-points.md)
> - [themes.md](themes.md)

---

# Purpose

This document describes the planned procedural world generation architecture.

World generation is not implemented yet. The current implementation produces individual baked rooms, their runtime scenes and their themes. Assembling those rooms into a world is the next architectural layer.

---

# Generation Philosophy

Project Echo combines:

- handcrafted rooms;
- procedural room selection;
- data-driven generation.

The generator creates world structure rather than room geometry. Rooms are authored and baked in advance; the generator decides which rooms are used, where they are placed and how they connect.

---

# Planned Pipeline

```mermaid
graph TD

Biome

→ Select Rooms

→ Validate Connections

→ Build World Graph

→ Instantiate Rooms

→ Apply Themes

→ Gameplay
```

Each stage has a separate responsibility:

| Stage | Responsibility |
|-------|----------------|
| Biome | Select compatible rooms and constraints |
| Select Rooms | Choose candidate rooms for the biome |
| Validate Connections | Check that adjacent rooms can connect |
| Build World Graph | Decide room layout and adjacency |
| Instantiate Rooms | Load baked runtime room scenes |
| Apply Themes | Assign visual themes for the biome |
| Gameplay | Hand control to runtime systems |

---

# Inputs

World generation is expected to consume:

- baked `RoomData` resources;
- generated runtime room scenes;
- room connection data (`ConnectionData`);
- biome definitions;
- built theme resources (`ThemeInfo`).

None of the biome, room database or generation-rule types exist yet.

---

# Biomes

A biome is planned to define:

- available rooms;
- enemy pool;
- visual theme;
- music;
- difficulty;
- generation rules.

Biome selection must not change room topology. A theme is visual configuration applied to already-baked room data.

See [themes.md](themes.md).

---

# Connection Validation

Connection rules are intentionally postponed.

The data model already reserves `RoomData.connections`, but no authoring or validation pipeline exists. Connection rules will be designed once biome generation requirements are clear.

See [connection-points.md](connection-points.md).

---

# Room Database

A room database is planned to index available baked rooms and their metadata.

It does not exist yet. Until it is implemented, rooms must be located by asset path.

---

# World Streaming

A future `WorldStreamer` system will be responsible for:

- loading nearby rooms;
- unloading inactive rooms;
- reducing memory usage.

This system is outside the scope of the current milestone.

---

# Current Status

Not implemented:

- room database;
- biome resources;
- room selection;
- connection validation;
- world graph generation;
- runtime room instantiation and streaming;
- biome-driven theme selection.

Implemented foundation:

- baked `RoomData`;
- baked runtime room scenes;
- `ConnectionData` data type;
- built theme resources and runtime theme application.

---

# Related Documents

- [World Overview](overview.md)
- [Room Architecture](room-architecture.md)
- [Room Data](room-data.md)
- [Connection Points](connection-points.md)
- [Themes](themes.md)
