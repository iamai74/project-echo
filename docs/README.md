# Project Echo Documentation

Welcome to the technical documentation for **Project Echo**, a 2D Roguelite Metroidvania built with **Godot 4**.

This documentation serves as the single source of truth for the project's architecture, gameplay systems, technical decisions, and development process.

---

## Project Status

> **Status:** In Progress  
> **Engine:** Godot 4.x  
> **Language:** GDScript

The project is currently in the **early prototype** phase. Core gameplay systems are being implemented alongside the project's long-term architecture.

---

# Documentation Structure

```text
docs/
│
├── README.md
│
├── architecture/
│   ├── overview.md
│   ├── project-structure.md
│   ├── actor.md
│   ├── components.md
│   ├── resources.md
│   ├── state-machine.md
│   ├── events.md
│   └── coding-style.md
│
├── gameplay/
│
├── world/
│
├── roadmap/
│
└── adr/
```

Only the `architecture` section is currently under active development. Other sections will be introduced as the project evolves.

---

# Architecture

The architecture documentation describes how the project is structured and why specific technical decisions were made.

Current documents:

| Document | Description |
|----------|-------------|
| `overview.md` | High-level architecture overview |
| `project-structure.md` | Repository and Godot project organization |
| `actor.md` | Base gameplay entity |
| `components.md` | Component-based architecture |
| `resources.md` | Resource-driven configuration |
| `state-machine.md` | Universal state machine |
| `events.md` | Communication between systems |
| `coding-style.md` | Project coding conventions |

---

# Documentation Principles

Project Echo documentation follows several principles:

- Architecture before implementation
- One document, one responsibility
- Composition over inheritance
- Documentation describes concepts, not individual source files
- Decisions are documented, not experiments
- Documentation evolves together with the project

---

# Architecture Decision Records (ADR)

Significant architectural decisions are documented separately inside the `adr/` directory.

Each ADR explains:

- the problem
- the chosen solution
- alternatives that were considered
- rationale behind the decision

---

# Current Development Focus

Current milestone:

- World Authoring Architecture

Completed systems:

- Base Actor
- Universal State Machine
- Health Component
- Combat Prototype
- Hitbox / Hurtbox pipeline
- Weapon Component
- Enemy Prototype

---

# Contributing

When introducing a new gameplay system or changing an existing architecture:

1. Discuss the design.
2. Update the relevant documentation.
3. Implement the code.
4. Update the documentation if implementation differs from the original design.

Documentation should always reflect the current architecture of the project.

---

# License

Private project.
