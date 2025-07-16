# QED Labyrinth

[![OCaml](https://img.shields.io/badge/OCaml-5.1-orange.svg)](https://ocaml.org)
[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![SolidJS](https://img.shields.io/badge/SolidJS-1.8-blue.svg)](https://www.solidjs.com/)

A living MUD system that creates intimate social spaces powered by autonomous agents. Built in OCaml, QED Labyrinth focuses on creating deeply simulated environments where agents develop relationships, share information, and generate emergent narratives through their interactions.

## Core Features

-   **Autonomous Agents**: Each agent has memories, needs, relationships, and goals.
-   **Living World**: Environments that persist and change based on agent actions.
-   **Emergent Stories**: Narratives arise naturally from agent interactions.
-   **Social Network**: Information spreads through agent interactions and relationships.
-   **Physical Simulation**: Spaces track physical and social state changes over time.

## Technical Architecture

QED Labyrinth is a distributed system composed of three primary services that communicate via HTTP and Redis.

```mermaid
graph TD
    subgraph Browser
        A[Game Client (SolidJS)]
    end

    subgraph Server
        B[API Server (Node.js/Fastify)]
        C[Chronos Engine (OCaml)]
        D[PostgreSQL Database]
        E[Redis Message Bus]
    end

    A -- HTTP/REST for Auth --> B
    A -- WebSocket for Game Commands --> B

    B -- Publishes Player Commands --> E
    B -- Reads/Writes --> D

    C -- Subscribes to Player Commands --> E
    C -- Publishes Game Events --> E
    C -- Reads/Writes --> D

    B -- Subscribes to Game Events --> E
    E -- Pushes Game Events --> B
    B -- Pushes Game Events via WebSocket --> A
```

-   **Chronos Engine (OCaml):** The heart of the simulation. It's a headless service that processes all game logic, manages the world state, and runs the agent simulation. It receives commands and publishes state changes via Redis.
-   **API Server (Node.js/Fastify):** The gateway to the system. It handles user authentication, manages persistent WebSocket connections, and translates client messages into formal protobuf commands for the engine.
-   **Game Client (SolidJS):** A reactive, terminal-themed web interface for players to interact with the world.

### Core Engine Principles

The OCaml engine is built on four foundational principles:

1.  **Observability:** Every system is automatically logged (structured JSON) and measured (metrics for duration, success, errors). End-to-end tracing via a `trace_id` allows for complete visibility into every player command's lifecycle.
2.  **Modularity:** The monolithic event handler is replaced by a registry of discrete, independent systems. Each system has a single responsibility and adheres to a strict `System.S` interface.
3.  **Flexibility:** The Scheduler can execute systems based on three different criteria:
    -   `OnEvent`: For player commands and their consequences.
    -   `OnTick`: For continuous processes like AP regeneration.
    -   `OnComponentChange`: For reactive logic like the knockout system.
4.  **Determinism:** The Scheduler supports ordering dependencies (`before`, `after`), using a topological sort to ensure a predictable and stable execution flow, with built-in cycle detection.

### Data Model: Relational + ECS

The engine uses a hybrid data model to leverage the strengths of both paradigms, as defined by a strict data synchronization doctrine:

-   **Relational Database (PostgreSQL - The "Blueprint"):** The system of record for templates and permanent, rarely-changing data (e.g., user accounts, character core stats, item definitions).
-   **Entity-Component-System (In-Memory, backed by DB/Redis - The "Live World"):** The system of record for unique instances and transient, high-volatility state (e.g., current HP, entity positions, inventories).

## Project Structure

```
.
├── api-server/        # Node.js/Fastify gateway for auth and WebSockets
├── bin/               # OCaml executables (the engine and world seeder)
├── game-client/       # SolidJS frontend application
├── lib/               # Core OCaml source code
│   ├── domain/        # Game logic, ECS, systems, models
│   └── infra/         # Database, Redis queue, monitoring tools
├── schemas/           # Protobuf definitions for inter-service communication
├── test/              # OCaml tests
├── world.json         # Data for seeding the game world
└── docker-compose.yml # Development environment setup
```

## Getting Started

### Prerequisites

-   **Docker** and **Docker Compose** (Recommended for easy setup)
-   **OCaml 5.1+**, **OPAM 2.1+**, and **Dune**
-   **Node.js 20+** and **npm**

### Running the Full Stack (Recommended)

The easiest way to run the entire project is with Docker Compose.

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd qed_labyrinth
    ```

2.  **Create an environment file:**
    Copy the environment variables needed by `docker-compose.yml`. You'll need to provide a `JWT_SECRET`.
    ```bash
    # Create a .env file in the root directory
    touch .env
    ```
    Add the following content to your `.env` file:
    ```env
    QED_DB_USER=postgres
    QED_DB_PASSWORD=mysecretpassword
    QED_DB_NAME=qed_labyrinth
    JWT_SECRET=a-very-strong-and-long-secret-key-for-jwt
    ```

3.  **Build and run the services:**
    This command will build the Docker images for the OCaml engine and API server, and start all services (Postgres, Redis, Engine, API Server).
    ```bash
    docker-compose build
    docker-compose up -d
    ```
    The game engine and API server will now be running.

4.  **Run the Game Client:**
    The client runs on your host machine and connects to the services in Docker.
    ```bash
    cd game-client
    npm install
    npm run dev
    ```
    The game client will be available at `http://localhost:3000`.

5.  **Seed the World:**
    With the services running, execute the `genesis` script inside the `chronos_engine` container to populate the database from `world.json`.
    ```bash
    docker-compose exec chronos_engine dune exec genesis
    ```
    You may also want to reset the database first if you are re-seeding:
    ```bash
    make reset-db
    ```

### Running Services Individually (for focused development)

If you prefer not to use Docker, you can run each service manually. You will need to have PostgreSQL and Redis instances running and accessible.

#### 1. OCaml Backend (`chronos_engine`)

```bash
# Install OCaml dependencies
opam install . --deps-only

# Build the project
dune build

# Run the world seeder
dune exec bin/genesis.ml

# Run the main engine
dune exec bin/chronos_engine.ml
```

#### 2. Node.js API Server (`api-server`)

```bash
cd api-server

# Install Node.js dependencies
npm install

# Run the server in development mode (with hot-reloading)
npm run dev
```

#### 3. SolidJS Game Client (`game-client`)

```bash
cd game-client

# Install Node.js dependencies
npm install

# Run the development server
npm run dev
```

## Development

### Schema Changes (Protobuf)

The `schemas/` directory defines the contract for messages between the `api-server` and `chronos_engine`. If you modify any `.proto` file, you must regenerate the corresponding code for both services.

-   **For the OCaml Engine:** The `dune build` command will automatically detect changes and regenerate the OCaml modules.
-   **For the API Server:** Run the generation script from the `api-server` directory.
    ```bash
    cd api-server
    npm run proto:gen
    ```

### Testing

To run the OCaml test suite:

```bash
dune runtest
```

## Contributing

1.  Fork the repository.
2.  Create a feature branch.
3.  Make your changes and add tests where applicable.
4.  Submit a pull request.
