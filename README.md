# QED Labyrinth

A Living MUD system that creates intimate social spaces powered by autonomous agents. Built in OCaml, QED Labyrinth focuses on creating deeply simulated environments where agents develop relationships, share information, and generate emergent narratives through their interactions.

## Core Features

- **Autonomous Agents**: Each agent has memories, needs, relationships, and goals
- **Living World**: Environments that persist and change based on agent actions
- **Emergent Stories**: Narratives arise naturally from agent interactions
- **Social Network**: Information spreads through agent interactions and relationships
- **Physical Simulation**: Spaces track physical and social state changes over time

## Technical Architecture

### Core Engine (OCaml)

```ocaml
World State
├─ Agents
│  ├─ Properties (needs, status)
│  ├─ Relationships
│  └─ Memory
│
├─ Spaces
│  ├─ Physical State
│  ├─ Social State
│  └─ History
│
└─ Events
   ├─ Actions
   ├─ Changes
   └─ Information
```

### Getting Started

1. **Prerequisites**

   - OCaml
   - Dune build system
   - PostgreSQL
   - Redis
   - Language model API access

1. **Installation**

   ```bash
   git clone <repository-url>
   cd qed_labyrinth
   opam install . --deps-only
   ```

1. **Building**

   ```bash
   dune build
   ```

1. **Running**

   ```bash
   dune exec qed_labyrinth
   ```

## Development Guide

### Project Structure

```
qed_labyrinth/
├─ src/
│  ├─ agent/        # Agent implementation
│  ├─ world/        # World state management
│  ├─ memory/       # Memory systems
│  ├─ planning/     # Planning modules
│  └─ interface/    # User interface
├─ test/            # Test suite
└─ examples/        # Example scenarios
```

### Key Components

1. **Agent System**

   - State representation
   - Decision making
   - Need simulation
   - Relationship tracking

1. **Memory System**

   - Event recording
   - Memory retrieval
   - Information decay
   - Reflection generation

1. **Planning System**

   - Goal planning
   - Action selection
   - Plan revision
   - Reactive behavior

1. **Space System**

   - Physical state tracking
   - Social state management
   - Event history
   - State transitions

## Contributing

1. Fork repository
1. Create feature branch
1. Make changes with tests
1. Submit pull request

## Testing

```bash
dune runtest
```

## Future Development

1. Enhanced Intelligence

   - Better decision making
   - Improved social strategies
   - More sophisticated planning

1. Performance

   - Parallel processing
   - Memory optimization
   - State update efficiency

## License

MIT License

## Acknowledgments

Built on research in:

- Generative agents
- Social simulation
- Artificial intelligence
- Multi-agent systems
