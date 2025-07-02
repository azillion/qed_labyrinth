# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QED Labyrinth is a living MUD system that creates intimate social spaces powered by autonomous agents. The system consists of an OCaml backend with Entity-Component-System architecture and multiple frontend clients.

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

## Architecture Overview

### Core System Architecture
- **OCaml backend**: Entity-Component-System (ECS) with event-driven architecture
- **WebSocket communication**: Real-time client-server communication via Dream framework
- **Database**: SQLite with Caqti abstraction layer
- **Authentication**: JWT-based auth with user/character management

### Key Directories

#### Backend (`/lib`)
- `domain/`: Core game logic and types
  - `client.ml`: WebSocket client management
  - `state.ml`: Global application state
  - `types.ml`: Core type definitions and protocol types
  - `ecs.ml`: Entity-Component-System implementation
  - `loop.ml`: Main game loop and event processing
- `server/`: HTTP/WebSocket server implementation
- `infra/`: Infrastructure (database, config, LLM clients)
- `llm/`: Language model integration with multiple providers

#### Frontends
- `/app`: SolidJS-based game client with real-time features
- `/frontend`: Next.js marketing/landing page

### ECS Architecture
The system uses a custom ECS implementation with:
- **Entities**: UUID-based entity management with database persistence
- **Components**: Modular data storage (Character, Position, Area, Description, etc.)
- **Systems**: Game logic processors with priority-based execution
- **Event-driven**: Asynchronous event queue for game state changes

### Communication Protocol
- WebSocket-based real-time communication
- JSON message protocol defined in `Protocol` module
- Event-driven architecture with client message and event queues

### Database Schema
- Component-based storage with each component type in separate tables
- Entity lifecycle management with pending deletion system
- Automatic sync between in-memory ECS and database

## Key Components

### Character System
- Character creation, selection, and management
- Position tracking and area navigation
- User authentication and character association

### Area Management
- Dynamic area creation with environmental properties
- Exit system for area connections
- Coordinate-based world mapping

### Communication System
- Real-time messaging between clients
- Area-based chat functionality
- Administrative commands

### LLM Integration
- Multiple provider support (OpenAI, Anthropic, DeepSeek)
- Rate limiting and retry logic
- World generation capabilities

## Testing
- Run all tests: `dune runtest`
- Component tests use Alcotest framework
- Integration tests cover ECS and database operations

## Common Patterns

### Adding New Components
1. Define component type in `lib/domain/components.ml`
2. Create storage module using `MakeComponentStorage` functor
3. Add to ECS initialization in `ecs.ml`
4. Implement systems that operate on the component

### Adding New Events
1. Define event type in `lib/domain/event.ml`
2. Add handler in `lib/domain/loop.ml` event processing
3. Create corresponding systems for event processing

### Database Operations
- Use Caqti for all database interactions
- Components automatically sync via ECS
- Manual queries should go through `Database.Pool.use`