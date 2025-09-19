# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QED Labyrinth is a living MUD system that creates intimate social spaces powered by autonomous agents. The system consists of an OCaml backend with a hybrid data model (Relational DB + ECS) and multiple frontend clients. The OCaml core engine now operates as a headless service, receiving commands and publishing state changes via Redis.

## Core Architecture Tenets

Our backend uses a hybrid data model (Relational + ECS) and an observable, functor-based system architecture for event processing.

### Data Architecture: Relational vs. ECS

This defines where different types of data should live.

*   **Relational Database (The "Blueprint Library"):** The system of record for templates and permanent, rarely-changing data (e.g., character core stats, item definitions).
*   **Entity-Component-System (The "Live World Cache"):** The system of record for unique instances and transient, high-volatility state, backed by Redis for resilience (e.g., current HP, position).

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

### Event-Driven Systems Architecture

The engine is event-driven and architected around a Dispatcher and modular Systems. This provides "observability by construction."

*   **System:** A self-contained OCaml module that handles one specific type of event (e.g., `TakeItem`). Each system implements a strict interface (`System.S`).
*   **Observability Functor (`System.Make`):** A functor that wraps a logic-containing system. This wrapper automatically provides structured JSON logging, metrics (success/error counts), and timing for every execution, eliminating boilerplate and ensuring consistency.
*   **Dispatcher:** A central module that holds a registry of all observable systems. The main game loop no longer contains business logic; it simply pops an event from the queue and passes it to the `Dispatcher`, which routes it to the correct, wrapped system handler.
*   **Distributed Tracing:** Every command entering the `api-server` is assigned a unique `trace_id`. This ID is propagated through Redis, the OCaml engine's event queue, the dispatcher, and back out through Redis to the `api-server`, allowing for complete end-to-end tracing of any action.

### The Domain Facade (Action-Oriented API)

To keep game logic clean and separate from data implementation details, we use a "Domain Facade" located in `lib/domain/actions/`. This layer provides a high-level, action-oriented API for interacting with game concepts like Characters, Items, and Areas.

-   **Systems should ALWAYS use the facade.** Systems should never call `Ecs.*Storage` modules or database `Models` directly.
-   **Facade functions are verbs:** `Character_actions.move`, `Item_actions.use`, etc.
-   **Facade handles complexity:** A single call like `Character_actions.take` orchestrates multiple state changes (removing from area, adding to inventory), hides the underlying data structures, and provides clear, user-facing error messages.

### Adding a New Game Action (Event)

1.  **Define the Command:** If the action originates from the client, add the command to `schemas/input.proto` and update the `api-server`'s `commandService.ts`.
2.  **Define the Internal Event:** Add a new variant to `lib/domain/event.ml` and map it in `lib/domain/loop.ml`.
3.  **Implement the Core Logic (in the Facade):** Add a new function to the appropriate module in `lib/domain/actions/` (e.g., a new character ability would go in `character_actions.ml`). This function contains the detailed implementation and is the "source of truth" for the action.
4.  **Create the System:** Create a new, simple system in the `systems/` directory. Its `execute` function should do three things only:
    a. Find the relevant domain objects using the facade (e.g., `Character_actions.find_active`).
    b. Call the new facade action function.
    c. Handle the `Ok`/`Error` result, usually by sending a message back to the player.
5.  **Register the System:** Add the new system to the scheduler in `bin/chronos_engine.ml`.

## Shared Schemas (The Contract)

The `schemas/` directory contains Protocol Buffer definitions that serve as the data contract between services. The `input.proto` file defines the structure for player commands sent from the API server to the Chronos Engine, ensuring consistent message format across the distributed system.

### Code Generation

The build system automatically generates OCaml modules from Protocol Buffer schemas using `ocaml-protoc` and the `pbrt` runtime library. The `schemas/dune` file contains rules that invoke `ocaml-protoc` to generate `.ml` and `.mli` files into `lib/schemas_generated/`. The generated code is exposed as the `qed_labyrinth.schemas_generated` library, making schema types directly available to the main engine code.

To use generated types in your code:
```ocaml
open Schemas_generated.Input
let event = { user_id = \"user123\"; trace_id = \"trace456\"; payload = Some (Move { direction = North }) }
```

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

## Deployment

The project is deployed via a GitHub Actions workflow that automatically builds and pushes Docker images to GitHub Container Registry (ghcr.io). Upon successful image builds, the workflow connects to the production server via SSH and uses `docker-compose` to pull and deploy the latest container versions. This ensures zero-downtime deployments with atomic service updates.

## Development Commands

### OCaml Backend
- **Build**: `dune build`
- **Run engine**: `dune exec chronos_engine`
- **Run tests**: `dune runtest`
- **Install dependencies**: `opam install . --deps-only`

### Frontend - SolidJS App (/game-client)
- **Development server**: `cd game-client && npm run dev` (or `bun run dev`)
- **Build**: `cd game-client && npm run build`
- **Preview build**: `cd game-client && npm run serve`

### Frontend - Next.js App (/frontend)
- **Development server**: `cd frontend && npm run dev` (runs on port 3000)
- **Build**: `cd frontend && npm run build`
- **Production server**: `cd frontend && npm start`
- **Lint**: `cd frontend && npm run lint`

### API Server (Fastify) (/api-server)
- **Development server**: `cd api-server && npm run dev` (runs on port 3001)
- **Build**: `cd api-server && npm run build`
- **Production server**: `cd api-server && npm run start`
- **Generate Protobuf schemas**: `cd api-server && sh ./generate-schemas.sh` (must be run whenever .proto files are changed)