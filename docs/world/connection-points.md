# Connection Points

> **Status:** Planned
>
> **Last Updated:** 2026-07-19
>
> **Related:**
> - room-architecture.md

---

# Purpose

Connection Points define where rooms may connect to other rooms.

---

# Design Principle

A Connection Point is an explicit design element.

It should not be automatically inferred from room geometry.

This allows level designers to control world generation directly.

---

# Responsibilities

Connection Points describe:

- position
- direction
- connection type
- optional metadata

---

# Future Usage

Connection Points will later be used for:

- room graph generation
- compatibility validation
- biome generation
- streaming
