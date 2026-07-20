# ADR-004: Store RoomData as a Godot Resource

> **Status:** Accepted
>
> **Date:** 2026-07-19

---

# Context

Room configuration must be editable without modifying gameplay code.

---

# Decision

RoomData is stored as a Godot Resource.

---

# Consequences

Benefits:

- editor integration
- reusable assets
- easy balancing
- data-driven workflow

Trade-offs:

- runtime state must remain separate
