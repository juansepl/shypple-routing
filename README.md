# Technical Challenge

Ruby CLI to find the cheapest or fastest shipping route and save searches that
can be fulfilled when new sailings arrive.

**Implemented:** Docker, SQLite setup, Minitest/SimpleCov and direct/indirect cheapest routing.
Fastest selection and saved searches are the next tickets.

## 1. Tech Stack

- Ruby 4.0.9 and Bundler 4.0.20.
- SQLite (`sqlite3` 2.10.1) in a Docker volume.
- Docker / optional Docker Compose.
- Minitest 6.0.6 and SimpleCov 1.3.2.

## 2. Getting Started

Requires Docker. From the project root, with Docker Compose:

```bash
docker volume create shypple-routing-data
docker compose build
printf 'CNSHA\nNLRTM\ncheapest-direct\n' | docker compose run --rm -T app
```

Or with Docker only:

```bash
docker build -t shypple-routing:dev .
printf 'CNSHA\nNLRTM\ncheapest-direct\n' | docker run --rm -i -v shypple-routing-data:/app/data shypple-routing:dev
```

Search reads origin, destination and criterion from stdin and prints JSON only to
stdout. With the sample catalog, `cheapest-direct` returns `ABCD`. Errors go to
stderr with exit code 1. SQLite is reserved for the saved-search ticket; no
migration step is required. Building downloads dependencies.

See the [challenge](docs/CHALLENGE.md) and [sample catalog](fixtures/response.json).

## 3. Running Tests

After building:

```bash
docker compose run --rm -v ./coverage:/app/coverage app bundle exec ruby bin/test
```

Without Compose:

```bash
docker run --rm -v "$PWD/coverage:/app/coverage" shypple-routing:dev bundle exec ruby bin/test
```

Acceptance specs in `test/acceptance/` run the real CLI for each ticket, including
valid routes, input errors and feed validation; unit specs in `test/unit/` cover
detailed rules. SimpleCov aggregates subprocess coverage and generates
`coverage/index.html`, including untested application files. Each new ticket adds
its own cases; current execution evidence is in plan.md.

## 4. Technical Decisions

- Plain Ruby CLI for the required stdin/stdout interface.
- SQLite in a persistent volume, without a database server.
- Pinned image and locked dependencies for reproducibility.
- Single-purpose objects: feed parsers, criterion strategies, forms, services and a
  CLI application that wires them (ADR-007).

See [Architecture Decisions](docs/ARCHITECTURE-DECISIONS.md).

## 5. AI-Assisted Development

AI assisted with requirement analysis, design and project setup. Build, startup,
SQLite persistence and coverage generation were checked in Docker.

Workflow: acceptance criteria → tests and implementation → review → validation → commit.
Each ticket includes its code, tests and relevant documentation.

See [AGENTS.md](AGENTS.md) for orchestration and role instructions,
[the specification](docs/spec.md) for acceptance criteria and test scenarios, and
[the implementation plan](plan.md) for phase status and verification evidence.

## 6. Limitations

- `cheapest-direct` and `cheapest` are implemented; fastest routing and pending
  searches are the next tickets.
- Checks ran on ARM64; AMD64 execution is unverified.
- Background notifications, catalog versioning and a web interface are out of scope.
- Optional `--explain` output is deferred until the required tickets are complete.
