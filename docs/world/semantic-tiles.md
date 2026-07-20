# Semantic Tiles

> **Status:** In Progress
>
> **Last Updated:** 2026-07-19
>
> **Related:**
> - room-architecture.md

---

# Purpose

Semantic Tiles separate gameplay meaning from visual representation.

---

# Motivation

A visual tile does not always describe gameplay behavior.

For example, identical tiles may represent:

- normal floor
- destructible floor
- hidden passage
- scripted event trigger

Visual appearance should not determine gameplay logic.

---

# Architecture

```text
Visual Tile

↓

Semantic Tile

↓

Gameplay Logic
```

---

# Possible Semantic Types

- Floor
- Wall
- Platform
- Hazard
- Decoration
- Spawn Area
- Connection
- Secret

---

# Current Scope

Semantic Tiles currently define gameplay meaning only.

The implementation will evolve alongside the world generation system.
