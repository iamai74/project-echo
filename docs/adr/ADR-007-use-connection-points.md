# ADR-007 — Use Connection Points for Room Connectivity

> **Status:** Accepted
>
> **Date:** 2026-07-19
>
> **Related:**
> - architecture/world-architecture.md
> - architecture/room-authoring.md

---

# Context

Project Echo generates game worlds by connecting prebuilt rooms into a larger biome.

Each room must expose one or more connection locations that allow the world generator to determine how rooms can be assembled into a valid layout.

Initially, these locations could simply be represented as coordinates or markers embedded in the room scene.

However, as world generation grows more sophisticated, room connections will require additional metadata beyond their physical position.

---

# Problem

The world generation system needs a reliable and extensible way to describe where rooms may connect.

A simple position is insufficient because future generation rules may depend on additional information such as:

- connection direction;
- doorway width;
- elevation;
- connection type;
- biome restrictions;
- gameplay requirements.

The project needed a representation that could evolve without redesigning the room format.

---

# Decision

Project Echo introduces **ConnectionPoint** as a dedicated architectural concept.

A ConnectionPoint represents a location where a room may connect to another room during world generation.

It is treated as an explicit object rather than an implicit coordinate.

Each room owns zero or more ConnectionPoints.

---

# Responsibilities

A ConnectionPoint is responsible for describing a possible room connection.

Typical information includes:

- local position;
- facing direction;
- connection identifier;
- optional metadata used by generation rules.

A ConnectionPoint is **not** responsible for:

- spawning rooms;
- validating world layouts;
- performing procedural generation;
- modifying room contents.

Its purpose is purely descriptive.

---

# Rationale

## Explicit Representation

Representing room exits as dedicated objects makes the architecture easier to understand.

Instead of searching for arbitrary markers inside a room, the generation system works with a well-defined collection of ConnectionPoints.

---

## Extensibility

Future gameplay may require richer connection data.

Examples include:

- locked doors;
- one-way passages;
- elevators;
- biome-specific entrances;
- boss gates;
- secret passages.

Adding new metadata to ConnectionPoint is straightforward and does not require redesigning existing rooms.

---

## Separation of Responsibilities

The room describes **where** connections exist.

The world generator decides **how** to use them.

This keeps room authoring independent from generation algorithms.

---

## Tooling Support

Treating ConnectionPoint as an explicit concept simplifies future editor tools.

Examples include:

- visual connection previews;
- validation tools;
- automatic doorway placement;
- generation debugging.

---

# Alternatives Considered

## Raw Coordinates

Each room exposes a list of positions.

Advantages:

- Very simple.
- Minimal implementation effort.

Disadvantages:

- Difficult to extend.
- Poor readability.
- No place for future metadata.
- Encourages generation logic to infer missing information.

Rejected.

---

## Tile-Based Detection

Generation automatically detects openings in room geometry.

Advantages:

- No additional authoring objects.

Disadvantages:

- Fragile.
- Difficult to debug.
- Couples procedural generation to tile layout.
- Limits future flexibility.

Rejected.

---

# Consequences

## Positive

- Clear room interface.
- Better separation between room design and world generation.
- Easier editor tooling.
- Future-proof architecture.
- Rich metadata support.

---

## Trade-offs

Room authors must explicitly define ConnectionPoints.

This introduces a small amount of additional work during room creation, but greatly improves clarity and maintainability.

---

# Future Considerations

ConnectionPoint may later be expanded with additional metadata, such as:

- connection category;
- required progression state;
- traversal type;
- traversal cost;
- biome compatibility;
- scripted events.

These additions should extend the existing concept rather than replace it.

---

# Decision Summary

Project Echo models room connections using explicit ConnectionPoint objects.

Rooms describe available connections.

The world generation system determines how those connections are used.

This separation keeps room authoring simple while allowing procedural generation to evolve independently.

---

# Decision Snapshot

**Chosen**

Represent room exits using dedicated ConnectionPoint objects.

**Reason**

Provide an extensible and explicit interface between room authoring and world generation.

**Benefits**

- Future-proof design.
- Rich metadata support.
- Better editor tooling.
- Cleaner generation architecture.

**Revisit When**

Only if the room generation architecture fundamentally changes.

---

# Related Documents

- World Architecture
- Room Authoring
- ADR-004 — Store RoomData as a Godot Resource
- ADR-005 — Runtime Rooms Should Be Prebuilt Assets
- ADR-006 — Introduce a Semantic Tile Layer
