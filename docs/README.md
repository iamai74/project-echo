# Project Echo Documentation

Welcome to the technical documentation for **Project Echo**, a 2D roguelite/metroidvania built with **Godot 4** and **GDScript**.

This documentation is the project's reference for architecture, gameplay systems, world authoring, technical decisions and development conventions.

---

## Project Status

> **Status:** Early prototype
> **Engine:** Godot 4.x
> **Language:** GDScript

Core gameplay and world-authoring systems are being implemented alongside the project's long-term architecture. Documentation describes both the implemented architecture and the parts that are explicitly planned.

When documentation and implementation disagree, the discrepancy should be resolved rather than preserved as a third interpretation.

---

## Documentation Structure

```text
docs/
│
├── README.md
├── CHANGELOG.md
│
├── architecture/
│   ├── overview.md
│   ├── project-structure.md
│   ├── actor.md
│   ├── components.md
│   ├── state-machine.md
│   ├── combat-architecture.md
│   ├── ai-architecture.md
│   ├── resources.md
│   ├── resources-catalog.md
│   └── glossary.md
│
├── world/
│   ├── overview.md
│   ├── room-architecture.md
│   ├── room-data.md
│   ├── semantic-tiles.md
│   ├── world-authoring.md
│   ├── bake-pipeline.md
│   ├── themes.md
│   ├── connection-points.md
│   └── world-generation.md
│
└── adr/
    ├── ADR-001 — Layer-Based Project Structure.md
    ├── ADR-002 — Composition over Inheritance.md
    ├── ADR-003 — Actor as the Base Gameplay Entity.md
    ├── ADR-004-room-data-as-resource.md
    ├── ADR-005-runtime-room-storage.md
    ├── ADR-006-semantic-tile-layer.md
    └── ADR-007-use-connection-points.md
```

---

## Architecture Documents

| Document | Description |
|----------|-------------|
| [`overview.md`](architecture/overview.md) | High-level architecture and system boundaries |
| [`project-structure.md`](architecture/project-structure.md) | Repository layout and directory responsibilities |
| [`actor.md`](architecture/actor.md) | Base gameplay entity and actor-level coordination |
| [`components.md`](architecture/components.md) | Reusable gameplay components |
| [`state-machine.md`](architecture/state-machine.md) | Actor state machine and state lifecycle |
| [`combat-architecture.md`](architecture/combat-architecture.md) | Attack, hitbox, hurtbox and health flow |
| [`ai-architecture.md`](architecture/ai-architecture.md) | Enemy AI states and current prototype limitations |
| [`resources.md`](architecture/resources.md) | Resource-driven configuration and baked data |
| [`resources-catalog.md`](architecture/resources-catalog.md) | Catalog of implemented and planned data types |
| [`glossary.md`](architecture/glossary.md) | Shared terminology |

---

## World Documents

| Document | Description |
|----------|-------------|
| [`overview.md`](world/overview.md) | World-system goals and current scope |
| [`room-architecture.md`](world/room-architecture.md) | Authored rooms, baked rooms and runtime rooms |
| [`room-data.md`](world/room-data.md) | The `RoomData` runtime resource |
| [`semantic-tiles.md`](world/semantic-tiles.md) | Semantic layers, cells, topology and brushes |
| [`world-authoring.md`](world/world-authoring.md) | Brush-based room authoring workflow |
| [`bake-pipeline.md`](world/bake-pipeline.md) | Room bake steps, processors and validators |
| [`themes.md`](world/themes.md) | Theme building and theme application |
| [`connection-points.md`](world/connection-points.md) | Room connection data and planned usage |
| [`world-generation.md`](world/world-generation.md) | Planned procedural world assembly |

---

## Documentation Principles

Project Echo documentation follows these principles:

- architecture before implementation;
- one document, one responsibility;
- composition over inheritance;
- describe concepts and responsibilities, not individual source files;
- document decisions, not experiments;
- keep documentation synchronized with the actual architecture.

---

## Architecture Decision Records

Significant architectural decisions are documented in [`adr/`](adr/). Each ADR records the problem, the chosen solution, alternatives and consequences.

ADRs are historical records. When later implementation changes an accepted decision, the ADR should be superseded by a new decision rather than silently rewritten.

---

## Current Development Focus

Current milestone: **world authoring, baking and theming**.

Implemented systems:

- base `Actor` with data-driven movement and health;
- universal state machine with player and enemy states;
- health, hitbox, hurtbox and weapon components;
- player input command buffer;
- enemy prototype (`Walker`, `Runner`, `Heavy`);
- semantic brush authoring;
- semantic layers, cells and topology;
- room bake pipeline with validation;
- baked `RoomData` and runtime room scenes;
- theme build and application pipeline;
- GdUnit4 unit and integration test suites.

In progress or partially implemented:

- marker and volume authoring/baking;
- enemy detection-to-behaviour wiring for the base `Enemy`;
- player dash and jump-attack states;
- room database and world generation.

Planned:

- procedural world assembly;
- biomes and room selection;
- world streaming;
- room connection authoring and validation.

---

## Contributing

When introducing a new gameplay system or changing an existing architecture:

1. Inspect the relevant architecture and world documentation.
2. Update the design documentation.
3. Implement the change.
4. Run the relevant tests and validators.
5. Update documentation if implementation differs from the design.

Documentation should always reflect the current architecture of the project.

---

## License

Private project.
