# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QED Labyrinth is a living MUD system that creates intimate social spaces powered by autonomous agents. The system consists of an OCaml backend with a hybrid data model (Relational DB + ECS) and multiple frontend clients.

## Development Commands

### OCaml Backend
- **Build**: `dune build`
- **Run server**: `dune exec qed_labyrinth`
- **Run tests**: `dune runtest`
- **Install dependencies**: `opam install . --deps-only`

### Frontend - SolidJS App (/app)
- **Development server**: `cd app && npm run dev` (or `bun run dev`)
- **Build**: `cd app && npm run build`
- **Preview build**: `cd app && npm run serve`

### Frontend - Next.js App (/frontend)
- **Development server**: `cd frontend && npm run dev` (runs on port 3001)
- **Build**: `cd frontend && npm run build`
- **Production server**: `cd frontend && npm start`
- **Lint**: `cd frontend && npm run lint`

## Core Architecture Tenets

Our backend uses a hybrid data model. Understanding the distinction between the Relational Database and the Entity-Component-System (ECS) is critical for all development.

### Data Architecture: Relational vs. ECS

This defines the rules for where different types of data should live.

#### **1. Relational Database (The "Blueprint Library")**
The relational DB is the **System of Record for Templates and Permanent Identity**.

**Use a Relational Table When:**
*   **It's a Template or Blueprint:** The data defines a *type* of thing, not a specific, unique instance (e.g., the definition of an "Iron Sword").
*   **It's Permanent, Rarely-Changing Character Data:** Data that defines who a character *is* (e.g., their allocated core stats, their known languages, their reputation).
*   **We Need to Run Global Queries:** The data needs to be searched or aggregated across all characters, even those offline (e.g., "find all members of a guild").

#### **2. Entity-Component-System (The "Live World Simulation")**
The ECS is the **System of Record for Instances and Transient State**.

**Use an ECS Component When:**
*   **It's a Unique Instance:** The data represents a *specific thing* existing in the world right now (e.g., a specific Iron Sword, entity ID `1234-abcd`, lying on the ground).
*   **It's Transient, High-Volatility Data:** The data changes frequently during the game loop (e.g., current HP, position, active spell effects).
*   **We Need to Query it Locally:** The data is for interactions within a single area (e.g., "find all entities with health within 10 meters").

### Data Synchronization Doctrine

This defines the rules for how data moves between the Relational DB and the ECS to prevent desynchronization. **This is a strict doctrine.**

**1. Unidirectional Data Flow for Core/Permanent Data:**
*   **Rule:** Permanent data (Core Stats, Knowledge) flows in **one direction only**: from the **Relational DB -> Live ECS**.
*   **Mechanism:** This data transfer happens *only* when a character is loaded into the world.
*   **Prohibition:** No system should ever write changes to a live ECS component that mirrors permanent data (e.g., `CoreStatsComponent`). These components are **read-only** during a game session.

**2. The Transactional Pattern for Permanent Changes:**
*   **Rule:** When a player makes a permanent change (e.g., allocating a stat point on level up), the change must be written to the **Relational DB first**.
*   **Mechanism:** An event is fired, and a system calls a Model function to `UPDATE` the relational table. **Only on success** does that system then update the live, read-only component in the ECS to reflect the change for the current session.

**3. Reconciliation on Load:**
*   **Rule:** The `CharacterLoadingSystem` is the **sole arbiter of truth** for assembling a live character.
*   **Mechanism:** On login, the system always rebuilds a character's state from scratch:
    1.  It loads permanent data from the **Relational DB** into read-only ECS components.
    2.  It loads transient state (current HP, inventory) from the **persisted ECS component tables**.
    3.  It runs calculation systems (like the stat calculator) to generate derived data.
*   **Benefit:** This guarantees every session starts from a consistent state, automatically correcting any potential drift.

## Common Patterns

### Adding a New Relational Model
1.  Define the model in `lib/domain/models/`.
2.  Include `t` type, Caqti `Q` module, and data access functions.
3.  Add the `CREATE TABLE` statement to `lib/infra/database.ml`.
4.  Integrate with systems via events and model function calls.

### Adding a New ECS Component
1.  Define component type and `table_name` in `lib/domain/components.ml`.
2.  Add a call to `create_component_table` in `lib/infra/database.ml`.
3.  Add the `MakeComponentStorage` module in `lib/domain/ecs.ml`.
4.  Wire the storage module into `World.init` and `World.sync_to_db` in `lib/domain/ecs.ml`.
5.  Implement systems that operate on the component.

### Adding New Events
1.  Define event type in `lib/domain/event.ml`.
2.  Add a handler case in `lib/domain/loop.ml`'s `process_event` function.
3.  Create or modify systems to handle and queue the event.