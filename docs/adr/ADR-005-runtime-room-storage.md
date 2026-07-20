# ADR-005: Runtime Rooms Should Be Prebuilt Assets

> **Status:** Accepted
>
> **Date:** 2026-07-19

---

# Context

Generating complete rooms during gameplay increases complexity and runtime cost.

---

# Decision

Rooms should be authored in advance and instantiated during gameplay.

The procedural generator assembles rooms instead of generating them from raw tiles.

---

# Consequences

Benefits:

- predictable performance
- easier optimization
- designer-friendly workflow

Trade-offs:

- requires management of room assets
